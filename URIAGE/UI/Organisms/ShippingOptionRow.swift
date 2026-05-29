import SwiftUI

struct ShippingOptionRow: View {
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

extension ShippingMethod {
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
