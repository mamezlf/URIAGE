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
    case threeMonths = "3ヶ月"
    case sixMonths = "半年"
    
    var id: String { self.rawValue }
    
    var calendarMonthsToSubtract: Int {
        switch self {
        case .thisMonth: return 0
        case .threeMonths: return -2
        case .sixMonths: return -5
        }
    }
}

enum SupplyRoute: Hashable {
    case add
    case edit(UUID)
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

    private var filteredTotalCost: Decimal {
        filteredSupplies.reduce(0) { $0 + $1.totalCost }
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
                        NavigationLink(value: SupplyRoute.add) {
                            Label("最初の資材を追加", systemImage: "plus")
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
                    SupplyFilterBar(
                        resultCount: filteredSupplies.count,
                        totalCostText: currencyFormatter.string(from: filteredTotalCost),
                        selectedPeriod: $selectedPeriod
                    )
                }
                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))

                if filteredSupplies.isEmpty {
                    Section {
                        EmptyStateCard(
                            title: "\(selectedPeriod.rawValue)の資材はありません",
                            message: "表示期間を変更するか、新しい資材を追加してください。",
                            systemImage: "magnifyingglass"
                        ) {
                            NavigationLink(value: SupplyRoute.add) {
                                Label("資材を追加", systemImage: "plus")
                            }
                        }
                    }
                    .listRowBackground(Color.clear)
                } else {
                    Section {
                        ForEach(filteredSupplies) { item in
                            NavigationLink(value: SupplyRoute.edit(item.id)) {
                                SupplyItemRow(item: item, currencyFormatter: currencyFormatter)
                            }
                        }
                        .onDelete(perform: deleteFiltered)
                    }
                }
            }
        }
        .safeAreaPadding(.top, 16)
        .navigationTitle("資材")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink(value: SupplyRoute.add) {
                    Label("追加", systemImage: "plus")
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
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline, spacing: 12) {
                Text(item.name)
                    .font(.headline)
                    .lineLimit(1)

                Spacer(minLength: 12)

                AmountText(
                    value: item.totalCost,
                    formatter: currencyFormatter,
                    role: .cost,
                    font: .subheadline,
                    fontWeight: .bold
                )
            }

            HStack(alignment: .firstTextBaseline, spacing: 12) {
                Text("\(AppDateFormatter.dateString(from: item.purchaseDate)) · \(item.displayType)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)

                Spacer(minLength: 12)

                Text("\(currencyFormatter.string(from: item.unitCost)) × \(item.quantity)個")
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
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
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 8) {
                Text("今月の資材費用")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                AmountText(
                    value: currentMonthCost,
                    formatter: currencyFormatter,
                    role: .cost,
                    font: .largeTitle,
                    fontWeight: .bold
                )
                .minimumScaleFactor(0.7)
            }

            HStack(spacing: 8) {
                SummaryMetric(title: "先月", value: currencyFormatter.string(from: lastMonthCost))
                SummaryMetric(title: "今月登録", value: "\(currentMonthCount)件")
            }
        }
        .padding(.vertical, 6)
    }
}

private struct SupplyFilterBar: View {
    let resultCount: Int
    let totalCostText: String
    @Binding var selectedPeriod: SupplyFilterPeriod

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .center, spacing: 10) {
                Label("\(resultCount)件", systemImage: "line.3.horizontal.decrease.circle")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)

                Spacer(minLength: 8)

                Text("合計 \(totalCostText)")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
            }

            Picker("表示期間", selection: $selectedPeriod) {
                ForEach(SupplyFilterPeriod.allCases) { period in
                    Text(period.rawValue).tag(period)
                }
            }
            .pickerStyle(.segmented)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    NavigationStack {
        SuppliesView()
    }
    .modelContainer(for: SupplyItem.self, inMemory: true)
}
