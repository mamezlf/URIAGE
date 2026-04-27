//
//  ContentView.swift
//  URIAGE
//
//  Created by zlf on 2026/04/26.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \SoldItem.soldAt, order: .reverse) private var items: [SoldItem]
#if DEBUG
    @Query(sort: \SupplyItem.purchaseDate, order: .reverse) private var supplies: [SupplyItem]
#endif

    var body: some View {
        TabView {
            NavigationStack {
                DashboardView(items: items)
            }
            .tabItem {
                Label("ホーム", systemImage: "house.fill")
            }

            NavigationStack {
                SoldItemListView()
            }
            .tabItem {
                Label("記録", systemImage: "list.bullet.rectangle")
            }

            NavigationStack {
                MonthlyReportView()
            }
            .tabItem {
                Label("レポート", systemImage: "chart.bar.xaxis")
            }

            NavigationStack {
                SuppliesView()
            }
            .tabItem {
                Label("資材", systemImage: "shippingbox")
            }

            NavigationStack {
                SettingsView()
            }
            .tabItem {
                Label("設定", systemImage: "gearshape.fill")
            }
        }
#if DEBUG
        .onAppear(perform: seedSamplesIfNeeded)
#endif
    }

#if DEBUG
    private func seedSamplesIfNeeded() {
        guard items.isEmpty, supplies.isEmpty else {
            return
        }

        SoldItem.samples.forEach { modelContext.insert($0) }
    }
#endif
}

private struct DashboardView: View {
    let items: [SoldItem]

    @AppStorage(AppSettingsKey.currencyCode) private var currencyCode = AppDefaults.currencyCode

    private var currencyFormatter: AppCurrencyFormatter {
        AppCurrencyFormatter(currencyCode: currencyCode)
    }

    private var monthlyItems: [SoldItem] {
        items.filter { Calendar.current.isDate($0.soldAt, equalTo: Date(), toGranularity: .month) }
    }

    private var recentItems: [SoldItem] {
        Array(items.sorted { $0.soldAt > $1.soldAt }.prefix(5))
    }

    private var monthlySales: Decimal {
        monthlyItems.reduce(0) { $0 + $1.salePrice }
    }

    private var monthlyProfit: Decimal {
        monthlyItems.reduce(0) { $0 + $1.profit }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                if items.isEmpty {
                    EmptyStateCard(
                        title: "まだ販売記録がありません",
                        message: "最初の販売記録を追加すると、売上と利益をここで確認できます。",
                        systemImage: "tray"
                    ) {
                        NavigationLink {
                            SoldItemFormView()
                        } label: {
                            Label("最初の記録を追加", systemImage: "plus")
                        }
                    }

                    QuickActionsSection()
                } else {
                    LazyVGrid(
                        columns: [
                            GridItem(.flexible(), spacing: 12),
                            GridItem(.flexible(), spacing: 12)
                        ],
                        spacing: 12
                    ) {
                        StatCard(
                            title: "今月の販売額",
                            value: currencyFormatter.string(from: monthlySales),
                            systemImage: "yensign.circle.fill",
                            tint: AppTheme.Colors.sales,
                            valueTint: AppTheme.Colors.sales
                        )
                        StatCard(
                            title: "今月の利益",
                            value: currencyFormatter.string(from: monthlyProfit),
                            systemImage: "chart.line.uptrend.xyaxis.circle.fill",
                            tint: AppTheme.profitColor(for: monthlyProfit),
                            valueTint: AppTheme.profitColor(for: monthlyProfit)
                        )
                        StatCard(
                            title: "販売済み件数",
                            value: "\(monthlyItems.count)",
                            systemImage: "shippingbox.circle.fill",
                            tint: AppTheme.Colors.warning
                        )
                        StatCard(
                            title: "平均利益",
                            value: averageProfitText,
                            systemImage: "chart.line.uptrend.xyaxis",
                            tint: AppTheme.Colors.secondary,
                            valueTint: AppTheme.profitColor(for: monthlyProfit)
                        )
                    }

                    QuickActionsSection()

                    SectionCard(title: "最近販売した商品") {
                        ForEach(recentItems) { item in
                            NavigationLink {
                                SoldItemDetailView(item: item)
                            } label: {
                                RecentSoldItemRow(item: item, currencyFormatter: currencyFormatter)
                            }
                            .buttonStyle(.plain)

                            if item.id != recentItems.last?.id {
                                Divider()
                            }
                        }
                    }
                }
            }
            .padding()
        }
        .background(AppTheme.Colors.pageBackground)
        .navigationTitle("ホーム")
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

    private var averageProfitText: String {
        guard monthlyItems.isEmpty == false else {
            return "-"
        }

        return currencyFormatter.string(from: monthlyProfit / Decimal(monthlyItems.count))
    }
}

private struct QuickActionsSection: View {
    var body: some View {
        SectionCard(title: "クイックアクション") {
            NavigationLink {
                ShippingCalculatorView()
            } label: {
                QuickActionRow(
                    title: "送料計算",
                    systemImage: "shippingbox",
                    tint: AppTheme.Colors.accent
                )
            }
            .buttonStyle(QuickActionButtonStyle())
        }
    }
}

private struct QuickActionRow: View {
    let title: String
    let systemImage: String
    var tint: Color = AppTheme.Colors.primary

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(tint.opacity(0.14))

                Image(systemName: systemImage)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(tint)
            }
            .frame(width: AppTheme.Metrics.iconBoxSize, height: AppTheme.Metrics.iconBoxSize)

            Text(title)
                .font(.subheadline.bold())
                .foregroundStyle(.primary)

            Spacer(minLength: 12)

            Image(systemName: "chevron.right")
                .font(.caption.bold())
                .foregroundStyle(tint.opacity(0.7))
        }
        .padding(AppTheme.Metrics.cardPadding)
        .contentShape(Rectangle())
    }
}

private struct RecentSoldItemRow: View {
    let item: SoldItem
    let currencyFormatter: AppCurrencyFormatter

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text(item.title)
                    .font(.subheadline.bold())
                    .lineLimit(1)

                Text("\(item.category.displayName) · \(AppDateFormatter.dateString(from: item.soldAt))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 12)

            VStack(alignment: .trailing, spacing: 6) {
                Text(currencyFormatter.string(from: item.salePrice))
                    .font(.subheadline.bold())
                    .foregroundStyle(AppTheme.Colors.sales)

                ProfitText(value: item.profit, formatter: currencyFormatter, font: .caption)
            }
        }
        .padding()
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [SoldItem.self, SupplyItem.self], inMemory: true)
}
