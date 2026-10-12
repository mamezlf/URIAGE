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
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Query(sort: \SoldItem.soldAt, order: .reverse) private var items: [SoldItem]

    @State private var searchText = ""
    @State private var monthFilter: MonthFilter = .all
    @State private var customMonth = Date()
    @State private var sortField: SortField = .soldDate
    @State private var sortOrder: SortOrder = .descending
    /// タブを初めて開いたときだけ false。一覧の構築を 1 フレーム後ろにずらし、タブ切り替えを先に完了させる
    @State private var isContentReady = false
    @AppStorage(AppSettingsKey.currencyCode) private var currencyCode = AppDefaults.currencyCode

    private var currencyFormatter: AppCurrencyFormatter {
        AppCurrencyFormatter(currencyCode: currencyCode)
    }

    private let calendar = Calendar.current

    private var filteredAndSortedItems: [SoldItem] {
        sortItems(
            filterByMonth(
                filterBySearch(items)
            )
        )
    }

    var body: some View {
        // 検索・絞り込み・並び替えは 1 回の描画で 1 回だけ計算する（初回表示の準備中は計算しない）
        let visibleItems = isContentReady ? filteredAndSortedItems : []

        ListViewTemplate(
            title: "販売記録",
            isEmpty: visibleItems.isEmpty,
            isLoading: isContentReady == false,
            filterBar: {
                FilterBar(
                    resultCount: visibleItems.count,
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
                ForEach(visibleItems) { item in
                    NavigationLink {
                        SoldItemDetailView(item: item)
                    } label: {
                        SoldItemListRow(
                            item: item,
                            currencyFormatter: currencyFormatter
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
        .task {
            // 2 回目以降のタブ切り替えでは何もしない（一覧はそのまま残っている）
            guard isContentReady == false else { return }
            // スケルトンを 1 フレーム描いてタブを切り替えてから、一覧を作る
            try? await Task.sleep(for: .milliseconds(16))
            withAnimation(.easeOut(duration: 0.2)) {
                isContentReady = true
            }
        }
        // 絞り込み（すべて / 今月 / 先月 / 指定）・並び替えの切り替えで行が動くようにする
        .animation(listAnimation, value: monthFilter)
        .animation(listAnimation, value: customMonth)
        .animation(listAnimation, value: sortField)
        .animation(listAnimation, value: sortOrder)
    }

    private var listAnimation: Animation? {
        reduceMotion ? nil : .snappy(duration: 0.35)
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
