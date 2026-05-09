//
//  SoldItemFormView.swift
//  URIAGE
//
//  Created by Codex on 2026/04/26.
//

import SwiftUI
import SwiftData
import UIKit

struct SoldItemFormView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.moveToHomeAfterRecordSave) private var moveToHomeAfterRecordSave
    @AppStorage(AppSettingsKey.defaultMercariFeeRate) private var defaultMercariFeeRate = AppDefaults.mercariFeeRate
    @AppStorage(AppSettingsKey.defaultShippingCost) private var defaultShippingCost = AppDefaults.shippingCost
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
    @State private var sourceURL: String
    @State private var validationMessage: String?
    @State private var isShowingValidationAlert = false
    @State private var importMessage: String?
    @State private var isShowingImportAlert = false
    @State private var isImportingMercariItem = false
    @State private var isShowingShippingCalculator = false
    @State private var shippingSelectionMessage: String?
    @State private var hasAppliedDefaultCosts = false
    @State private var didManuallyEditPlatformFee = false
    @State private var hasCompletedSave = false
    private let onSaveComplete: (() -> Void)?

    init(item: SoldItem? = nil, onSaveComplete: (() -> Void)? = nil) {
        self.originalItem = item
        self.onSaveComplete = onSaveComplete
        _title = State(initialValue: item?.title ?? "")
        _soldAt = State(initialValue: item?.soldAt ?? Date())
        _salePrice = State(initialValue: item.map { Self.inputText(from: $0.salePrice) } ?? "")
        _platformFee = State(initialValue: item.map { Self.inputText(from: $0.platformFee) } ?? "")
        _shippingCost = State(initialValue: item.map { Self.inputText(from: $0.shippingCost) } ?? "")
        _purchaseCost = State(initialValue: item.map { Self.inputText(from: $0.purchaseCost) } ?? "")
        _sourceURL = State(initialValue: item?.sourceURL ?? "")
    }

    init(copying item: SoldItem, onSaveComplete: (() -> Void)? = nil) {
        self.originalItem = nil
        self.onSaveComplete = onSaveComplete
        _title = State(initialValue: item.title)
        _soldAt = State(initialValue: Date())
        _salePrice = State(initialValue: Self.inputText(from: item.salePrice))
        _platformFee = State(initialValue: Self.inputText(from: item.platformFee))
        _shippingCost = State(initialValue: Self.inputText(from: item.shippingCost))
        _purchaseCost = State(initialValue: Self.inputText(from: item.purchaseCost))
        _sourceURL = State(initialValue: "")
    }

    init(importedMercariItem: MercariItemImportResult, onSaveComplete: (() -> Void)? = nil) {
        self.originalItem = nil
        self.onSaveComplete = onSaveComplete
        _title = State(initialValue: importedMercariItem.title ?? "")
        _soldAt = State(initialValue: Date())
        _salePrice = State(initialValue: importedMercariItem.price.map { Self.inputText(from: $0) } ?? "")
        _platformFee = State(initialValue: "")
        _shippingCost = State(initialValue: "")
        _purchaseCost = State(initialValue: "")
        _sourceURL = State(initialValue: importedMercariItem.url.absoluteString)
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

            Section("タイトル") {
                TextField("商品名", text: $title)
                DatePicker("販売日", selection: $soldAt, displayedComponents: .date)

                VStack(alignment: .leading, spacing: 8) {
                    TextField("メルカリ商品リンク", text: $sourceURL)
                        .keyboardType(.URL)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()

                    HStack {
                        Spacer()
                        Button {
                            Task {
                                await importMercariItem()
                            }
                        } label: {
                            Label("リンクから読み込む", systemImage: "link")
                        }
                        .buttonStyle(.bordered)
                        .disabled(isImportingMercariItem)

                        if isImportingMercariItem {
                            ProgressView()
                        }
                    }
                }
                .padding(.vertical, 2)
            }

            Section("金額") {
                amountField("販売価格", text: $salePrice)
                amountField("メルカリ手数料", text: platformFeeBinding)

                VStack(alignment: .leading, spacing: 8) {
                    amountField("送料", text: $shippingCost)

                    HStack {
                        Spacer()
                        Button {
                            isShowingShippingCalculator = true
                        } label: {
                            Label("送料を計算", systemImage: "shippingbox")
                        }
                        .buttonStyle(.bordered)
                    }

                    if let shippingSelectionMessage {
                        Text(shippingSelectionMessage)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 2)

                amountField("仕入れ価格", text: $purchaseCost)
            }
        }
        .navigationTitle(originalItem == nil ? "販売記録を追加" : "販売記録を編集")
        .alert("保存できません", isPresented: $isShowingValidationAlert) {
            Button("確認", role: .cancel) {}
        } message: {
            Text(validationMessage ?? "入力内容を確認してください。")
        }
        .alert("リンク読み込み", isPresented: $isShowingImportAlert) {
            Button("確認", role: .cancel) {}
        } message: {
            Text(importMessage ?? "")
        }
        .onAppear(perform: applyDefaultsIfNeeded)
        .onChange(of: salePrice) { _, _ in
            updatePlatformFeeFromSalePriceIfNeeded()
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
                    .disabled(hasCompletedSave)
            }
        }
    }

    private var previewProfit: Decimal {
        ProfitCalculator.profit(
            salePrice: decimal(from: salePrice),
            purchaseCost: decimal(from: purchaseCost),
            shippingCost: decimal(from: shippingCost),
            platformFee: decimal(from: platformFee),
            packagingCost: 0,
            otherCosts: 0
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

        let defaultShipping = Decimal(defaultShippingCost)
        shippingCost = defaultShipping == 0 ? "" : Self.inputText(from: defaultShipping)
        updatePlatformFeeFromSalePriceIfNeeded()
        hasAppliedDefaultCosts = true
    }

    private func updatePlatformFeeFromSalePriceIfNeeded() {
        guard originalItem == nil, didManuallyEditPlatformFee == false else {
            return
        }

        let calculatedFee = (decimal(from: salePrice) * Decimal(defaultMercariFeeRate)).roundedScale0
        platformFee = calculatedFee == 0 ? "" : Self.inputText(from: calculatedFee)
    }

    private func applyShippingOption(_ option: ShippingOption) {
        shippingCost = Self.inputText(from: option.price)
        shippingSelectionMessage = "\(option.method.rawValue)を送料に設定しました"
        isShowingShippingCalculator = false
    }

    private func save() {
        guard hasCompletedSave == false else {
            return
        }

        guard validate() else {
            isShowingValidationAlert = true
            return
        }

        hasCompletedSave = true
        let trimmedSourceURL = trimmedOptional(sourceURL)

        if let originalItem {
            originalItem.title = title.trimmingCharacters(in: .whitespacesAndNewlines)
            originalItem.soldAt = soldAt
            originalItem.quantity = 1
            originalItem.salePrice = decimal(from: salePrice)
            originalItem.purchaseCost = decimal(from: purchaseCost)
            originalItem.shippingCost = decimal(from: shippingCost)
            originalItem.platformFee = decimal(from: platformFee)
            originalItem.packagingCost = 0
            originalItem.inventoryPackagingCost = 0
            originalItem.otherCosts = 0
            originalItem.sourceURL = trimmedSourceURL
        } else {
            let item = SoldItem(
                title: title.trimmingCharacters(in: .whitespacesAndNewlines),
                salePrice: decimal(from: salePrice),
                quantity: 1,
                purchaseCost: decimal(from: purchaseCost),
                shippingCost: decimal(from: shippingCost),
                platformFee: decimal(from: platformFee),
                packagingCost: 0,
                inventoryPackagingCost: 0,
                otherCosts: 0,
                soldAt: soldAt,
                sourceURL: trimmedSourceURL
            )

            modelContext.insert(item)
        }

        completeSave()
    }

    private func completeSave() {
        if let onSaveComplete {
            onSaveComplete()
        } else if let moveToHomeAfterRecordSave {
            moveToHomeAfterRecordSave()
        } else {
            dismiss()
        }
    }

    private func validate() -> Bool {
        if sourceURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false {
            do {
                _ = try MercariItemImporter.normalize(sourceURL)
            } catch {
                validationMessage = error.localizedDescription
                return false
            }
        }

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
            ("仕入れ価格", purchaseCost)
        ]

        for field in nonNegativeFields where decimal(from: field.1) < 0 {
            validationMessage = "\(field.0)は0以上の金額を入力してください。"
            return false
        }

        validationMessage = nil
        return true
    }

    @MainActor
    private func importMercariItem() async {
        if let clipboardText = UIPasteboard.general.string?.trimmingCharacters(in: .whitespacesAndNewlines),
           clipboardText.isEmpty == false {
            sourceURL = clipboardText
        }

        guard sourceURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false else {
            importMessage = "クリップボードにMercariリンクがありません。"
            isShowingImportAlert = true
            return
        }

        isImportingMercariItem = true
        defer {
            isImportingMercariItem = false
        }

        do {
            let result = try await MercariItemImporter.fetch(from: sourceURL)
            sourceURL = result.url.absoluteString

            if let importedTitle = result.title, title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                title = importedTitle
            }

            if let importedPrice = result.price, decimal(from: salePrice) == 0 {
                salePrice = Self.inputText(from: importedPrice)
                updatePlatformFeeFromSalePriceIfNeeded()
            }

            if result.title == nil || result.price == nil {
                importMessage = "リンクを保存しました。取得できなかった項目は手入力してください。"
                isShowingImportAlert = true
            }
        } catch {
            if let normalized = try? MercariItemImporter.normalize(sourceURL) {
                sourceURL = normalized.url.absoluteString
            }

            importMessage = error.localizedDescription
            isShowingImportAlert = true
        }
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

#if DEBUG
#Preview {
    NavigationStack {
        SoldItemFormView(item: SoldItem.sample)
    }
    .modelContainer(for: [SoldItem.self, SupplyItem.self], inMemory: true)
}
#endif
