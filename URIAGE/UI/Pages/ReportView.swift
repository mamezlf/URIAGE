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

    private let calendar = Calendar.current
    private let initialMonth: Date
    private let initialYear: Date

    /// 過去 10 年分までさかのぼれる
    private static let monthRange = -120...0
    private static let yearRange = -10...0

    init() {
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
        VStack(spacing: 0) {
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
                monthlyPager
            case .yearly:
                yearlyPager
            case .all:
                AllTimeReportContent(
                    items: items,
                    supplies: supplies,
                    currencyCode: currencyCode,
                    onOpenYear: openYear
                )
                .padding(.top, 12)
            }
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .navigationTitle("レポート")
        .toolbar {
            if currentOffset != 0 {
                ToolbarItem(placement: .topBarLeading) {
                    Button(mode == .monthly ? "今月" : "今年") {
                        withAnimation {
                            switch mode {
                            case .monthly: monthOffset = 0
                            case .yearly: yearOffset = 0
                            case .all: break
                            }
                        }
                    }
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink {
                    SoldItemFormView()
                } label: {
                    Label("追加", systemImage: "plus")
                }
            }
        }
    }

    // Header (Non-sliding). List を使わず固定の高さで描画して、下のコンテンツに隠れないようにする
    private var periodHeader: some View {
        HStack {
            Button {
                step(-1)
            } label: {
                Image(systemName: "chevron.left")
                    .frame(width: 44, height: 44)
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
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .opacity(currentOffset >= 0 ? 0 : 1.0)
            .disabled(currentOffset >= 0)
        }
        .buttonStyle(.borderless)
        .padding(.horizontal, 4)
        .background(AppTheme.Colors.cardBackground, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .padding(.horizontal, AppTheme.Metrics.screenPadding + 4)
        .padding(.top, 16)
        .padding(.bottom, 12)
    }

    private var monthlyPager: some View {
        TabView(selection: clampedBinding($monthOffset, to: Self.monthRange)) {
            ForEach(Self.monthRange, id: \.self) { offset in
                MonthlyReportContent(
                    month: month(at: offset),
                    items: items,
                    supplies: supplies,
                    currencyCode: currencyCode
                )
                .tag(offset)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
    }

    private var yearlyPager: some View {
        TabView(selection: clampedBinding($yearOffset, to: Self.yearRange)) {
            ForEach(Self.yearRange, id: \.self) { offset in
                YearlyReportContent(
                    year: year(at: offset),
                    items: items,
                    supplies: supplies,
                    currencyCode: currencyCode,
                    onOpenMonth: openMonth
                )
                .tag(offset)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
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
