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
        ScrollView {
            VStack(alignment: .leading, spacing: AppTheme.Metrics.sectionSpacing) {
                recommendationPanel
                manualCalculatorSection
                resultSection
            }
            .padding()
        }
        .background(AppTheme.Colors.pageBackground)
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
        SectionCard(title: "手動送料計算") {
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
                        PresetButton(title: "A4・薄手", subtitle: "30 x 21 x 2 / 500g") {
                            applyPreset(length: "30", width: "21", height: "2", weight: "500")
                        }

                        PresetButton(title: "小型箱", subtitle: "24 x 17 x 7 / 900g") {
                            applyPreset(length: "24", width: "17", height: "7", weight: "900")
                        }

                        PresetButton(title: "60サイズ", subtitle: "30 x 20 x 10 / 1500g") {
                            applyPreset(length: "30", width: "20", height: "10", weight: "1500")
                        }

                        PresetButton(title: "80サイズ", subtitle: "40 x 25 x 15 / 3000g") {
                            applyPreset(length: "40", width: "25", height: "15", weight: "3000")
                        }
                    }
                }
                .padding(AppTheme.Metrics.cardPadding)
            }
        }
    }

    private var resultSection: some View {
        SectionCard(title: "自動で絞り込まれた発送方式") {
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
            return hasInput ? "候補なし" : "サイズを入力"
        }

        return recommendedOption.method.rawValue
    }

    private var recommendationMessage: String {
        if hasInput == false {
            return "下の手動送料計算に梱包後のサイズを入れてください。"
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

private struct SummaryMetric: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)

            Text(value)
                .font(.subheadline.weight(.semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.72)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 10)
        .padding(.vertical, 9)
        .background(AppTheme.Colors.pageBackground)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

private struct DimensionField: View {
    let title: String
    let unit: String
    @Binding var text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            HStack(alignment: .firstTextBaseline, spacing: 6) {
                TextField("0", text: $text)
                    .keyboardType(.decimalPad)
                    .font(.title3.weight(.semibold))
                    .lineLimit(1)

                Text(unit)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 12)
            .frame(height: 48)
            .background(AppTheme.Colors.pageBackground)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct PresetButton: View {
    let title: String
    let subtitle: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: "shippingbox")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppTheme.Colors.accent)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.82)

                    Text(subtitle)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.72)
                }

                Spacer(minLength: 0)
            }
            .padding(10)
            .frame(maxWidth: .infinity, minHeight: 58, alignment: .leading)
            .background(AppTheme.Colors.pageBackground)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

private struct ShippingOptionRow: View {
    let option: ShippingOption
    let isRecommended: Bool
    let priceText: String
    let onSelect: (() -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(option.method.tint.opacity(0.14))

                    Image(systemName: option.method.systemImage)
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(option.method.tint)
                }
                .frame(width: AppTheme.Metrics.iconBoxSize, height: AppTheme.Metrics.iconBoxSize)

                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 8) {
                        Text(option.method.rawValue)
                            .font(.headline)
                            .lineLimit(2)

                        if isRecommended {
                            Text("最安")
                                .font(.caption2.weight(.bold))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 7)
                                .padding(.vertical, 3)
                                .background(AppTheme.Colors.success)
                                .clipShape(Capsule())
                        }
                    }

                    Text(option.method.limitText)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 8)

                Text(priceText)
                    .font(.headline)
                    .foregroundStyle(AppTheme.Colors.cost)
                    .lineLimit(1)
            }

            HStack(spacing: 6) {
                ForEach(option.method.badges, id: \.self) { badge in
                    Text(badge)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 4)
                        .background(AppTheme.Colors.pageBackground)
                        .clipShape(Capsule())
                }

                Spacer(minLength: 0)
            }

            if let onSelect {
                Button(action: onSelect) {
                    Label("この送料を使う", systemImage: "checkmark.circle")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(PrimaryActionButtonStyle())
            }
        }
        .padding(AppTheme.Metrics.cardPadding)
    }
}

private struct EmptyResultRow: View {
    let systemImage: String
    let message: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.headline)
                .foregroundStyle(.secondary)
                .frame(width: AppTheme.Metrics.iconBoxSize, height: AppTheme.Metrics.iconBoxSize)

            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(AppTheme.Metrics.cardPadding)
    }
}

private extension ShippingMethod {
    var shippingCategory: String {
        switch self {
        case .nekopos, .takkyubinCompact, .takkyubin60, .takkyubin80, .takkyubin100, .takkyubin120, .takkyubin140, .takkyubin160, .takkyubin180, .takkyubin200, .konekoBin420:
            return "らくらく・ヤマト系"
        case .yuPacket, .yuPacketPost, .yuPacketPostMini, .yuPacketPlus, .yuPack60, .yuPack80, .yuPack100, .yuPack120, .yuPack140, .yuPack160, .yuPack170:
            return "ゆうゆう・日本郵便系"
        case .standardMail, .nonStandardMailStandardSize, .nonStandardMailNonStandardSize, .letterPackLight, .letterPackPlus, .smartLetter, .clickPost:
            return "郵便・その他"
        }
    }

