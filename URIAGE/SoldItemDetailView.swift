//
//  SoldItemDetailView.swift
//  URIAGE
//
//  Created by Codex on 2026/04/26.
//

import SwiftUI
import SwiftData

struct SoldItemDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let item: SoldItem

    @State private var isShowingDeleteConfirmation = false
    @AppStorage(AppSettingsKey.currencyCode) private var currencyCode = AppDefaults.currencyCode

    private var currencyFormatter: AppCurrencyFormatter {
        AppCurrencyFormatter(currencyCode: currencyCode)
    }

    private let percentFormatter = AppPercentFormatter()

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text(item.title)
                        .font(.title2.bold())

                    Text(AppDateFormatter.dateString(from: item.soldAt))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
            }

            Section("商品") {
                detailRow("カテゴリ", item.category.displayName)
                detailRow("タグ", textOrDash(item.tags))
                detailRow("メモ", textOrDash(item.memo))
            }

            Section("金額") {
                detailAmountRow("販売価格", item.salePrice, role: .sales)
                detailAmountRow("メルカリ手数料", item.platformFee, role: .cost)
                detailAmountRow("送料", item.shippingCost, role: .cost)
                detailAmountRow("仕入れ価格", item.purchaseCost, role: .cost)
                detailAmountRow("梱包費", item.packagingCost, role: .cost)
                detailAmountRow("その他費用", item.otherCosts, role: .cost)
            }

            Section("サマリー") {
                detailAmountRow("純売上", item.netIncome, role: .sales)
                detailAmountRow("総コスト", item.totalCost, role: .cost)
                detailProfitRow("利益", item.profit)
                detailRow("利益率", percentFormatter.string(from: item.profitRate))
            }

            Section {
                Button(role: .destructive) {
                    isShowingDeleteConfirmation = true
                } label: {
                    Label("販売記録を削除", systemImage: "trash")
                }
            }
        }
        .navigationTitle("販売記録")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink {
                    SoldItemFormView(item: item)
                } label: {
                    Label("編集", systemImage: "pencil")
                }
            }
        }
        .confirmationDialog(
            "この販売記録を削除しますか？",
            isPresented: $isShowingDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("削除", role: .destructive, action: delete)
            Button("キャンセル", role: .cancel) {}
        } message: {
            Text("この操作は取り消せません。")
        }
    }

    private func detailRow(_ label: String, _ value: String, valueTint: Color = .primary) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 16) {
            Text(label)
                .foregroundStyle(.secondary)

            Spacer(minLength: 16)

            Text(value)
                .multilineTextAlignment(.trailing)
                .foregroundStyle(valueTint)
        }
    }

    private func detailProfitRow(_ label: String, _ value: Decimal) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 16) {
            Text(label)
                .foregroundStyle(.secondary)

            Spacer(minLength: 16)

            ProfitText(value: value, formatter: currencyFormatter, font: .body)
        }
    }

    private func detailAmountRow(_ label: String, _ value: Decimal, role: AmountRole) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 16) {
            Text(label)
                .foregroundStyle(.secondary)

            Spacer(minLength: 16)

            AmountText(value: value, formatter: currencyFormatter, role: role)
        }
    }

    private func textOrDash(_ text: String?) -> String {
        guard let text, text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false else {
            return "-"
        }

        return text
    }

    private func delete() {
        modelContext.delete(item)
        dismiss()
    }
}

#if DEBUG
#Preview {
    NavigationStack {
        SoldItemDetailView(item: SoldItem.sample)
    }
    .modelContainer(for: SoldItem.self, inMemory: true)
}
#endif
