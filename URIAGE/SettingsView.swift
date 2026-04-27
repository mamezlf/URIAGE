//
//  SettingsView.swift
//  URIAGE
//
//  Created by Codex on 2026/04/26.
//

import SwiftUI

struct SettingsView: View {
    @AppStorage(AppSettingsKey.defaultMercariFeeRate) private var defaultMercariFeeRate = AppDefaults.mercariFeeRate
    @AppStorage(AppSettingsKey.defaultShippingCost) private var defaultShippingCost = AppDefaults.shippingCost
    @AppStorage(AppSettingsKey.defaultPackagingCost) private var defaultPackagingCost = AppDefaults.packagingCost
    @AppStorage(AppSettingsKey.currencyCode) private var currencyCode = AppDefaults.currencyCode

    var body: some View {
        Form {
            Section("デフォルト費用") {
                HStack {
                    Text("メルカリ手数料率")

                    TextField("10", value: feeRatePercentBinding, format: .number.precision(.fractionLength(0...2)))
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)

                    Text("%")
                        .foregroundStyle(.secondary)
                }

                amountField("送料", value: $defaultShippingCost)
                amountField("梱包費", value: $defaultPackagingCost)
            }

            Section("通貨") {
                Picker("通貨", selection: $currencyCode) {
                    Text("JPY").tag("JPY")
                }
            }
        }
        .navigationTitle("設定")
    }

    private var feeRatePercentBinding: Binding<Double> {
        Binding(
            get: { defaultMercariFeeRate * 100 },
            set: { defaultMercariFeeRate = max(0, $0) / 100 }
        )
    }

    private func amountField(_ label: String, value: Binding<Double>) -> some View {
        HStack {
            Text(label)

            TextField("0", value: value, format: .number.precision(.fractionLength(0...2)))
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
        }
    }
}

#Preview {
    NavigationStack {
        SettingsView()
    }
}
