//
//  YearlyReportView.swift
//  URIAGE
//
//  年次レポート：サマリー（前年比）・月別推移・利益上位5件
//

import SwiftUI
import SwiftData
import Charts

struct YearlyReportContent: View {
    let year: Date
    let items: [SoldItem]
    let supplies: [SupplyItem]
    let currencyCode: String
    let onOpenMonth: (Date) -> Void

    private var currencyFormatter: AppCurrencyFormatter {
        AppCurrencyFormatter(currencyCode: currencyCode)
    }

    var body: some View {
        // body の評価ごとに 1 回だけ集計する
        let report = YearlyReport(year: year, soldItems: items, supplies: supplies)

        List {
            if report.isEmpty {
                Section {
                    EmptyStateCard(
                        title: "この年の販売記録はありません",
                        message: "販売記録を追加すると、1年間の売上と利益の推移を確認できます。",
                        systemImage: "chart.bar.xaxis"
                    ) {
                        NavigationLink {
                            SoldItemFormView()
                        } label: {
                            Label("記録を追加", systemImage: "plus")
                        }
                    }
                }
                .listRowBackground(Color.clear)
            } else {
                summarySection(report)

                Section("月別推移") {
                    MonthlyTrendChart(
                        months: report.months,
                        bestMonth: report.bestMonth,
                        currencyFormatter: currencyFormatter,
                        onOpenMonth: onOpenMonth
                    )
                    .padding(.vertical, 8)
                }

                Section("利益上位5件") {
                    ForEach(report.topProfitItems) { item in
                        NavigationLink {
                            SoldItemDetailView(item: item)
                        } label: {
                            ReportItemRow(item: item, currencyFormatter: currencyFormatter)
                        }
                    }
                }
            }
        }
        .contentMargins(.top, 0, for: .scrollContent)
        .safeAreaPadding(.top, -10)
    }

    // MARK: - Summary

    @ViewBuilder
    private func summarySection(_ report: YearlyReport) -> some View {
        let comparisonLabel = report.isCurrentYear ? "前年同期比" : "前年比"

        Section {
            summaryRow(
                "販売額",
                currencyFormatter.string(from: report.sales),
                valueTint: AppTheme.Colors.sales,
                change: report.salesChangeRate,
                changeLabel: comparisonLabel
            )
            summaryRow(
                "利益",
                currencyFormatter.string(from: report.profit),
                valueTint: AppTheme.profitColor(for: report.profit),
                change: report.profitChangeRate,
                changeLabel: comparisonLabel
            )
            summaryRow("販売件数", "\(report.soldCount)", valueTint: AppTheme.Colors.secondary)
            summaryRow("資材費用", currencyFormatter.string(from: report.supplyCost), valueTint: AppTheme.Colors.cost)
        } header: {
            Text("サマリー")
        }
    }

    private func summaryRow(
        _ label: String,
        _ value: String,
        valueTint: Color,
        change: Decimal? = nil,
        changeLabel: String = ""
    ) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 16) {
            Text(label)
                .foregroundStyle(.secondary)
            Spacer(minLength: 16)
            VStack(alignment: .trailing, spacing: 2) {
                Text(value)
                    .fontWeight(.semibold)
                    .foregroundStyle(valueTint)
                if let change {
                    Text("\(changeLabel) \(Self.signedPercent(change))")
                        .font(.caption)
                        .foregroundStyle(change >= 0 ? AppTheme.Colors.success : AppTheme.Colors.loss)
                }
            }
            .multilineTextAlignment(.trailing)
        }
    }

    static func signedPercent(_ value: Decimal) -> String {
        let text = AppPercentFormatter().string(from: abs(value))
        return value >= 0 ? "+\(text)" : "−\(text)"
    }
}

// MARK: - Monthly trend chart

private struct MonthlyTrendChart: View {
    let months: [YearlyReport.Month]
    let bestMonth: YearlyReport.Month?
    let currencyFormatter: AppCurrencyFormatter
    let onOpenMonth: (Date) -> Void

    @State private var selectedLabel: String?

    private var selectedMonth: YearlyReport.Month? {
        guard let selectedLabel else { return nil }
        return months.first { $0.label == selectedLabel && $0.isFuture == false }
    }

    private var pastMonths: [YearlyReport.Month] {
        months.filter { $0.isFuture == false }
    }

