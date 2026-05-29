//
//  AppTheme.swift
//  URIAGE
//
//  Created by Codex on 2026/04/26.
//

import SwiftUI

enum AppTheme {
    enum Colors {
        static let primary = Color(red: 0.16, green: 0.43, blue: 0.86)
        static let secondary = Color(red: 0.43, green: 0.36, blue: 0.86)
        static let accent = Color(red: 0.05, green: 0.62, blue: 0.72)
        static let success = Color(red: 0.07, green: 0.58, blue: 0.32)
        static let loss = Color(red: 0.86, green: 0.19, blue: 0.22)
        static let warning = Color(red: 0.91, green: 0.48, blue: 0.11)
        static let sales = primary
        static let cost = warning
        static let pageBackground = Color(.systemGroupedBackground)
        static let cardBackground = Color(.secondarySystemGroupedBackground)
        static let elevatedCardBackground = Color(.systemBackground)
        static let separator = Color(.separator).opacity(0.45)
    }

    enum Metrics {
        static let screenPadding: CGFloat = 16
        static let sectionSpacing: CGFloat = 24
        static let cardSpacing: CGFloat = 12
        static let cardPadding: CGFloat = 16
        static let cardCornerRadius: CGFloat = 16
        static let controlCornerRadius: CGFloat = 12
        static let iconBoxSize: CGFloat = 36
    }

    enum Shadows {
        static let cardColor = Color.black.opacity(0.08)
        static let cardRadius: CGFloat = 12
        static let cardX: CGFloat = 0
        static let cardY: CGFloat = 4
    }

    static func profitColor(for value: Decimal) -> Color {
        value >= 0 ? Colors.success : Colors.loss
    }

    static func amountColor(for role: AmountRole, value: Decimal? = nil) -> Color {
        switch role {
        case .profit:
            return profitColor(for: value ?? 0)
        case .sales:
            return Colors.sales
        case .cost:
            return Colors.cost
        case .plain:
            return .primary
        }
    }
}

enum AmountRole {
    case profit
    case sales
    case cost
    case plain
}
