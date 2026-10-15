//
//  ReportView.swift
//  URIAGE
//
//  レポートタブ：月次 / 年次 を切り替えるコンテナ
//

import SwiftUI
import SwiftData

enum ReportPeriodMode: String, CaseIterable, Identifiable {
    case monthly
    case yearly
    case all

    var id: Self { self }

    var title: String {
        switch self {
        case .monthly: "月"
        case .yearly: "年"
        case .all: "すべて"
        }
    }
}

struct ReportView: View {
    @Query(sort: \SoldItem.soldAt, order: .reverse) private var items: [SoldItem]
    @Query(sort: \SupplyItem.purchaseDate, order: .reverse) private var supplies: [SupplyItem]
    @AppStorage(AppSettingsKey.currencyCode) private var currencyCode = AppDefaults.currencyCode

    @State private var mode: ReportPeriodMode = .monthly
    // 0 は今月 / 今年、負の値は過去
    @State private var monthOffset: Int = 0
    @State private var yearOffset: Int = 0
    /// 集計結果のキャッシュ（月・年をまたいで共有。販売記録が変わると自動で捨てる）
    @State private var cache = ReportCache()
    /// 上部（大きいタイトル・期間ヘッダー）の縮み具合。0 = 通常、1 = 最小（販売記録の大きいタイトルと同じ動き）
    @State private var collapseProgress: CGFloat = 0
    /// 大きいタイトルの本来の高さ（文字サイズの設定で変わるので実測する）
    @State private var largeTitleHeight: CGFloat = 52

    /// レポートタブが選択中か。タブを離れたら今月・今年に戻すために使う
    private let isTabActive: Bool

    private let calendar = Calendar.current
    private let initialMonth: Date
    private let initialYear: Date

    /// 過去 10 年分までさかのぼれる
    private static let monthRange = -120...0
    private static let yearRange = -10...0

    /// 期間ヘッダーが縮む量（上下の余白とボタンの高さ）
    private static let periodHeaderCollapse: CGFloat = 24

    init(isTabActive: Bool = true) {
        self.isTabActive = isTabActive
        let now = Date()
        let calendar = Calendar.current
        self.initialMonth = calendar.dateInterval(of: .month, for: now)?.start ?? now
        self.initialYear = calendar.dateInterval(of: .year, for: now)?.start ?? now
    }

    private func month(at offset: Int) -> Date {
        calendar.date(byAdding: .month, value: offset, to: initialMonth) ?? initialMonth
    }

    private func year(at offset: Int) -> Date {
        calendar.date(byAdding: .year, value: offset, to: initialYear) ?? initialYear
    }

    private var currentOffset: Int {
        switch mode {
        case .monthly: monthOffset
        case .yearly: yearOffset
        case .all: 0
        }
    }

    private var periodTitle: String {
        switch mode {
        case .monthly: AppDateFormatter.monthString(from: month(at: monthOffset))
        case .yearly: AppDateFormatter.yearString(from: year(at: yearOffset))
        case .all: ""
        }
    }

    private var canGoBack: Bool {
        switch mode {
        case .monthly: monthOffset > Self.monthRange.lowerBound
        case .yearly: yearOffset > Self.yearRange.lowerBound
        case .all: false
        }
    }

