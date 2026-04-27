//
//  SharedUI.swift
//  URIAGE
//
//  Created by Codex on 2026/04/26.
//

import SwiftUI

struct StatCard: View {
    let title: String
    let value: String
    let systemImage: String
    var tint: Color = AppTheme.Colors.primary
    var valueTint: Color = .primary

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(tint.opacity(0.14))

                Image(systemName: systemImage)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(tint)
            }
            .frame(width: AppTheme.Metrics.iconBoxSize, height: AppTheme.Metrics.iconBoxSize)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)

                Text(value)
                    .font(.title3.bold())
                    .foregroundStyle(valueTint)
                    .minimumScaleFactor(0.8)
                    .lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 112, alignment: .leading)
        .appCard(background: AppTheme.Colors.cardBackground)
    }
}

struct SectionCard<Content: View>: View {
    let title: String
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Metrics.cardSpacing) {
            Text(title)
                .font(.headline)

            VStack(spacing: 0) {
                content
            }
            .background(AppTheme.Colors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.Metrics.cardCornerRadius, style: .continuous))
            .shadow(
                color: AppTheme.Shadows.cardColor,
                radius: AppTheme.Shadows.cardRadius,
                x: AppTheme.Shadows.cardX,
                y: AppTheme.Shadows.cardY
            )
        }
    }
}

struct EmptyStateCard<Action: View>: View {
    let title: String
    let message: String
    let systemImage: String
    @ViewBuilder var action: Action

    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: systemImage)
                .font(.system(size: 34, weight: .semibold))
                .foregroundStyle(.secondary)

            VStack(spacing: 6) {
                Text(title)
                    .font(.headline)
                    .multilineTextAlignment(.center)

                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }

            action
                .buttonStyle(PrimaryActionButtonStyle())
                .padding(.top, 2)
        }
        .frame(maxWidth: .infinity)
        .appCard(background: AppTheme.Colors.cardBackground, padding: 24)
    }
}

extension EmptyStateCard where Action == EmptyView {
    init(title: String, message: String, systemImage: String) {
        self.title = title
        self.message = message
        self.systemImage = systemImage
        self.action = EmptyView()
    }
}

struct ProfitText: View {
    let value: Decimal
    let formatter: AppCurrencyFormatter
    var font: Font = .body
    var showPrefix = false

    var body: some View {
        Text(displayText)
            .font(font)
            .foregroundStyle(AppTheme.amountColor(for: .profit, value: value))
    }

    private var displayText: String {
        let amount = formatter.string(from: value)
        return showPrefix ? "利益 \(amount)" : amount
    }
}

struct AmountText: View {
    let value: Decimal
    let formatter: AppCurrencyFormatter
    var role: AmountRole = .plain
    var font: Font = .body
    var fontWeight: Font.Weight = .regular

    var body: some View {
        Text(formatter.string(from: value))
            .font(font)
            .fontWeight(fontWeight)
            .foregroundStyle(AppTheme.amountColor(for: role, value: value))
            .lineLimit(1)
    }
}
