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
        List {
            Section {
                FilterBar(
                    resultCount: filteredAndSortedItems.count,
                    monthFilter: $monthFilter,
                    customMonth: $customMonth,
                    sortField: $sortField,
                    sortOrder: $sortOrder
                )
            }
            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))

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
        .safeAreaPadding(.top, 16)
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

    var shortTitle: String {
        switch self {
        case .all:
            return "すべて"
        case .current:
            return "今月"
        case .previous:
            return "先月"
        case .custom:
            return "指定"
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

    var systemImage: String {
        switch self {
        case .ascending:
            return "arrow.up"
        case .descending:
            return "arrow.down"
        }
    }

    var toggled: SortOrder {
        switch self {
        case .ascending:
            return .descending
        case .descending:
            return .ascending
        }
    }
}

private struct FilterBar: View {
    let resultCount: Int
    @Binding var monthFilter: MonthFilter
    @Binding var customMonth: Date
    @Binding var sortField: SortField
    @Binding var sortOrder: SortOrder

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .center, spacing: 10) {
                Label("\(resultCount)件", systemImage: "line.3.horizontal.decrease.circle")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)

                Spacer(minLength: 8)

                Text(activeFilterSummary)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
            }

            Picker("月", selection: $monthFilter) {
                ForEach(MonthFilter.allCases) { filter in
                    Text(filter.shortTitle).tag(filter)
                }
            }
            .pickerStyle(.segmented)

            if monthFilter == .custom {
                HStack(spacing: 10) {
                    Label("対象月", systemImage: "calendar")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)

                    Spacer(minLength: 8)

                    DatePicker("対象月", selection: $customMonth, displayedComponents: .date)
                        .labelsHidden()
                        .datePickerStyle(.compact)
                }
                .padding(10)
                .background(AppTheme.Colors.pageBackground)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }

            HStack(spacing: 10) {
                Label("並び替え", systemImage: "arrow.up.arrow.down")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)

                Spacer(minLength: 8)

                Menu {
                    Picker("並び替え", selection: $sortField) {
                        ForEach(SortField.allCases) { field in
                            Text(field.title).tag(field)
                        }
                    }
                } label: {
                    Text(sortField.title)
                        .font(.subheadline.weight(.semibold))
                        .lineLimit(1)
                }

                Button {
                    sortOrder = sortOrder.toggled
                } label: {
                    Label(sortOrder.title, systemImage: sortOrder.systemImage)
                        .font(.subheadline.weight(.semibold))
                        .lineLimit(1)
                        .labelStyle(.titleAndIcon)
                }
                .buttonStyle(.bordered)
                .tint(AppTheme.Colors.secondary)
                .accessibilityLabel(sortOrder.title)
            }
            .padding(10)
            .background(AppTheme.Colors.pageBackground)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
        .padding(.vertical, 4)
    }

    private var activeFilterSummary: String {
        switch monthFilter {
        case .all:
            return "すべて表示"
        case .current, .previous:
            return monthFilter.title
        case .custom:
            return AppDateFormatter.monthString(from: customMonth)
        }
    }
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
