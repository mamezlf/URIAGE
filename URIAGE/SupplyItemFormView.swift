//
//  SupplyItemFormView.swift
//  URIAGE
//
//  Created by Codex on 2026/04/26.
//

import SwiftUI
import SwiftData

struct SupplyItemFormView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    private let originalItem: SupplyItem?

    @State private var name: String
    @State private var type: String
    @State private var unitCost: String
    @State private var quantity: String
    @State private var purchaseDate: Date
    @State private var notes: String
    @State private var validationMessage: String?
    @State private var isShowingValidationAlert = false

    init(item: SupplyItem? = nil) {
        self.originalItem = item
        _name = State(initialValue: item?.name ?? "")
        _type = State(initialValue: item.map { SupplyItemType.displayName(for: $0.type) } ?? SupplyItemType.packaging)
        _unitCost = State(initialValue: item.map { Self.inputText(from: $0.unitCost) } ?? "")
        _quantity = State(initialValue: item.map { String($0.quantity) } ?? "")
        _purchaseDate = State(initialValue: item?.purchaseDate ?? Date())
        _notes = State(initialValue: item?.notes ?? "")
    }

    var body: some View {
        Form {
            Section("基本情報") {
                TextField("名称", text: $name)

                Picker("種類", selection: $type) {
                    ForEach(SupplyItemType.all, id: \.self) { itemType in
                        Text(itemType).tag(itemType)
                    }
                }

                DatePicker("購入日", selection: $purchaseDate, displayedComponents: .date)
                TextField("メモ", text: $notes, axis: .vertical)
                    .lineLimit(2...4)
            }

            Section("数量とコスト") {
                amountField("単価", text: $unitCost)
                integerField("数量", text: $quantity)
            }
        }
        .navigationTitle(originalItem == nil ? "資材を追加" : "資材を編集")
        .alert("保存できません", isPresented: $isShowingValidationAlert) {
            Button("確認", role: .cancel) {}
        } message: {
            Text(validationMessage ?? "入力内容を確認してください。")
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

    private func amountField(_ label: String, text: Binding<String>) -> some View {
        HStack {
            Text(label)

            TextField("0", text: text)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
        }
    }

    private func integerField(_ label: String, text: Binding<String>) -> some View {
        HStack {
            Text(label)

            TextField("0", text: text)
                .keyboardType(.numberPad)
                .multilineTextAlignment(.trailing)
        }
    }

    private func save() {
        guard validate() else {
            isShowingValidationAlert = true
            return
        }

        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedNotes = trimmedOptional(notes)
        let unitCostValue = decimal(from: unitCost)
        let quantityValue = int(from: quantity)
        let totalCostValue = unitCostValue * Decimal(quantityValue)

        if let originalItem {
            originalItem.name = trimmedName
            originalItem.type = type
            originalItem.totalCost = totalCostValue
            originalItem.quantity = quantityValue
            originalItem.remainingQuantity = quantityValue
            originalItem.purchaseDate = purchaseDate
            originalItem.notes = trimmedNotes
        } else {
            let item = SupplyItem(
                name: trimmedName,
                type: type,
                totalCost: totalCostValue,
                quantity: quantityValue,
                remainingQuantity: quantityValue,
                purchaseDate: purchaseDate,
                notes: trimmedNotes
            )

            modelContext.insert(item)
        }

        dismiss()
    }

    private func validate() -> Bool {
        if name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            validationMessage = "名称を入力してください。"
            return false
        }

        if decimal(from: unitCost) < 0 {
            validationMessage = "単価は0以上の金額を入力してください。"
            return false
        }

        if int(from: quantity) <= 0 {
            validationMessage = "数量は1以上を入力してください。"
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

    private func int(from text: String) -> Int {
        Int(text.trimmingCharacters(in: .whitespacesAndNewlines)) ?? 0
    }

    private static func inputText(from value: Decimal) -> String {
        NSDecimalNumber(decimal: value).stringValue
    }
}

#Preview {
    NavigationStack {
        SupplyItemFormView()
    }
    .modelContainer(for: SupplyItem.self, inMemory: true)
}
