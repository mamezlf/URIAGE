import SwiftUI

struct ReportItemRow: View {
    let item: SoldItem
    let currencyFormatter: AppCurrencyFormatter
    let percentFormatter: AppPercentFormatter

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline, spacing: 12) {
                Text(item.title)
                    .font(.subheadline.bold())
                    .lineLimit(1)

                Spacer(minLength: 12)

                ProfitText(value: item.profit, formatter: currencyFormatter, font: .subheadline.bold())
            }

            HStack(alignment: .firstTextBaseline, spacing: 12) {
                Text(AppDateFormatter.dateString(from: item.soldAt))
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Spacer(minLength: 12)

                Text(percentFormatter.string(from: item.profitRate))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}
