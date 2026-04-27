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

struct AppCardStyle: ViewModifier {
    var background: Color = AppTheme.Colors.cardBackground
    var cornerRadius: CGFloat = AppTheme.Metrics.cardCornerRadius
    var padding: CGFloat = AppTheme.Metrics.cardPadding
    var shadow: Bool = true

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(background)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .shadow(
                color: shadow ? AppTheme.Shadows.cardColor : .clear,
                radius: AppTheme.Shadows.cardRadius,
                x: AppTheme.Shadows.cardX,
                y: AppTheme.Shadows.cardY
            )
    }
}

extension View {
    func appCard(
        background: Color = AppTheme.Colors.cardBackground,
        cornerRadius: CGFloat = AppTheme.Metrics.cardCornerRadius,
        padding: CGFloat = AppTheme.Metrics.cardPadding,
        shadow: Bool = true
    ) -> some View {
        modifier(
            AppCardStyle(
                background: background,
                cornerRadius: cornerRadius,
                padding: padding,
                shadow: shadow
            )
        )
    }
}

struct PrimaryActionButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .frame(minHeight: 42)
            .background(AppTheme.Colors.primary.opacity(configuration.isPressed ? 0.82 : 1))
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.Metrics.controlCornerRadius, style: .continuous))
    }
}

struct QuickActionButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}