    var limitText: String {
        switch self {
        case .nekopos:
            return "3辺60cm以内・長辺34cm以内・厚さ3cm以内・1kg以内"
        case .yuPacket:
            return "3辺60cm以内・長辺34cm以内・厚さ3cm以内・1kg以内"
        case .yuPacketPost:
            return "3辺60cm以内・長辺34cm以内・厚さ3cm以内・2kg以内"
        case .yuPacketPostMini:
            return "21.1 x 16.8cm以内・2kg以内・専用封筒"
        case .yuPacketPlus:
            return "24 x 17 x 7cm以内・2kg以内・専用箱"
        case .clickPost:
            return "34 x 25 x 3cm以内・1kg以内"
        case .standardMail:
            return "23.5 x 12 x 1cm以内・50g以内"
        case .takkyubinCompact:
            return "34 x 25 x 5cm以内・専用BOX"
        case .takkyubin60:
            return "3辺60cm以内・2kg以内"
        case .takkyubin80:
            return "3辺80cm以内・5kg以内"
        case .takkyubin100:
            return "3辺100cm以内・10kg以内"
        case .takkyubin120:
            return "3辺120cm以内・15kg以内"
        case .takkyubin140:
            return "3辺140cm以内・20kg以内"
        case .takkyubin160:
            return "3辺160cm以内・25kg以内"
        case .takkyubin180:
            return "3辺180cm以内・30kg以内"
        case .takkyubin200:
            return "3辺200cm以内・30kg以内"
        case .yuPack60:
            return "3辺60cm以内・25kg以内"
        case .yuPack80:
            return "3辺80cm以内・25kg以内"
        case .yuPack100:
            return "3辺100cm以内・25kg以内"
        case .yuPack120:
            return "3辺120cm以内・25kg以内"
        case .yuPack140:
            return "3辺140cm以内・25kg以内"
        case .yuPack160:
            return "3辺160cm以内・25kg以内"
        case .yuPack170:
            return "3辺170cm以内・25kg以内"
        case .nonStandardMailStandardSize:
            return "34 x 25 x 3cm以内・1kg以内・重量で変動"
        case .nonStandardMailNonStandardSize:
            return "3辺90cm以内・4kg以内・重量で変動"
        case .letterPackLight:
            return "34 x 24.8 x 3cm以内・4kg以内"
        case .letterPackPlus:
            return "34 x 24.8cm以内・4kg以内・封筒に入れば厚さ制限なし"
        case .smartLetter:
            return "25 x 17 x 2cm以内・1kg以内"
        case .konekoBin420:
            return "34 x 24.8 x 3cm以内・専用封筒代込み"
        }
    }

    var badges: [String] {
        switch self {
        case .nekopos, .yuPacket, .yuPacketPost, .yuPacketPostMini, .yuPacketPlus, .takkyubinCompact, .takkyubin60, .takkyubin80, .takkyubin100, .takkyubin120, .takkyubin140, .takkyubin160, .takkyubin180, .takkyubin200, .yuPack60, .yuPack80, .yuPack100, .yuPack120, .yuPack140, .yuPack160, .yuPack170:
            return ["匿名", "追跡"]
        case .clickPost, .letterPackLight, .letterPackPlus, .konekoBin420:
            return ["追跡"]
        case .standardMail, .nonStandardMailStandardSize, .nonStandardMailNonStandardSize, .smartLetter:
            return ["低コスト"]
        }
    }

    var systemImage: String {
        switch self {
        case .nekopos, .yuPacket, .yuPacketPost, .yuPacketPostMini, .clickPost, .standardMail, .nonStandardMailStandardSize, .nonStandardMailNonStandardSize, .letterPackLight, .letterPackPlus, .smartLetter, .konekoBin420:
            return "envelope"
        case .yuPacketPlus, .takkyubinCompact:
            return "shippingbox"
        case .takkyubin60, .takkyubin80, .takkyubin100, .takkyubin120, .takkyubin140, .takkyubin160, .takkyubin180, .takkyubin200, .yuPack60, .yuPack80, .yuPack100, .yuPack120, .yuPack140, .yuPack160, .yuPack170:
            return "box.truck"
        }
    }

    var tint: Color {
        switch self {
        case .nekopos, .takkyubinCompact, .takkyubin60, .takkyubin80, .takkyubin100, .takkyubin120, .takkyubin140, .takkyubin160, .takkyubin180, .takkyubin200, .konekoBin420:
            return AppTheme.Colors.accent
        case .yuPacket, .yuPacketPost, .yuPacketPostMini, .yuPacketPlus, .yuPack60, .yuPack80, .yuPack100, .yuPack120, .yuPack140, .yuPack160, .yuPack170:
            return AppTheme.Colors.primary
        case .standardMail, .nonStandardMailStandardSize, .nonStandardMailNonStandardSize, .letterPackLight, .letterPackPlus, .smartLetter, .clickPost:
            return AppTheme.Colors.secondary
        }
    }
}

private extension Decimal {
    var displayText: String {
        let number = NSDecimalNumber(decimal: self)
        return number.stringValue
    }
}

#Preview {
    NavigationStack {
        ShippingCalculatorView()
    }
}
