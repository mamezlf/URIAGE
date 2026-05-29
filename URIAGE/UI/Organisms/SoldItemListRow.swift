import SwiftUI

struct SoldItemListRow: View {
    let item: SoldItem
    let currencyFormatter: AppCurrencyFormatter

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline, spacing: 12) {
                Text(item.title)
                    .font(.headline)
                    .lineLimit(1)

                Spacer(minLength: 12)

                AmountText(
                    value: item.salePrice,
                    formatter: currencyFormatter,
                    role: .sales,
                    font: .subheadline,
                    fontWeight: .bold
                )
            }

            HStack(alignment: .firstTextBaseline, spacing: 12) {
                Text(AppDateFormatter.dateString(from: item.soldAt))
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Spacer(minLength: 12)

                ProfitText(
                    value: item.profit,
                    formatter: currencyFormatter,
                    font: .caption.bold(),
                    showPrefix: true
                )
            }
        }
        .padding(.vertical, 6)
    }
}
