import SwiftUI

enum MonthFilter: String, CaseIterable, Identifiable {
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

enum SortField: String, CaseIterable, Identifiable {
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

enum SortOrder: String, CaseIterable, Identifiable {
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

struct FilterBar: View {
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
