import SwiftUI

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
