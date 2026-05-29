import SwiftUI

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
