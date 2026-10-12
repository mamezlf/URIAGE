//
//  MonthlyReportView.swift
//  URIAGE
//
//  Created by Codex on 2026/04/26.
//

import SwiftUI
import SwiftData

struct MonthlyReportContent: View {
    let month: Date
    let input: ReportInput
    let cache: ReportCache
    /// 利益上位の行から詳細画面へ遷移するときに使う
    let items: [SoldItem]
    let currencyCode: String

    private var currencyFormatter: AppCurrencyFormatter {
        AppCurrencyFormatter(currencyCode: currencyCode)
    }

    var body: some View {
        ReportLoader(
            key: .month(month),
            input: input,
            cache: cache,
            compute: ReportComputation.monthly(month)
        ) { report in
            reportList(report)
        } placeholder: {
            ReportSkeleton()
        }
        .contentMargins(.top, 0, for: .scrollContent)
        .safeAreaPadding(.top, -10)
    }

    private func reportList(_ report: MonthlyReport) -> some View {
        List {
            if report.isEmpty {
                Section {
                    EmptyStateCard(
                        title: "この月の販売記録はありません",
                        message: "販売記録を追加すると、月次の売上・コスト・利益を確認できます。",
                        systemImage: "chart.bar"
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
                    reportRow("販売額", currencyFormatter.string(from: report.sales), valueTint: AppTheme.Colors.sales)
                    reportRow("利益", currencyFormatter.string(from: report.profit), valueTint: AppTheme.profitColor(for: report.profit))
                    reportRow("販売件数", "\(report.soldCount)", valueTint: AppTheme.Colors.secondary)
                    reportRow("資材費用", currencyFormatter.string(from: report.supplyCost), valueTint: AppTheme.Colors.cost)
                }

                Section("利益上位5件") {
                    ForEach(report.topProfitItems) { record in
                        ReportItemLink(record: record, items: items, currencyFormatter: currencyFormatter)
                    }
                }
            }
        }
    }

    private func reportRow(_ label: String, _ value: String, valueTint: Color = .primary) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 16) {
            Text(label)
                .foregroundStyle(.secondary)
            Spacer(minLength: 16)
            Text(value)
                .fontWeight(.semibold)
                .foregroundStyle(valueTint)
                .multilineTextAlignment(.trailing)
        }
    }
}

#Preview {
    NavigationStack {
        ReportView()
    }
    .modelContainer(for: [SoldItem.self, SupplyItem.self], inMemory: true)
}
