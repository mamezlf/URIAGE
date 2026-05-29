import SwiftUI

struct ReportItemRow: View {
    let item: SoldItem
    let currencyFormatter: AppCurrencyFormatter

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline, spacing: 12) {
                Text(item.title)
                    .font(.subheadline.bold())
                    .lineLimit(1)

                Spacer(minLength: 12)

                ProfitText(value: item.profit, formatter: currencyFormatter, font: .subheadline.bold())
            }

            Text(AppDateFormatter.dateString(from: item.soldAt))
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}