    private var hasNegativeProfit: Bool {
        pastMonths.contains { $0.profit < 0 }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Chart {
                ForEach(months) { month in
                    BarMark(
                        x: .value("月", month.label),
                        y: .value("販売額", month.sales.doubleValue)
                    )
                    .cornerRadius(4)
                    .foregroundStyle(AppTheme.Colors.sales.opacity(barOpacity(for: month)))
                }

                ForEach(pastMonths) { month in
                    LineMark(
                        x: .value("月", month.label),
                        y: .value("利益", month.profit.doubleValue),
                        series: .value("系列", "利益")
                    )
                    .foregroundStyle(AppTheme.Colors.success)
                    .lineStyle(StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
                    .interpolationMethod(.monotone)

                    PointMark(
                        x: .value("月", month.label),
                        y: .value("利益", month.profit.doubleValue)
                    )
                    .foregroundStyle(AppTheme.profitColor(for: month.profit))
                    .symbolSize(month.label == selectedLabel ? 110 : 45)
                }

                if hasNegativeProfit {
                    RuleMark(y: .value("ゼロ", 0))
                        .foregroundStyle(.secondary.opacity(0.5))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [3, 3]))
                }
            }
            .chartXSelection(value: $selectedLabel)
            // 標準の選択は指を離すと解除されるので、タップで選択を保持する
            .chartGesture { proxy in
                SpatialTapGesture().onEnded { value in
                    proxy.selectXValue(at: value.location.x)
                }
            }
            .chartXAxis {
                AxisMarks { value in
                    AxisValueLabel {
                        if let label = value.as(String.self) {
                            Text(label.replacingOccurrences(of: "月", with: ""))
                        }
                    }
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    AxisGridLine()
                    AxisValueLabel {
                        if let amount = value.as(Double.self) {
                            Text(amount.formatted(.number.notation(.compactName).locale(Locale(identifier: "ja_JP"))))
                        }
                    }
                }
            }
            .frame(height: 220)
            .onChange(of: selectedLabel) { _, newValue in
                // 未来の月は選択させない
                if let newValue, months.first(where: { $0.label == newValue })?.isFuture == true {
                    selectedLabel = nil
                }
            }

            legend

            // 選択中の月 / ベスト月の情報はグラフの下に置く
            detailHeader
                .frame(maxWidth: .infinity, minHeight: 64, alignment: .topLeading)
                .padding(.top, 4)
                .animation(.snappy, value: selectedLabel)
        }
    }

    // 販売額の棒は背景として淡く、利益の線を主役にする
    private func barOpacity(for month: YearlyReport.Month) -> Double {
        guard selectedLabel != nil else { return 0.28 }
        return month.label == selectedLabel ? 0.55 : 0.14
    }

    @ViewBuilder
    private var detailHeader: some View {
        if let month = selectedMonth {
            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .firstTextBaseline) {
                    Text(month.label)
                        .font(.headline)
                    Spacer()
                    Button {
                        onOpenMonth(month.start)
                    } label: {
                        HStack(spacing: 2) {
                            Text("月次レポート")
                            Image(systemName: "chevron.right")
                        }
                        .font(.subheadline)
                    }
                    .buttonStyle(.borderless)
                }

                HStack(spacing: 16) {
                    metric("販売額", currencyFormatter.string(from: month.sales), tint: AppTheme.Colors.sales)
                    metric("利益", currencyFormatter.string(from: month.profit), tint: AppTheme.profitColor(for: month.profit))
                    metric("件数", "\(month.soldCount)", tint: AppTheme.Colors.secondary)
                }
            }
        } else {
            VStack(alignment: .leading, spacing: 6) {
                if let bestMonth {
                    HStack(spacing: 6) {
                        Image(systemName: "crown.fill")
                            .foregroundStyle(AppTheme.Colors.warning)
                        Text("ベスト月は\(bestMonth.label)")
                            .font(.headline)
                    }
                    Text("利益 \(currencyFormatter.string(from: bestMonth.profit))・\(bestMonth.soldCount)件")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Text("グラフをタップすると月ごとの数字を表示します")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
    }

    private func metric(_ label: String, _ value: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(tint)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
    }

    private var legend: some View {
        HStack(spacing: 16) {
            legendItem(color: AppTheme.Colors.sales.opacity(0.35), label: "販売額", isLine: false)
            legendItem(color: AppTheme.Colors.success, label: "利益", isLine: true)
        }
        .font(.caption)
        .foregroundStyle(.secondary)
    }

    private func legendItem(color: Color, label: String, isLine: Bool) -> some View {
        HStack(spacing: 6) {
            if isLine {
                Capsule().fill(color).frame(width: 14, height: 3)
            } else {
                RoundedRectangle(cornerRadius: 2).fill(color).frame(width: 10, height: 10)
            }
            Text(label)
        }
    }
}

private extension Decimal {
    var doubleValue: Double {
        NSDecimalNumber(decimal: self).doubleValue
    }
}
