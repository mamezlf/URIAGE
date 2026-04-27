//
//  SoldItemFormView.swift
//  URIAGE
//
//  Created by Codex on 2026/04/26.
//

import SwiftUI
import SwiftData

struct SoldItemFormView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \SupplyItem.purchaseDate, order: .reverse) private var supplies: [SupplyItem]
    @AppStorage(AppSettingsKey.defaultMercariFeeRate) private var defaultMercariFeeRate = AppDefaults.mercariFeeRate
    @AppStorage(AppSettingsKey.defaultShippingCost) private var defaultShippingCost = AppDefaults.shippingCost
    @AppStorage(AppSettingsKey.defaultPackagingCost) private var defaultPackagingCost = AppDefaults.packagingCost
    @AppStorage(AppSettingsKey.currencyCode) private var currencyCode = AppDefaults.currencyCode

    private let originalItem: SoldItem?

    private var currencyFormatter: AppCurrencyFormatter {
        AppCurrencyFormatter(currencyCode: currencyCode)
    }

    @State private var title: String
    @State private var soldAt: Date
    @State private var salePrice: String
    @State private var platformFee: String
    @State private var shippingCost: String
    @State private var purchaseCost: String
    @State private var packagingCost: String
    @State private var otherCosts: String
    @State private var tags: String
    @State private var memo: String
    @State private var validationMessage: String?
    @State private var isShowingValidationAlert = false
    @State private var isShowingSupplyPicker = false
    @State private var isShowingShippingCalculator = false
    @State private var supplySelectionMessage: String?
    @State private var shippingSelectionMessage: String?
    @State private var hasAppliedDefaultCosts = false
    @State private var didManuallyEditPlatformFee = false

    init(item: SoldItem? = nil) {
        self.originalItem = item
        _title = State(initialValue: item?.title ?? "")
        _soldAt = State(initialValue: item?.soldAt ?? Date())
        _salePrice = State(initialValue: Self.inputText(from: item?.salePrice ?? 0))
        _platformFee = State(initialValue: Self.inputText(from: item?.platformFee ?? 0))
        _shippingCost = State(initialValue: Self.inputText(from: item?.shippingCost ?? 0))
        _purchaseCost = State(initialValue: Self.inputText(from: item?.purchaseCost ?? 0))
        _packagingCost = State(initialValue: Self.inputText(from: item?.packagingCost ?? 0))
        _otherCosts = State(initialValue: Self.inputText(from: item?.otherCosts ?? 0))
        _tags = State(initialValue: item?.tags ?? "")
        _memo = State(initialValue: item?.memo ?? "")
    }

    var body: some View {
        Form {
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text("利益")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    ProfitText(value: previewProfit, formatter: currencyFormatter, font: .largeTitle.bold())
                        .minimumScaleFactor(0.7)
                        .lineLimit(1)
                }
                .padding(.vertical, 6)
            }

            Section("商品") {
                TextField("商品名", text: $title)
                DatePicker("販売日", selection: $soldAt, displayedComponents: .date)
                TextField("タグ", text: $tags)
                TextField("メモ", text: $memo, axis: .vertical)
                    .lineLimit(2...4)
            }

            Section("金額") {
                amountField("販売価格", text: $salePrice)
                amountField("メルカリ手数料", text: platformFeeBinding)

                VStack(alignment: .leading, spacing: 8) {
                    amountField("送料", text: $shippingCost)

                    HStack {
                        Button {
                            isShowingShippingCalculator = true
                        } label: {
                            Label("送料を計算", systemImage: "shippingbox")
                        }
                        .buttonStyle(.bordered)

                        Spacer()
                    }

                    if let shippingSelectionMessage {
                        Text(shippingSelectionMessage)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 2)

                amountField("仕入れ価格", text: $purchaseCost)

                VStack(alignment: .leading, spacing: 8) {
                    amountField("梱包費", text: $packagingCost)

                    HStack {
                        Button {
                            isShowingSupplyPicker = true
                        } label: {
                            Label("資材から追加", systemImage: "shippingbox")
                        }
                        .buttonStyle(.bordered)

                        Spacer()
                    }

                    if let supplySelectionMessage {
                        Text(supplySelectionMessage)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 2)

                amountField("その他費用", text: $otherCosts)
            }
        }
        .navigationTitle(originalItem == nil ? "販売記録を追加" : "販売記録を編集")
        .alert("保存できません", isPresented: $isShowingValidationAlert) {
            Button("確認", role: .cancel) {}
        } message: {
            Text(validationMessage ?? "入力内容を確認してください。")
        }
        .onAppear(perform: applyDefaultsIfNeeded)
        .onChange(of: salePrice) { _, _ in
            updatePlatformFeeFromSalePriceIfNeeded()
        }
        .sheet(isPresented: $isShowingSupplyPicker) {
            NavigationStack {
                SupplyPickerView(
                    supplies: supplies,
                    currencyFormatter: currencyFormatter,
                    onSelect: addSupplyToPackagingCost
                )
            }
        }
        .sheet(isPresented: $isShowingShippingCalculator) {
            NavigationStack {
                ShippingCalculatorView(onSelect: applyShippingOption)
            }
        }
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("キャンセル", role: .cancel) {
                    dismiss()
                }
            }

            ToolbarItem(placement: .confirmationAction) {
                Button("保存", action: save)
            }
        }
    }

    private var previewProfit: Decimal {
        ProfitCalculator.profit(
            salePrice: decimal(from: salePrice),
            purchaseCost: decimal(from: purchaseCost),
            shippingCost: decimal(from: shippingCost),
            platformFee: decimal(from: platformFee),
            packagingCost: decimal(from: packagingCost),
            otherCosts: decimal(from: otherCosts)
        )
    }

    private var platformFeeBinding: Binding<String> {
        Binding(
            get: { platformFee },
            set: { newValue in
                platformFee = newValue
                didManuallyEditPlatformFee = true
            }
        )
    }

    private func amountField(_ label: String, text: Binding<String>) -> some View {
        HStack {
            Text(label)

            TextField("0", text: text)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
        }
    }

    private func applyDefaultsIfNeeded() {
        guard originalItem == nil, hasAppliedDefaultCosts == false else {
            return
        }

        shippingCost = Self.inputText(from: Decimal(defaultShippingCost))
        packagingCost = Self.inputText(from: Decimal(defaultPackagingCost))
        updatePlatformFeeFromSalePriceIfNeeded()
        hasAppliedDefaultCosts = true
    }

    private func updatePlatformFeeFromSalePriceIfNeeded() {
        guard originalItem == nil, didManuallyEditPlatformFee == false else {
            return
        }

        let calculatedFee = decimal(from: salePrice) * Decimal(defaultMercariFeeRate)
        platformFee = Self.inputText(from: calculatedFee.roundedScale0)
    }

    private func addSupplyToPackagingCost(_ supply: SupplyItem) {
        let updatedCost = decimal(from: packagingCost) + supply.unitCost
        packagingCost = Self.inputText(from: updatedCost)
        supplySelectionMessage = "\(supply.name)を追加しました"
        isShowingSupplyPicker = false
    }

    private func applyShippingOption(_ option: ShippingOption) {
        shippingCost = Self.inputText(from: option.price)
        shippingSelectionMessage = "\(option.method.rawValue)を送料に設定しました"
        isShowingShippingCalculator = false
    }

    private func save() {
        guard validate() else {
            isShowingValidationAlert = true
            return
        }

        let trimmedTags = trimmedOptional(tags)
        let trimmedMemo = trimmedOptional(memo)

        if let originalItem {
            originalItem.title = title.trimmingCharacters(in: .whitespacesAndNewlines)
            originalItem.soldAt = soldAt
            originalItem.salePrice = decimal(from: salePrice)
            originalItem.purchaseCost = decimal(from: purchaseCost)
            originalItem.shippingCost = decimal(from: shippingCost)
            originalItem.platformFee = decimal(from: platformFee)
            originalItem.packagingCost = decimal(from: packagingCost)
            originalItem.otherCosts = decimal(from: otherCosts)
            originalItem.tags = trimmedTags
            originalItem.memo = trimmedMemo
        } else {
            let item = SoldItem(
                title: title.trimmingCharacters(in: .whitespacesAndNewlines),
                salePrice: decimal(from: salePrice),
                purchaseCost: decimal(from: purchaseCost),
                shippingCost: decimal(from: shippingCost),
                platformFee: decimal(from: platformFee),
                packagingCost: decimal(from: packagingCost),
                otherCosts: decimal(from: otherCosts),
                soldAt: soldAt,
                tags: trimmedTags,
                memo: trimmedMemo
            )

            modelContext.insert(item)
        }

        dismiss()
    }

    private func validate() -> Bool {
        if title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            validationMessage = "商品名を入力してください。"
            return false
        }

        let salePriceValue = decimal(from: salePrice)
        if salePriceValue <= 0 {
            validationMessage = "販売価格は0より大きい金額を入力してください。"
            return false
        }

        let nonNegativeFields = [
            ("メルカリ手数料", platformFee),
            ("送料", shippingCost),
            ("仕入れ価格", purchaseCost),
            ("梱包費", packagingCost),
            ("その他費用", otherCosts)
        ]

        for field in nonNegativeFields where decimal(from: field.1) < 0 {
            validationMessage = "\(field.0)は0以上の金額を入力してください。"
            return false
        }

        validationMessage = nil
        return true
    }

    private func trimmedOptional(_ text: String) -> String? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    private func decimal(from text: String) -> Decimal {
        let normalized = text
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: ",", with: "")

        return Decimal(string: normalized) ?? 0
    }

    private static func inputText(from value: Decimal) -> String {
        NSDecimalNumber(decimal: value).stringValue
    }
}

