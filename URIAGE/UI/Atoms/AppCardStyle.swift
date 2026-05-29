import SwiftUI

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
