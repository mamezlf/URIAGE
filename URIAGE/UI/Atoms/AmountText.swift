import SwiftUI

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
