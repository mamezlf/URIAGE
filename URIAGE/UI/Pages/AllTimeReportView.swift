//
//  AllTimeReportView.swift
//  URIAGE
//
//  「すべて」レポート：通算サマリー・年別推移・通算の利益上位5件
//

import SwiftUI
import SwiftData

struct AllTimeReportContent: View {
    let input: ReportInput
    let cache: ReportCache
    /// 利益上位の行から詳細画面へ遷移するときに使う
    let items: [SoldItem]
    let currencyCode: String
    let onOpenYear: (Date) -> Void

    private var currencyFormatter: AppCurrencyFormatter {
        AppCurrencyFormatter(currencyCode: currencyCode)
    }

    var body: some View {
        ReportLoader(
            key: .allTime,
            input: input,
            cache: cache,
            compute: ReportComputation.allTime
        ) { report in
            reportList(report)
                .reportScrollTracking()
        } placeholder: {
            ReportSkeleton(chartTitle: "年別推移")
        }
        .contentMargins(.top, 0, for: .scrollContent)
    }

    private func reportList(_ report: AllTimeReport) -> some View {
        List {
            if report.isEmpty {
                Section {
                    EmptyStateCard(
                        title: "まだ販売記録はありません",
                        message: "販売記録を追加すると、これまでの売上と利益の推移を確認できます。",
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
                Section("サマリー") {
                    row("販売額", currencyFormatter.string(from: report.sales), tint: AppTheme.Colors.sales)
                    row("利益", currencyFormatter.string(from: report.profit), tint: AppTheme.profitColor(for: report.profit))
                    row("販売件数", "\(report.soldCount)", tint: AppTheme.Colors.secondary)
                    row("資材費用", currencyFormatter.string(from: report.supplyCost), tint: AppTheme.Colors.cost)
                }

                Section("年別推移") {
                    ReportTrendChart(
                        points: report.trendPoints,
                        bestPoint: report.trendPoint(for: report.bestYear),
                        unit: .year,
                        currencyFormatter: currencyFormatter,
                        onOpen: onOpenYear
                    )
                    .padding(.vertical, 8)
                }

                Section("利益上位5件") {
                    ForEach(report.topProfitItems) { record in
                        ReportItemLink(record: record, items: items, currencyFormatter: currencyFormatter)
                    }
                }
            }
        }
    }

    private func row(_ label: String, _ value: String, tint: Color) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 16) {
            Text(label)
                .foregroundStyle(.secondary)
            Spacer(minLength: 16)
            Text(value)
                .fontWeight(.semibold)
                .foregroundStyle(tint)
                .multilineTextAlignment(.trailing)
        }
    }
}
