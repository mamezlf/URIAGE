import SwiftUI

struct ScrollableContainer<Content: View>: View {
    var spacing: CGFloat = AppTheme.Metrics.sectionSpacing
    var padding: CGFloat = AppTheme.Metrics.screenPadding
    var backgroundColor: Color = AppTheme.Colors.pageBackground
    @ViewBuilder var content: Content

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: spacing) {
                content
            }
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(backgroundColor)
    }
}
