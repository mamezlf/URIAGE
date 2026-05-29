import SwiftUI

struct DimensionField: View {
    let title: String
    let unit: String
    @Binding var text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            HStack(alignment: .firstTextBaseline, spacing: 6) {
                TextField("0", text: $text)
                    .keyboardType(.decimalPad)
                    .font(.title3.weight(.semibold))
                    .lineLimit(1)

                Text(unit)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 12)
            .frame(height: 48)
            .background(AppTheme.Colors.pageBackground)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
