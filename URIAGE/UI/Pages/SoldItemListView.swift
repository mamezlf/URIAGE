//
//  SoldItemListView.swift
//  URIAGE
//
//  Created by Codex on 2026/04/26.
//

import SwiftUI
import SwiftData

struct SoldItemListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \SoldItem.soldAt, order: .reverse) private var items: [SoldItem]

    @State private var searchText = ""
    @State private var monthFilter: MonthFilter = .all
    @State private var customMonth = Date()
    @State private var sortField: SortField = .soldDate
    @State private var sortOrder: SortOrder = .descending
    @AppStorage(AppSettingsKey.currencyCode) private var currencyCode = AppDefaults.currencyCode

    private var currencyFormatter: AppCurrencyFormatter {
        AppCurrencyFormatter(currencyCode: currencyCode)
    }

    private let percentFormatter = AppPercentFormatter()
    private let calendar = Calendar.current

    private var filteredAndSortedItems: [SoldItem] {
        sortItems(
            filterByMonth(
                filterBySearch(items)
            )
        )
    }

    var body: some View {
        ListViewTemplate(
            title: "販売記録",
            isEmpty: filteredAndSortedItems.isEmpty,
            filterBar: {
                FilterBar(
                    resultCount: filteredAndSortedItems.count,
                    monthFilter: $monthFilter,
                    customMonth: $customMonth,
                    sortField: $sortField,
                    sortOrder: $sortOrder
                )
            },
            emptyState: {
                if items.isEmpty {
                    EmptyStateCard(
                        title: "販売記録がありません",
                        message: "最初の販売記録を追加して、売上と利益を管理しましょう。",
                        systemImage: "tray"
                    ) {
                        NavigationLink {
                            SoldItemFormView()
                        } label: {
                            Label("最初の記録を追加", systemImage: "plus")
                        }
                    }

                } else {
                    EmptyStateCard(
                        title: "条件に一致する記録がありません",
                        message: "検索条件、絞り込み、並び替えを変更してください。",
                        systemImage: "magnifyingglass"
                    ) {
                        Button {
                            resetFilters()
                        } label: {
                            Label("絞り込みをリセット", systemImage: "arrow.counterclockwise")
                        }
                    }
                }
            },
            content: {
                ForEach(filteredAndSortedItems) { item in
                    NavigationLink {
                        SoldItemDetailView(item: item)
                    } label: {
                        SoldItemListRow(
                            item: item,
                            currencyFormatter: currencyFormatter,
                            percentFormatter: percentFormatter
                        )
                    }
                }
                .onDelete(perform: delete)
            },
            trailingToolbar: {
                AnyView(
                    NavigationLink {
                        SoldItemFormView()
                    } label: {
                        Label("追加", systemImage: "plus")
                    }
                )
            }
        )
        .searchable(text: $searchText, prompt: "商品名を検索")
    }

    private func filterBySearch(_ source: [SoldItem]) -> [SoldItem] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard query.isEmpty == false else {
            return source
        }

        return source.filter { $0.title.localizedCaseInsensitiveContains(query) }
    }

    private func filterByMonth(_ source: [SoldItem]) -> [SoldItem] {
        guard let targetMonth = monthFilter.targetMonth(from: customMonth, calendar: calendar) else {
            return source
        }

        return source.filter { calendar.isDate($0.soldAt, equalTo: targetMonth, toGranularity: .month) }
    }

    private func sortItems(_ source: [SoldItem]) -> [SoldItem] {
        source.sorted { lhs, rhs in
            switch sortField {
            case .soldDate:
                return sortOrder == .ascending ? lhs.soldAt < rhs.soldAt : lhs.soldAt > rhs.soldAt
            case .profit:
                return compare(lhs.profit, rhs.profit)
            case .salePrice:
                return compare(lhs.salePrice, rhs.salePrice)
            case .profitRate:
                return compare(lhs.profitRate ?? 0, rhs.profitRate ?? 0)
            }
        }
    }

    private func compare(_ lhs: Decimal, _ rhs: Decimal) -> Bool {
        sortOrder == .ascending ? lhs < rhs : lhs > rhs
    }

    private func delete(at offsets: IndexSet) {
        let currentItems = filteredAndSortedItems
        offsets
            .map { currentItems[$0] }
            .forEach { modelContext.delete($0) }
    }

    private func resetFilters() {
        searchText = ""
        monthFilter = .all
        customMonth = Date()
        sortField = .soldDate
        sortOrder = .descending
    }

}

#Preview {
    NavigationStack {
        SoldItemListView()
    }
    .modelContainer(for: SoldItem.self, inMemory: true)
}
