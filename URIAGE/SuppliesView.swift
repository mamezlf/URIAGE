//
//  SuppliesView.swift
//  URIAGE
//
//  Created by Codex on 2026/04/26.
//

import SwiftUI
import SwiftData

enum SupplyFilterPeriod: String, CaseIterable, Identifiable {
    case thisMonth = "今月"
    case threeMonths = "過去3ヶ月"
    case sixMonths = "過去半年"
    
    var id: String { self.rawValue }
    
    var calendarMonthsToSubtract: Int {
        switch self {
        case .thisMonth: return 0
        case .threeMonths: return -2
        case .sixMonths: return -5
        }
    }
}

struct SuppliesView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \SupplyItem.purchaseDate, order: .reverse) private var supplies: [SupplyItem]

    @State private var itemsPendingDeletion: [SupplyItem] = []
    @State private var isShowingDeleteConfirmation = false
    @State private var selectedPeriod: SupplyFilterPeriod = .thisMonth
    @AppStorage(AppSettingsKey.currencyCode) private var currencyCode = AppDefaults.currencyCode

    private var currencyFormatter: AppCurrencyFormatter {
        AppCurrencyFormatter(currencyCode: currencyCode)
    }

    private var currentMonthSupplyCost: Decimal {
        SupplyCostCalculator.monthlyRegisteredSupplyCost(supplies: supplies, in: Date())
    }

    private var lastMonthSupplyCost: Decimal {
        guard let lastMonth = Calendar.current.date(byAdding: .month, value: -1, to: Date()) else {
            return 0
        }
        return SupplyCostCalculator.monthlyRegisteredSupplyCost(supplies: supplies, in: lastMonth)
    }

    private var currentMonthSuppliesCount: Int {
        guard let interval = Calendar.current.dateInterval(of: .month, for: Date()) else {
            return 0
        }
        return supplies.filter { $0.purchaseDate >= interval.start && $0.purchaseDate < interval.end }.count
    }

    private var filteredSupplies: [SupplyItem] {
        let now = Date()
        guard let startOfThisMonth = Calendar.current.dateInterval(of: .month, for: now)?.start else {
            return supplies
        }
        
        guard let cutoffDate = Calendar.current.date(byAdding: .month, value: selectedPeriod.calendarMonthsToSubtract, to: startOfThisMonth) else {
            return supplies
        }
        
        return supplies.filter { $0.purchaseDate >= cutoffDate }
    }

    var body: some View {
        List {
            if supplies.isEmpty {
                Section {
                    EmptyStateCard(
                        title: "まだ資材がありません",
                        message: "梱包材や送料関連の資材を登録すると、商品ごとのコスト計算に使いやすくなります。",
                        systemImage: "archivebox"
                    ) {
                        NavigationLink {
                            SupplyItemFormView()
                        } label: {
                            Label("資材を追加", systemImage: "plus")
                        }
                    }
                }
                .listRowBackground(Color.clear)
            } else {
                Section {
                    SupplyCostSummaryRow(
                        currentMonthCost: currentMonthSupplyCost,
                        lastMonthCost: lastMonthSupplyCost,
                        currentMonthCount: currentMonthSuppliesCount,
                        currencyFormatter: currencyFormatter
                    )
                }

                Section {
                    if filteredSupplies.isEmpty {
                        Text("今月に購入した資材はありません")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(filteredSupplies) { item in
                            NavigationLink {
                                SupplyItemFormView(item: item)
                            } label: {
                                SupplyItemRow(item: item, currencyFormatter: currencyFormatter)
                            }
                        }
                        .onDelete(perform: deleteFiltered)
                    }
                } header: {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("最近購入した資材")

                        Picker("表示期間", selection: $selectedPeriod) {
                            ForEach(SupplyFilterPeriod.allCases) { period in
                                Text(period.rawValue).tag(period)
                            }
                        }
                        .pickerStyle(.segmented)
                        .textCase(nil)
                    }
                    .padding(.bottom, 4)
                }
            }
        }
        .safeAreaPadding(.top, 16)
        .navigationTitle("資材（梱包材など）")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink {
                    SupplyItemFormView()
                } label: {
                    Label("資材を追加", systemImage: "plus")
                }
            }
        }
        .confirmationDialog(
            deleteConfirmationTitle,
            isPresented: $isShowingDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("削除", role: .destructive, action: confirmDelete)
            Button("キャンセル", role: .cancel) {
                itemsPendingDeletion = []
            }
        } message: {
            Text("この操作は取り消せません。")
        }
    }

    private func deleteFiltered(at offsets: IndexSet) {
        itemsPendingDeletion = offsets.map { filteredSupplies[$0] }
        isShowingDeleteConfirmation = true
    }

    private func confirmDelete() {
        itemsPendingDeletion.forEach { modelContext.delete($0) }
        itemsPendingDeletion = []
    }

    private var deleteConfirmationTitle: String {
        itemsPendingDeletion.count > 1 ? "選択した資材を削除しますか？" : "この資材を削除しますか？"
    }
}

private struct SupplyItemRow: View {
    let item: SupplyItem
    let currencyFormatter: AppCurrencyFormatter

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline, spacing: 12) {
                Text(item.name)
                    .font(.headline)
                    .lineLimit(1)

                Spacer(minLength: 12)

                Text(currencyFormatter.string(from: item.totalCost))
                    .font(.subheadline.bold())
                    .foregroundStyle(AppTheme.Colors.cost)
                    .lineLimit(1)
            }

            HStack(alignment: .firstTextBaseline, spacing: 10) {
                Text(item.displayType)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text(AppDateFormatter.dateString(from: item.purchaseDate))
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Spacer(minLength: 10)

                Text("単価 \(currencyFormatter.string(from: item.unitCost)) × \(item.quantity)個")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 6)
    }
}

private struct SupplyCostSummaryRow: View {
    let currentMonthCost: Decimal
    let lastMonthCost: Decimal
    let currentMonthCount: Int
    let currencyFormatter: AppCurrencyFormatter

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .firstTextBaseline) {
                Text("今月資材にかかったお金")
                    .font(.headline)

                Spacer(minLength: 12)

                Text(currencyFormatter.string(from: currentMonthCost))
                    .font(.title3.bold())
                    .foregroundStyle(AppTheme.Colors.cost)
            }

            HStack(spacing: 12) {
                summaryPill("先月", currencyFormatter.string(from: lastMonthCost), systemImage: "calendar")
                summaryPill("今月登録", "\(currentMonthCount)件", systemImage: "shippingbox")
            }
        }
        .padding(.vertical, 6)
    }

    private func summaryPill(_ title: String, _ value: String, systemImage: String) -> some View {
        Label {
            Text("\(title) \(value)")
        } icon: {
            Image(systemName: systemImage)
        }
        .font(.caption.bold())
        .foregroundStyle(.secondary)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(AppTheme.Colors.cardBackground)
        .clipShape(Capsule())
    }
}

#Preview {
    NavigationStack {
        SuppliesView()
    }
    .modelContainer(for: SupplyItem.self, inMemory: true)
}