    var body: some View {
        // 集計用に値だけ写し取る（集計そのものは各ページがバックグラウンドで行う）
        let input = ReportInput(items: items, supplies: supplies)

        VStack(spacing: 0) {
            largeTitle

            Picker("期間", selection: $mode) {
                ForEach(ReportPeriodMode.allCases) { mode in
                    Text(mode.title).tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, AppTheme.Metrics.screenPadding)
            .padding(.top, 8)

            if mode != .all {
                periodHeader
            }

            switch mode {
            case .monthly:
                monthlyPager(input: input)
            case .yearly:
                yearlyPager(input: input)
            case .all:
                AllTimeReportContent(
                    input: input,
                    cache: cache,
                    items: items,
                    currencyCode: currencyCode,
                    onOpenYear: openYear
                )
                .padding(.top, 12)
                .environment(\.reportScrollHandler, scrollHandler(isActive: true))
            }
        }
        .environment(\.reportCollapsedHeight, collapsibleHeight * collapseProgress)
        .background(Color(uiColor: .systemGroupedBackground))
        .onChange(of: monthOffset) { resetCollapse() }
        .onChange(of: yearOffset) { resetCollapse() }
        .onChange(of: mode) { oldMode, _ in
            resetCollapse()
            // 「月」「年」から離れたら今月・今年に戻しておく。次に開いたときは今月・今年から表示する
            // （グラフから特定の月・年を開く場合は、openMonth / openYear が離れた後に設定するので影響しない）
            switch oldMode {
            case .monthly: monthOffset = 0
            case .yearly: yearOffset = 0
            case .all: break
            }
        }
        .onChange(of: isTabActive) { _, isActive in
            // 他のタブへ移ったら今月・今年に戻す（詳細画面への push では戻さない）
            if isActive == false {
                monthOffset = 0
                yearOffset = 0
            }
        }
        .task(id: PrefetchID(mode: mode.rawValue, monthOffset: monthOffset, yearOffset: yearOffset, input: input)) {
            await prefetchNeighbors(input: input)
        }
        // 大きいタイトルは自前で描いてスクロールに合わせて縮める。
        // （ページ送りの中の List はナビゲーションバーが追従できないため、標準の大きいタイトルは縮まない）
        .navigationTitle("レポート")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("レポート")
                    .font(.headline)
                    .opacity(inlineTitleOpacity)
                    .accessibilityHidden(collapseProgress < 0.6)
            }
            .sharedBackgroundVisibility(.hidden)
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink {
                    SoldItemFormView()
                } label: {
                    Label("追加", systemImage: "plus")
                }
            }
        }
    }

    /// 販売記録の大きいタイトルと同じ見た目。スクロールすると上に隠れていく
    private var largeTitle: some View {
        Text("レポート")
            .font(.largeTitle.bold())
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, AppTheme.Metrics.screenPadding)
            .padding(.top, 4)
            .padding(.bottom, 8)
            .fixedSize(horizontal: false, vertical: true)
            .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { height in
                largeTitleHeight = height
            }
            .frame(height: largeTitleHeight * (1 - collapseProgress), alignment: .bottom)
            .clipped()
            .opacity(largeTitleOpacity)
            .accessibilityAddTraits(.isHeader)
    }

    /// 大きいタイトルは縮み始めてすぐ薄くなる
    private var largeTitleOpacity: Double {
        1 - min(Double(collapseProgress) / 0.6, 1)
    }

    /// ナビゲーションバーの小さいタイトルは、大きいタイトルがほぼ隠れてから出てくる
    private var inlineTitleOpacity: Double {
        min(max((Double(collapseProgress) - 0.6) / 0.4, 0), 1)
    }

    /// 表示中のページにだけスクロールの通知先を渡す
    private func scrollHandler(isActive: Bool) -> ((ReportScrollMetrics) -> Void)? {
        guard isActive else { return nil }
        return { metrics in handleScroll(metrics) }
    }

    private var collapsibleHeight: CGFloat {
        largeTitleHeight + (mode == .all ? 0 : Self.periodHeaderCollapse)
    }

    /// 表示中のページのスクロール量から、上部の縮み具合を決める
    private func handleScroll(_ metrics: ReportScrollMetrics) {
        // 縮んだ分は List の下に余白を足しているので、scrollableHeight は縮み具合によらず一定になる
        let scrollable = metrics.scrollableHeight
        let progress: CGFloat
        if scrollable < 8 {
            // ほとんどスクロールできないページは縮めない
            progress = 0
        } else {
            // 内容が短い月でも、一番下までスクロールすれば最後まで縮むようにする
            let distance = min(collapsibleHeight, scrollable)
            progress = min(max(metrics.offset / distance, 0), 1)
        }
        if abs(progress - collapseProgress) > 0.001 {
            collapseProgress = progress
        }
    }

    /// ページや「月 / 年 / すべて」を切り替えたら、新しいページは一番上から始まるので元の大きさに戻す
    private func resetCollapse() {
        guard collapseProgress != 0 else { return }
        withAnimation(.snappy(duration: 0.25)) {
            collapseProgress = 0
        }
    }

    // Header (Non-sliding). List を使わず固定の高さで描画して、下のコンテンツに隠れないようにする
    private var periodHeader: some View {
        HStack {
            Button {
                step(-1)
            } label: {
                Image(systemName: "chevron.left")
                    .frame(width: 44, height: 44 - 8 * collapseProgress)
                    .contentShape(Rectangle())
            }
            .opacity(canGoBack ? 1.0 : 0)
            .disabled(canGoBack == false)

            Spacer()

            Text(periodTitle)
                .font(.headline)
                .contentTransition(.numericText())

            Spacer()

            Button {
                step(1)
            } label: {
                Image(systemName: "chevron.right")
                    .frame(width: 44, height: 44 - 8 * collapseProgress)
                    .contentShape(Rectangle())
            }
            .opacity(currentOffset >= 0 ? 0 : 1.0)
            .disabled(currentOffset >= 0)
        }
        .buttonStyle(.borderless)
        .padding(.horizontal, 4)
        .background(AppTheme.Colors.cardBackground, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .padding(.horizontal, AppTheme.Metrics.screenPadding + 4)
        // 縮んだときは上下の余白を減らす（合計 periodHeaderCollapse 分）
        .padding(.top, 16 - 10 * collapseProgress)
        .padding(.bottom, 12 - 6 * collapseProgress)
    }

    // 121 ページ全部を作ると重いので、表示中のページと左右 1 ページだけ中身を作る
    private func monthlyPager(input: ReportInput) -> some View {
        TabView(selection: clampedBinding($monthOffset, to: Self.monthRange)) {
            ForEach(Self.monthRange, id: \.self) { offset in
                ZStack {
                    if abs(offset - monthOffset) <= 1 {
                        MonthlyReportContent(
                            month: month(at: offset),
                            input: input,
                            cache: cache,
                            items: items,
                            currencyCode: currencyCode
                        )
                    }
                }
                .environment(\.reportScrollHandler, scrollHandler(isActive: offset == monthOffset))
                .tag(offset)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
    }

    private func yearlyPager(input: ReportInput) -> some View {
        TabView(selection: clampedBinding($yearOffset, to: Self.yearRange)) {
            ForEach(Self.yearRange, id: \.self) { offset in
                ZStack {
                    if abs(offset - yearOffset) <= 1 {
                        YearlyReportContent(
                            year: year(at: offset),
                            input: input,
                            cache: cache,
                            items: items,
                            currencyCode: currencyCode,
                            onOpenMonth: openMonth
                        )
                    }
                }
                .environment(\.reportScrollHandler, scrollHandler(isActive: offset == yearOffset))
                .tag(offset)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
    }

    private nonisolated struct PrefetchID: Equatable {
        let mode: String
        let monthOffset: Int
        let yearOffset: Int
        let input: ReportInput
    }

    /// 左右のページと、他のモード（月 / 年 / すべて）の表示予定ページを先に集計しておき、
    /// めくったり切り替えたりしたときに待たずに表示できるようにする
    private func prefetchNeighbors(input: ReportInput) async {
        let currentMonth = month(at: monthOffset)
        let currentYear = year(at: yearOffset)
        await cache.prefetch(.month(currentMonth), input: input, compute: ReportComputation.monthly(currentMonth))
        await cache.prefetch(.year(currentYear), input: input, compute: ReportComputation.yearly(currentYear))
        await cache.prefetch(.allTime, input: input, compute: ReportComputation.allTime)

        switch mode {
        case .monthly:
            for offset in [monthOffset + 1, monthOffset - 1] where Self.monthRange.contains(offset) {
                let target = month(at: offset)
                await cache.prefetch(.month(target), input: input, compute: ReportComputation.monthly(target))
            }
        case .yearly:
            for offset in [yearOffset + 1, yearOffset - 1] where Self.yearRange.contains(offset) {
                let target = year(at: offset)
                await cache.prefetch(.year(target), input: input, compute: ReportComputation.yearly(target))
            }
        case .all:
            break
        }
    }

    private func step(_ delta: Int) {
        withAnimation {
            switch mode {
            case .monthly:
                monthOffset = (monthOffset + delta).clamped(to: Self.monthRange)
            case .yearly:
                yearOffset = (yearOffset + delta).clamped(to: Self.yearRange)
            case .all:
                break
            }
        }
    }

    /// 年次の月別推移から、その月の月次レポートへ移動する
    private func openMonth(_ monthStart: Date) {
        let offset = calendar.dateComponents([.month], from: initialMonth, to: monthStart).month ?? 0
        monthOffset = offset.clamped(to: Self.monthRange)
        withAnimation {
            mode = .monthly
        }
    }

    /// 「すべて」の年別推移から、その年の年次レポートへ移動する
    private func openYear(_ yearStart: Date) {
        let offset = calendar.dateComponents([.year], from: initialYear, to: yearStart).year ?? 0
        yearOffset = offset.clamped(to: Self.yearRange)
        withAnimation {
            mode = .yearly
        }
    }

    private func clampedBinding(_ binding: Binding<Int>, to range: ClosedRange<Int>) -> Binding<Int> {
        Binding(
            get: { binding.wrappedValue },
            set: { newValue in
                if range.contains(newValue) {
                    binding.wrappedValue = newValue
                }
            }
        )
    }
}

private extension Int {
    func clamped(to range: ClosedRange<Int>) -> Int {
        Swift.min(Swift.max(self, range.lowerBound), range.upperBound)
    }
}

#Preview {
    NavigationStack {
        ReportView()
    }
    .modelContainer(for: [SoldItem.self, SupplyItem.self], inMemory: true)
}
