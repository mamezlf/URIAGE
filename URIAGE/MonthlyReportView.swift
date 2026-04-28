//
//  MonthlyReportView.swift
//  URIAGE
//
//  Created by Codex on 2026/04/26.
//

import SwiftUI
import SwiftData

struct MonthlyReportView: View {
    @Query(sort: \SoldItem.soldAt, order: .reverse) private var items: [SoldItem]
    @Query(sort: \SupplyItem.purchaseDate, order: .reverse) private var supplies: [SupplyItem]

    @State private var selectedMonth = Date()
    @AppStorage(AppSettingsKey.currencyCode) private var currencyCode = AppDefaults.currencyCode

    private var currencyFormatter: AppCurrencyFormatter {
        AppCurrencyFormatter(currencyCode: currencyCode)
    }

    private let percentFormatter = AppPercentFormatter()
    private let calendar = Calendar.current

    private var monthlyItems: [SoldItem] {
        items.filter { item in
            guard let interval = calendar.dateInterval(of: .month, for: selectedMonth) else {
                return false
            }

            return item.soldAt >= interval.start && item.soldAt < interval.end
        }
    }

    private var topProfitItems: [SoldItem] {
        Array(monthlyItems.sorted { $0.profit > $1.profit }.prefix(5))
    }

    private var lossItems: [SoldItem] {
        monthlyItems
            .filter { $0.profit < 0 }
            .sorted { $0.profit < $1.profit }
    }

    private var monthlySales: Decimal {
        monthlyItems.reduce(0) { $0 + $1.salePrice }
    }

    private var monthlyNetIncome: Decimal {
        monthlyItems.reduce(0) { $0 + $1.netIncome }
    }

    private var monthlyTotalCost: Decimal {
        monthlyItems.reduce(0) { $0 + $1.totalCost }
    }

    private var monthlyProfit: Decimal {
        SupplyCostCalculator.monthlyProfitAfterRegisteredSupplyCost(
            soldItems: items,
            supplies: supplies,
            in: selectedMonth,
            calendar: calendar
        )
    }

    private var monthlySupplyCost: Decimal {
        SupplyCostCalculator.monthlySupplyCost(soldItems: items, supplies: supplies, in: selectedMonth, calendar: calendar)
    }

    private var monthlySoldCount: Int {
        monthlyItems.count
    }

    private var averageProfit: Decimal? {
        guard monthlyItems.isEmpty == false else {
            return nil
        }

        return monthlyProfit / Decimal(max(monthlySoldCount, 1))
    }

    private var averageProfitRate: Decimal? {
        guard monthlySales != 0 else {
            return nil
        }

        return monthlyProfit / monthlySales
    }

    var body: some View {
        List {
            Section {
                HStack {
                    Button {
                        moveMonth(by: -1)
                    } label: {
                        Image(systemName: "chevron.left")
                    }

                    Spacer()

                    Text(AppDateFormatter.monthString(from: selectedMonth))
                        .font(.headline)

                    Spacer()

                    Button {
                        moveMonth(by: 1)
                    } label: {
                        Image(systemName: "chevron.right")
                    }
                }
                .buttonStyle(.borderless)
            }

            if monthlyItems.isEmpty {
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
                    reportRow("販売額", currencyFormatter.string(from: monthlySales), valueTint: AppTheme.Colors.sales)
                    reportRow("純売上", currencyFormatter.string(from: monthlyNetIncome), valueTint: AppTheme.Colors.sales)
                    reportRow("総コスト", currencyFormatter.string(from: monthlyTotalCost), valueTint: AppTheme.Colors.cost)
                    reportRow("資材費用", currencyFormatter.string(from: monthlySupplyCost), valueTint: AppTheme.Colors.cost)
                    reportRow("利益", currencyFormatter.string(from: monthlyProfit), valueTint: AppTheme.profitColor(for: monthlyProfit))
                    reportRow("平均利益率", percentFormatter.string(from: averageProfitRate))
                    reportRow("販売件数", "\(monthlySoldCount)")
                    reportRow(
                        "平均単品利益",
                        averageProfit.map { currencyFormatter.string(from: $0) } ?? "-",
                        valueTint: AppTheme.profitColor(for: averageProfit ?? 0)
                    )
                }

                Section("利益上位5件") {
                    ForEach(topProfitItems) { item in
                        NavigationLink {
                            SoldItemDetailView(item: item)
                        } label: {
                            ReportItemRow(item: item, currencyFormatter: currencyFormatter, percentFormatter: percentFormatter)
                        }
                    }
                }

                Section("赤字商品") {
                    if lossItems.isEmpty {
                        emptyRow("この月の赤字商品はありません。")
                    } else {
                        ForEach(lossItems) { item in
                            NavigationLink {
                                SoldItemDetailView(item: item)
                            } label: {
                                ReportItemRow(item: item, currencyFormatter: currencyFormatter, percentFormatter: percentFormatter)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("月次レポート")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink {
                    SoldItemFormView()
                } label: {
                    Label("追加", systemImage: "plus")
                }
            }
        }
    }

    private func moveMonth(by value: Int) {
        selectedMonth = calendar.date(byAdding: .month, value: value, to: selectedMonth) ?? selectedMonth
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

    private func emptyRow(_ text: String) -> some View {
        Text(text)
            .foregroundStyle(.secondary)
    }
}

private struct ReportItemRow: View {
    let item: SoldItem
    let currencyFormatter: AppCurrencyFormatter
    let percentFormatter: AppPercentFormatter

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline, spacing: 12) {
                Text(item.title)
                    .font(.subheadline.bold())
                    .lineLimit(1)

                Spacer(minLength: 12)

                ProfitText(value: item.profit, formatter: currencyFormatter, font: .subheadline.bold())
            }

            HStack(alignment: .firstTextBaseline, spacing: 12) {
                Text(AppDateFormatter.dateString(from: item.soldAt))
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Spacer(minLength: 12)

                Text(percentFormatter.string(from: item.profitRate))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    NavigationStack {
        MonthlyReportView()
    }
    .modelContainer(for: [SoldItem.self, SupplyItem.self], inMemory: true)
}
