//
//  SuppliesView.swift
//  URIAGE
//
//  Created by Codex on 2026/04/26.
//

import SwiftUI
import SwiftData

struct SuppliesView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \SupplyItem.purchaseDate, order: .reverse) private var supplies: [SupplyItem]

    @State private var itemsPendingDeletion: [SupplyItem] = []
    @State private var isShowingDeleteConfirmation = false
    @AppStorage(AppSettingsKey.currencyCode) private var currencyCode = AppDefaults.currencyCode

    private var currencyFormatter: AppCurrencyFormatter {
        AppCurrencyFormatter(currencyCode: currencyCode)
    }

    private var totalSupplyCost: Decimal {
        supplies.reduce(0) { $0 + $1.totalCost }
    }

    private var currentMonthSupplyCost: Decimal {
        supplies
            .filter { Calendar.current.isDate($0.purchaseDate, equalTo: Date(), toGranularity: .month) }
            .reduce(0) { $0 + $1.totalCost }
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
                        totalCost: totalSupplyCost,
                        currentMonthCost: currentMonthSupplyCost,
                        itemCount: supplies.count,
                        currencyFormatter: currencyFormatter
                    )
                }

                Section("購入した資材") {
                    ForEach(supplies) { item in
                        NavigationLink {
                            SupplyItemFormView(item: item)
                        } label: {
                            SupplyItemRow(item: item, currencyFormatter: currencyFormatter)
                        }
                    }
                    .onDelete(perform: delete)
                }
            }
        }
        .navigationTitle("資材")
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

    private func delete(at offsets: IndexSet) {
        itemsPendingDeletion = offsets.map { supplies[$0] }
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

                Text(currencyFormatter.string(from: item.unitCost))
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

                Text("合計 \(currencyFormatter.string(from: item.totalCost)) / \(item.quantity)個")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 6)
    }
}

private struct SupplyCostSummaryRow: View {
    let totalCost: Decimal
    let currentMonthCost: Decimal
    let itemCount: Int
    let currencyFormatter: AppCurrencyFormatter

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .firstTextBaseline) {
                Text("資材にかかったお金")
                    .font(.headline)

                Spacer(minLength: 12)

                Text(currencyFormatter.string(from: totalCost))
                    .font(.title3.bold())
                    .foregroundStyle(AppTheme.Colors.cost)
            }

            HStack(spacing: 12) {
                summaryPill("今月", currencyFormatter.string(from: currentMonthCost), systemImage: "calendar")
                summaryPill("登録", "\(itemCount)件", systemImage: "shippingbox")
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
