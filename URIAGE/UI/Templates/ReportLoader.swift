//
//  ReportLoader.swift
//  URIAGE
//
//  レポートの集計をバックグラウンドで行い、終わったら描画するコンテナ。
//
//  - 集計済み（キャッシュあり）ならその場で描画する。スケルトンは出さない
//

import SwiftUI

/// どの期間のレポートか
nonisolated enum ReportKey: Hashable, Sendable {
    case month(Date)
    case year(Date)
    case allTime
}

/// 集計結果のキャッシュ。入力（販売記録・資材）が変わったら全部捨てる。
/// ReportView が 1 つ持ち、各ページで共有する。
@MainActor
final class ReportCache {
    private var input: ReportInput?
    private var storage: [ReportKey: any Sendable] = [:]

    func report<Report: Sendable>(for key: ReportKey, input: ReportInput) -> Report? {
        guard input == self.input else { return nil }
        return storage[key] as? Report
    }

    func store<Report: Sendable>(_ report: Report, for key: ReportKey, input: ReportInput) {
        if input != self.input {
            self.input = input
            storage = [:]
        }
        storage[key] = report
    }

    /// 隣のページなど、まだ表示していない期間を先に集計しておく
    func prefetch<Report: Sendable>(
        _ key: ReportKey,
        input: ReportInput,
        compute: @escaping @Sendable (ReportInput) -> Report
    ) async {
        guard (report(for: key, input: input) as Report?) == nil else { return }
        let report = await Task.detached(priority: .utility) { compute(input) }.value
        store(report, for: key, input: input)
    }
}

struct ReportLoader<Report: Sendable, Content: View, Placeholder: View>: View {
    let key: ReportKey
    let input: ReportInput
    let cache: ReportCache
    let compute: @Sendable (ReportInput) -> Report
    /// これより早く集計が終わればスケルトンは出さない
    var skeletonDelay: Duration = .milliseconds(150)
    @ViewBuilder var content: (Report) -> Content
    @ViewBuilder var placeholder: () -> Placeholder

    @State private var loaded: Report?
    @State private var isShowingPlaceholder = false

    private nonisolated struct LoadID: Equatable {
        let key: ReportKey
        let input: ReportInput
    }

    var body: some View {
        // 最新のキャッシュ → その場で集計（軽い場合）→ 前回の結果（再集計中）→ なし の順で使う
        let report: Report? = cache.report(for: key, input: input)
            ?? computeInlineIfCheap()
            ?? loaded

        ZStack(alignment: .top) {
            if let report {
                content(report)
            } else if isShowingPlaceholder {
                placeholder()
                    .transition(.opacity)
            } else {
                // 一瞬で終わる集計のために、何も描かずに待つ
                Color.clear
            }
        }
        .task(id: LoadID(key: key, input: input)) {
            await load()
        }
    }

    private func computeInlineIfCheap() -> Report? {
        guard input.isCheapToAggregate else { return nil }
        let report = compute(input)
        cache.store(report, for: key, input: input)
        return report
    }

    private func load() async {
        let key = key
        let input = input

        if let cached: Report = cache.report(for: key, input: input) {
            loaded = cached
            return
        }

        // 一定時間を過ぎても終わらない場合だけスケルトンを出す
        let skeletonTimer = Task { @MainActor in
            try? await Task.sleep(for: skeletonDelay)
            guard Task.isCancelled == false, loaded == nil else { return }
            withAnimation(.easeOut(duration: 0.15)) {
                isShowingPlaceholder = true
            }
        }

        let compute = compute
        let report = await Task.detached(priority: .userInitiated) { compute(input) }.value
        skeletonTimer.cancel()

        cache.store(report, for: key, input: input)
        guard Task.isCancelled == false else { return }

        withAnimation(isShowingPlaceholder ? .easeOut(duration: 0.2) : nil) {
            loaded = report
            isShowingPlaceholder = false
        }
    }
}

// MARK: - 各レポートの集計方法

nonisolated enum ReportComputation {
    static func monthly(_ month: Date) -> @Sendable (ReportInput) -> MonthlyReport {
        { MonthlyReport(month: month, input: $0) }
    }

    static func yearly(_ year: Date) -> @Sendable (ReportInput) -> YearlyReport {
        { YearlyReport(year: year, input: $0) }
    }

    static let allTime: @Sendable (ReportInput) -> AllTimeReport = {
        AllTimeReport(input: $0)
    }
}
