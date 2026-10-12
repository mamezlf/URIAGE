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

    private let iconColumnWidth: CGFloat = 22
    private let controlHeight: CGFloat = 32

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            row(systemImage: "line.3.horizontal.decrease.circle", iconColor: .primary) {
                Text("\(resultCount)件")
                    .font(.headline)
                    .monospacedDigit()
                    .contentTransition(.numericText(value: Double(resultCount)))
                    .foregroundStyle(.primary)
            } trailing: {
                Text(activeFilterSummary)
                    .contentTransition(.interpolate)
                    .font(.subheadline)
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
                row(systemImage: "calendar") {
                    rowLabel("対象月")
                } trailing: {
                    DatePicker("対象月", selection: $customMonth, displayedComponents: .date)
                        .labelsHidden()
                        .datePickerStyle(.compact)
                }
                .frame(minHeight: controlHeight)
            }

            Divider()
                .overlay(AppTheme.Colors.separator)

            row(systemImage: "arrow.up.arrow.down") {
                rowLabel("並び替え")
            } trailing: {
                HStack(spacing: 8) {
                    Menu {
                        Picker("並び替え", selection: $sortField) {
                            ForEach(SortField.allCases) { field in
                                Text(field.title).tag(field)
                            }
                        }
                    } label: {
                        chip(title: sortField.title, systemImage: "chevron.up.chevron.down")
                    }

                    Button {
                        sortOrder = sortOrder.toggled
                    } label: {
                        chip(
                            title: sortOrder.title,
                            systemImage: "arrow.up",
                            iconRotation: sortOrder == .ascending ? .zero : .degrees(180)
                        )
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("並び順 \(sortOrder.title)")
                }
            }
        }
        .padding(.vertical, 4)
    }

    private func row<Leading: View, Trailing: View>(
        systemImage: String,
        iconColor: Color = .secondary,
        @ViewBuilder leading: () -> Leading,
        @ViewBuilder trailing: () -> Trailing
    ) -> some View {
        HStack(alignment: .center, spacing: 8) {
            Image(systemName: systemImage)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(iconColor)
                .frame(width: iconColumnWidth, alignment: .leading)

            leading()

            Spacer(minLength: 8)

            trailing()
        }
    }

    private func rowLabel(_ title: String) -> some View {
        Text(title)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.secondary)
    }

    private func chip(title: String, systemImage: String, iconRotation: Angle = .zero) -> some View {
        HStack(spacing: 4) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .lineLimit(1)
                .contentTransition(.interpolate)
            Image(systemName: systemImage)
                .font(.caption.weight(.bold))
                .rotationEffect(iconRotation)
        }
        .foregroundStyle(AppTheme.Colors.primary)
        .padding(.horizontal, 12)
        .frame(height: controlHeight)
        .background(
            AppTheme.Colors.primary.opacity(0.12),
            in: RoundedRectangle(cornerRadius: AppTheme.Metrics.controlCornerRadius, style: .continuous)
        )
        .contentShape(Rectangle())
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
