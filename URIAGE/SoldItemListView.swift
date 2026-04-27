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
    @State private var categoryFilter = CategoryFilterTitle.all
    @State private var profitFilter: ProfitFilter = .all
    @State private var sortField: SortField = .soldDate
    @State private var sortOrder: SortOrder = .descending
    @State private var itemsPendingDeletion: [SoldItem] = []
    @State private var isShowingDeleteConfirmation = false
    @AppStorage(AppSettingsKey.currencyCode) private var currencyCode = AppDefaults.currencyCode

    private var currencyFormatter: AppCurrencyFormatter {
        AppCurrencyFormatter(currencyCode: currencyCode)
    }

    private let percentFormatter = AppPercentFormatter()
    private let calendar = Calendar.current

    private var filteredAndSortedItems: [SoldItem] {
        sortItems(
            filterByProfit(
                filterByCategory(
                    filterByMonth(
                        filterBySearch(items)
                    )
                )
            )
        )
    }

    private var categoryOptions: [String] {
        let categories = Set(items.map(\.categoryName)).sorted()
        return [CategoryFilterTitle.all] + categories
    }

    var body: some View {
        List {
            Section {
                Picker("月", selection: $monthFilter) {
                    ForEach(MonthFilter.allCases) { filter in
                        Text(filter.title).tag(filter)
                    }
                }

                if monthFilter == .custom {
                    DatePicker("対象月", selection: $customMonth, displayedComponents: .date)
                }

                Picker("カテゴリ", selection: $categoryFilter) {
                    ForEach(categoryOptions, id: \.self) { category in
                        Text(Category.displayName(for: category)).tag(category)
                    }
                }

                Picker("利益", selection: $profitFilter) {
                    ForEach(ProfitFilter.allCases) { filter in
                        Text(filter.title).tag(filter)
                    }
                }

                Picker("並び替え", selection: $sortField) {
                    ForEach(SortField.allCases) { field in
                        Text(field.title).tag(field)
                    }
                }

                Picker("順序", selection: $sortOrder) {
                    ForEach(SortOrder.allCases) { order in
                        Text(order.title).tag(order)
                    }
                }
            }

            if filteredAndSortedItems.isEmpty {
                Section {
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
                }
                .listRowBackground(Color.clear)
            } else {
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
            }
        }
        .navigationTitle("販売記録")
        .searchable(text: $searchText, prompt: "商品名を検索")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink {
                    SoldItemFormView()
                } label: {
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

    private func filterByCategory(_ source: [SoldItem]) -> [SoldItem] {
        guard categoryFilter != CategoryFilterTitle.all else {
            return source
        }

        return source.filter { $0.categoryName == categoryFilter }
    }

    private func filterByProfit(_ source: [SoldItem]) -> [SoldItem] {
        switch profitFilter {
        case .all:
            return source
        case .profitable:
            return source.filter { $0.profit >= 0 }
        case .loss:
            return source.filter { $0.profit < 0 }
        }
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
        itemsPendingDeletion = offsets.map { currentItems[$0] }
        isShowingDeleteConfirmation = true
    }

    private func confirmDelete() {
        itemsPendingDeletion.forEach { modelContext.delete($0) }
        itemsPendingDeletion = []
    }

    private func resetFilters() {
        searchText = ""
        monthFilter = .all
        customMonth = Date()
        categoryFilter = CategoryFilterTitle.all
        profitFilter = .all
        sortField = .soldDate
        sortOrder = .descending
    }

    private var deleteConfirmationTitle: String {
        itemsPendingDeletion.count > 1 ? "選択した販売記録を削除しますか？" : "この販売記録を削除しますか？"
    }
}

private enum MonthFilter: String, CaseIterable, Identifiable {
    case all
    case current
    case previous
    case custom

    var id: String { rawValue }

    var title: String {
        switch self {
        case .all:
            return "すべての月"
        case .current:
            return "今月"
        case .previous:
            return "先月"
        case .custom:
            return "月を指定"
        }
    }

    func targetMonth(from customMonth: Date, calendar: Calendar) -> Date? {
        switch self {
        case .all:
            return nil
        case .current:
            return Date()
        case .previous:
            return calendar.date(byAdding: .month, value: -1, to: Date())
        case .custom:
            return customMonth
        }
    }
}

private enum ProfitFilter: String, CaseIterable, Identifiable {
    case all
    case profitable
    case loss

    var id: String { rawValue }

    var title: String {
        switch self {
        case .all:
            return "すべて"
        case .profitable:
            return "利益ありのみ"
        case .loss:
            return "赤字のみ"
        }
    }
}

private enum SortField: String, CaseIterable, Identifiable {
    case soldDate
    case profit
    case salePrice
    case profitRate

    var id: String { rawValue }

    var title: String {
        switch self {
        case .soldDate:
            return "販売日"
        case .profit:
            return "利益"
        case .salePrice:
            return "販売価格"
        case .profitRate:
            return "利益率"
        }
    }
}

private enum SortOrder: String, CaseIterable, Identifiable {
    case ascending
    case descending

    var id: String { rawValue }

    var title: String {
        switch self {
        case .ascending:
            return "昇順"
        case .descending:
            return "降順"
        }
    }
}

private enum CategoryFilterTitle {
    static let all = "すべてのカテゴリ"
}

private struct SoldItemListRow: View {
    let item: SoldItem
    let currencyFormatter: AppCurrencyFormatter
    let percentFormatter: AppPercentFormatter

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline, spacing: 12) {
                Text(item.title)
                    .font(.headline)
                    .lineLimit(1)

                Spacer(minLength: 12)

                AmountText(
                    value: item.salePrice,
                    formatter: currencyFormatter,
                    role: .sales,
                    font: .subheadline,
                    fontWeight: .bold
                )
            }

            HStack(alignment: .firstTextBaseline, spacing: 12) {
                Text(AppDateFormatter.dateString(from: item.soldAt))
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Spacer(minLength: 12)

                VStack(alignment: .trailing, spacing: 4) {
                    ProfitText(
                        value: item.profit,
                        formatter: currencyFormatter,
                        font: .caption.bold(),
                        showPrefix: true
                    )

                    Text("利益率 \(percentFormatter.string(from: item.profitRate))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 6)
    }
}

#Preview {
    NavigationStack {
        SoldItemListView()
    }
    .modelContainer(for: SoldItem.self, inMemory: true)
}
