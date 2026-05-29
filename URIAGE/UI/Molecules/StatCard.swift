import SwiftUI

struct StatCard: View {
    let title: String
    let value: String
    var footnote: String? = nil
    let systemImage: String
    var tint: Color = AppTheme.Colors.primary
    var valueTint: Color = .primary

    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            HStack(alignment: .center, spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(tint.opacity(0.14))

                    Image(systemName: systemImage)
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(tint)
                }
                .frame(width: 40, height: 40)

            }

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .minimumScaleFactor(0.82)
                
                Text(value)
                    .font(.headline.bold())
                    .foregroundStyle(valueTint)
                    .minimumScaleFactor(0.72)
                    .lineLimit(1)

                if let footnote {
                    Text(footnote)
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                }
            }
        }
        .frame(maxWidth: .infinity, minHeight: 64, alignment: .leading)
        .appCard(background: AppTheme.Colors.elevatedCardBackground, padding: 12)
        .overlay(alignment: .top) {
            Rectangle()
                .fill(tint.opacity(0.55))
                .frame(height: 2)
                .clipShape(RoundedRectangle(cornerRadius: 1, style: .continuous))
                .padding(.horizontal, 12)
        }
    }
}
