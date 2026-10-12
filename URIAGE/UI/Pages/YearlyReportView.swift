//
//  YearlyReportView.swift
//  URIAGE
//
//  年次レポート：サマリー（前年比）・月別推移・利益上位5件
//

import SwiftUI
import SwiftData

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
        // ページを開いた直後はスケルトンを出し、集計は次のフレーム以降に行う
        DeferredContent {
            // 描画ごとに 1 回だけ集計する
            reportList(YearlyReport(year: year, soldItems: items, supplies: supplies))
        } placeholder: {
            ReportSkeleton(chartTitle: "月別推移")
        }
        .contentMargins(.top, 0, for: .scrollContent)
        .safeAreaPadding(.top, -10)
    }

    private func reportList(_ report: YearlyReport) -> some View {
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
                    ReportTrendChart(
                        points: report.trendPoints,
                        bestPoint: report.bestTrendPoint,
                        unit: .month,
                        currencyFormatter: currencyFormatter,
                        onOpen: onOpenMonth
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
