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

    // 0 is current month, negative is past, positive is future
    @State private var monthOffset: Int = 0
    @AppStorage(AppSettingsKey.currencyCode) private var currencyCode = AppDefaults.currencyCode

    private let calendar = Calendar.current
    private let initialMonth: Date

    init() {
        let now = Date()
        self.initialMonth = Calendar.current.dateInterval(of: .month, for: now)?.start ?? now
    }

    private var selectedMonth: Date {
        calendar.date(byAdding: .month, value: monthOffset, to: initialMonth) ?? initialMonth
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header (Non-sliding, matching the old List row look)
            List {
                Section {
                    HStack {
                        Button {
                            withAnimation { monthOffset -= 1 }
                        } label: {
                            Image(systemName: "chevron.left")
                        }

                        Spacer()

                        Text(AppDateFormatter.monthString(from: selectedMonth))
                            .font(.headline)

                        Spacer()

                        Button {
                            withAnimation { monthOffset += 1 }
                        } label: {
                            Image(systemName: "chevron.right")
                        }
                        .opacity(monthOffset >= 0 ? 0 : 1.0)
                        .disabled(monthOffset >= 0)
                    }
                    .buttonStyle(.borderless)
                }
            }
            .frame(height: 80) // Reduced from 100
            .scrollDisabled(true)
            .environment(\.defaultMinListHeaderHeight, 0)
            .padding(.bottom, -15) // Pull the content up

            TabView(selection: Binding(
                get: { monthOffset },
                set: { newValue in
                    if newValue <= 0 {
                        monthOffset = newValue
                    }
                }
            )) {
                // Restricted range: past 10 years up to the current month
                ForEach(-120...0, id: \.self) { offset in
                    MonthlyReportContent(
                        month: calendar.date(byAdding: .month, value: offset, to: initialMonth) ?? initialMonth,
                        items: items,
                        supplies: supplies,
                        currencyCode: currencyCode
                    )
                    .tag(offset)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .background(Color(uiColor: .systemGroupedBackground))
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
}

private struct MonthlyReportContent: View {
    let month: Date
    let items: [SoldItem]
    let supplies: [SupplyItem]
    let currencyCode: String

    private let calendar = Calendar.current
    
    private var currencyFormatter: AppCurrencyFormatter {
        AppCurrencyFormatter(currencyCode: currencyCode)
    }

    private var monthlyItems: [SoldItem] {
        items.filter { item in
            guard let interval = calendar.dateInterval(of: .month, for: month) else {
                return false
            }
            return item.soldAt >= interval.start && item.soldAt < interval.end
        }
    }

    private var topProfitItems: [SoldItem] {
        Array(monthlyItems.sorted { $0.profit > $1.profit }.prefix(5))
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
            in: month,
            calendar: calendar
        )
    }

    private var monthlySupplyCost: Decimal {
        SupplyCostCalculator.monthlySupplyCost(soldItems: items, supplies: supplies, in: month, calendar: calendar)
    }

    private var monthlySoldCount: Int {
        monthlyItems.count
    }

    private var averageProfit: Decimal? {
        guard monthlyItems.isEmpty == false else { return nil }
        return monthlyProfit / Decimal(max(monthlySoldCount, 1))
    }

    private var averageProfitRate: Decimal? {
        guard monthlySales != 0 else { return nil }
        return monthlyProfit / monthlySales
    }

    var body: some View {
        List {
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
                    reportRow("利益", currencyFormatter.string(from: monthlyProfit), valueTint: AppTheme.profitColor(for: monthlyProfit))
                    reportRow("販売件数", "\(monthlySoldCount)", valueTint: AppTheme.Colors.secondary)
                    reportRow("資材費用", currencyFormatter.string(from: monthlySupplyCost), valueTint: AppTheme.Colors.cost)
                }


                Section("利益上位5件") {
                    ForEach(topProfitItems) { item in
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
        MonthlyReportView()
    }
    .modelContainer(for: [SoldItem.self, SupplyItem.self], inMemory: true)
}