private struct SupplyPickerView: View {
    let supplies: [SupplyItem]
    let currencyFormatter: AppCurrencyFormatter
    let onSelect: (SupplyItem) -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        List {
            if supplies.isEmpty {
                Section {
                    EmptyStateCard(
                        title: "登録済みの資材がありません",
                        message: "資材タブで梱包材などを追加すると、ここから梱包費に反映できます。",
                        systemImage: "archivebox"
                    )
                }
                .listRowBackground(Color.clear)
            } else {
                ForEach(supplies) { supply in
                    Button {
                        onSelect(supply)
                    } label: {
                        HStack(alignment: .firstTextBaseline, spacing: 12) {
                            VStack(alignment: .leading, spacing: 6) {
                                Text(supply.name)
                                    .font(.headline)
                                    .foregroundStyle(.primary)

                                Text("\(supply.displayType) · 残り \(supply.remainingQuantity)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer(minLength: 12)

                            Text(currencyFormatter.string(from: supply.unitCost))
                                .font(.subheadline.bold())
                                .foregroundStyle(.primary)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
        .navigationTitle("資材を選択")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("キャンセル") {
                    dismiss()
                }
            }
        }
    }
}

#if DEBUG
#Preview {
    NavigationStack {
        SoldItemFormView(item: SoldItem.sample)
    }
    .modelContainer(for: [SoldItem.self, SupplyItem.self], inMemory: true)
}
#endif
