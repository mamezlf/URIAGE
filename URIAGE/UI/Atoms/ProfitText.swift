import SwiftUI

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
