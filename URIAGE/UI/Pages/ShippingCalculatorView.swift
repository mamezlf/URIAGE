//
//  ShippingCalculatorView.swift
//  URIAGE
//
//  Created by Codex on 2026/04/26.
//

import SwiftUI

struct ShippingCalculatorView: View {
    @Environment(\.dismiss) private var dismiss

    private let onSelect: ((ShippingOption) -> Void)?

    @State private var length = ""
    @State private var width = ""
    @State private var height = ""
    @State private var weight = ""

    init(onSelect: ((ShippingOption) -> Void)? = nil) {
        self.onSelect = onSelect
    }

    private var package: ShippingPackageSummary {
        ShippingCalculator.packageSummary(
            length: decimal(from: length),
            width: decimal(from: width),
            height: decimal(from: height),
            weight: decimal(from: weight)
        )
    }

    private var options: [ShippingOption] {
        ShippingCalculator.options(
            length: decimal(from: length),
            width: decimal(from: width),
            height: decimal(from: height),
            weight: decimal(from: weight)
        )
    }

    private var recommendedOption: ShippingOption? {
        options.first
    }

    var body: some View {
        ScrollableContainer {
            recommendationPanel
            manualCalculatorSection
            resultSection
        }
        .scrollDismissesKeyboard(.interactively)
        .navigationTitle("送料計算")
    }

    private var recommendationPanel: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(AppTheme.Colors.accent.opacity(0.14))

                    Image(systemName: "shippingbox.fill")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(AppTheme.Colors.accent)
                }
                .frame(width: AppTheme.Metrics.iconBoxSize, height: AppTheme.Metrics.iconBoxSize)

                VStack(alignment: .leading, spacing: 4) {
                    Text("おすすめ発送方式")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text(recommendationTitle)
                        .font(.title2.bold())
                        .lineLimit(2)
                        .minimumScaleFactor(0.78)
                }

                Spacer(minLength: 8)
            }

            HStack(spacing: 10) {
                SummaryMetric(title: "3辺合計", value: hasCompleteInput ? "\(package.totalSize.displayText)cm" : "-")
                SummaryMetric(title: "厚さ", value: hasCompleteInput ? "\(package.thickness.displayText)cm" : "-")
                SummaryMetric(title: "重量", value: hasCompleteInput ? "\(package.weight.displayText)g" : "-")
            }

            if let recommendedOption {
                HStack {
                    Text(recommendedOption.method.shippingCategory)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(AppTheme.Colors.accent)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 5)
                        .background(AppTheme.Colors.accent.opacity(0.12))
                        .clipShape(Capsule())

                    Spacer()

                    Text(priceText(recommendedOption.price))
                        .font(.headline)
                        .foregroundStyle(AppTheme.Colors.cost)
                }

                if let onSelect {
                    Button {
                        onSelect(recommendedOption)
                        dismiss()
                    } label: {
                        Label("この送料を使う", systemImage: "checkmark.circle")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(PrimaryActionButtonStyle())
                    .padding(.top, 4)
                }
            } else {
                Text(recommendationMessage)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .appCard(background: AppTheme.Colors.elevatedCardBackground)
    }

    private var manualCalculatorSection: some View {
        SectionCard(title: "梱包後のサイズ入力") {
            VStack(spacing: 0) {
                HStack(spacing: 10) {
                    DimensionField(title: "長さ", unit: "cm", text: $length)
                    DimensionField(title: "幅", unit: "cm", text: $width)
                }
                .padding([.horizontal, .top], AppTheme.Metrics.cardPadding)

                HStack(spacing: 10) {
                    DimensionField(title: "高さ", unit: "cm", text: $height)
                    DimensionField(title: "重量", unit: "g", text: $weight)
                }
                .padding([.horizontal, .top], AppTheme.Metrics.cardPadding)

                Divider()
                    .padding(.top, AppTheme.Metrics.cardPadding)

                VStack(alignment: .leading, spacing: 10) {
                    Text("よく使うサイズ")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                        PresetButton(title: "A4・薄手", subtitle: "30 x 21 x 2 / 150g") {
                            applyPreset(length: "30", width: "21", height: "2", weight: "150")
                        }

                        PresetButton(title: "A5・薄手", subtitle: "21 x 15 x 2 / 80g") {
                            applyPreset(length: "21", width: "15", height: "2", weight: "800")
                        }

                        PresetButton(title: "60サイズ", subtitle: "30 x 20 x 10 / 150g") {
                            applyPreset(length: "30", width: "20", height: "10", weight: "1500")
                        }

                        PresetButton(title: "80サイズ", subtitle: "40 x 25 x 15 / 300g") {
                            applyPreset(length: "40", width: "25", height: "15", weight: "3000")
                        }
                    }
                }
                .padding(AppTheme.Metrics.cardPadding)
            }
        }
    }

    private var resultSection: some View {
        SectionCard(title: "その他の発送方式") {
            VStack(spacing: 0) {
                if hasInput == false {
                    EmptyResultRow(systemImage: "ruler", message: "サイズと重量を入力すると、条件に合う発送方式を自動で表示します。")
                } else if hasCompleteInput == false {
                    EmptyResultRow(systemImage: "exclamationmark.circle", message: "長さ・幅・高さ・重量をすべて入力してください。")
                } else if options.isEmpty {
                    EmptyResultRow(systemImage: "xmark.circle", message: "条件に合う発送方式がありません。サイズや重量を確認してください。")
                } else {
                    ForEach(Array(options.enumerated()), id: \.element.id) { index, option in
                        ShippingOptionRow(
                            option: option,
                            isRecommended: index == 0,
                            priceText: priceText(option.price),
                            onSelect: onSelect == nil ? nil : {
                                onSelect?(option)
                                dismiss()
                            }
                        )

                        if option.id != options.last?.id {
                            Divider()
                                .padding(.leading, AppTheme.Metrics.cardPadding)
                        }
                    }
                }
            }
        }
    }

    private var recommendationTitle: String {
        guard let recommendedOption else {
            return hasInput ? "候補なし" : "サイズを入力してください"
        }

        return recommendedOption.method.rawValue
    }

    private var recommendationMessage: String {
        if hasInput == false {
            return "下に梱包後のサイズを入れてください。"
        }

        if hasCompleteInput == false {
            return "未入力の項目があります。4つの値がそろうと候補を絞り込みます。"
        }

        return "該当する発送方式が見つかりませんでした。"
    }

    private var hasInput: Bool {
        [length, width, height, weight].contains { $0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false }
    }

    private var hasCompleteInput: Bool {
        package.isValid
    }

    private func applyPreset(length: String, width: String, height: String, weight: String) {
        self.length = length
        self.width = width
        self.height = height
        self.weight = weight
    }

    private func decimal(from text: String) -> Decimal {
        let normalized = text
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: ",", with: "")

        return Decimal(string: normalized) ?? 0
    }

    private func priceText(_ price: Decimal) -> String {
        "\(price.displayText)円"
    }
}

#Preview {
    NavigationStack {
        ShippingCalculatorView()
    }
}
