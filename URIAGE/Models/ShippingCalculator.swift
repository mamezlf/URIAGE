//
//  ShippingCalculator.swift
//  URIAGE
//
//  Created by Codex on 2026/04/26.
//

import Foundation

enum ShippingMethod: String, CaseIterable {
    case nekopos = "ネコポス"
    case yuPacket = "ゆうパケット"
    case yuPacketPost = "ゆうパケットポスト"
    case yuPacketPostMini = "ゆうパケットポストmini"
    case yuPacketPlus = "ゆうパケットプラス"
    case clickPost = "クリックポスト"
    case standardMail = "定形郵便"
    case takkyubinCompact = "宅急便コンパクト"
    case takkyubin60 = "宅急便60"
    case takkyubin80 = "宅急便80"
    case takkyubin100 = "宅急便100"
    case takkyubin120 = "宅急便120"
    case takkyubin140 = "宅急便140"
    case takkyubin160 = "宅急便160"
    case takkyubin180 = "宅急便180"
    case takkyubin200 = "宅急便200"
    case yuPack60 = "ゆうパック60"
    case yuPack80 = "ゆうパック80"
    case yuPack100 = "ゆうパック100"
    case yuPack120 = "ゆうパック120"
    case yuPack140 = "ゆうパック140"
    case yuPack160 = "ゆうパック160"
    case yuPack170 = "ゆうパック170"
    case nonStandardMailStandardSize = "定形外郵便（規格内）"
    case nonStandardMailNonStandardSize = "定形外郵便（規格外）"
    case letterPackLight = "レターパックライト"
    case letterPackPlus = "レターパックプラス"
    case smartLetter = "スマートレター"
    case konekoBin420 = "こねこ便420"

    var sortOrder: Int {
        Self.allCases.firstIndex(of: self) ?? 0
    }
}

struct ShippingOption: Identifiable, Equatable {
    var id: ShippingMethod { method }
    let method: ShippingMethod
    let price: Decimal
}

struct ShippingPackageSummary: Equatable {
    let longestSide: Decimal
    let middleSide: Decimal
    let thickness: Decimal
    let totalSize: Decimal
    let weight: Decimal

    var isValid: Bool {
        longestSide > 0 && middleSide > 0 && thickness > 0 && weight > 0
    }
}

enum ShippingCalculator {
    static func packageSummary(
        length: Decimal,
        width: Decimal,
        height: Decimal,
        weight: Decimal
    ) -> ShippingPackageSummary {
        let dimensions = [length, width, height].sorted(by: >)

        return ShippingPackageSummary(
            longestSide: dimensions[0],
            middleSide: dimensions[1],
            thickness: dimensions[2],
            totalSize: length + width + height,
            weight: weight
        )
    }

    static func options(length: Decimal, width: Decimal, height: Decimal, weight: Decimal) -> [ShippingOption] {
        let package = packageSummary(length: length, width: width, height: height, weight: weight)

        guard package.isValid else {
            return []
        }

        let standardSizeMailPrice = nonStandardMailStandardSizePrice(
            longestSide: package.longestSide,
            middleSide: package.middleSide,
            thickness: package.thickness,
            weight: package.weight
        )
        let nonStandardSizeMailPrice = standardSizeMailPrice == nil
            ? nonStandardMailNonStandardSizePrice(totalSize: package.totalSize, weight: package.weight)
            : nil

        let rules: [(ShippingMethod, Decimal, Bool)] = [
            (.nekopos, 210, package.totalSize <= 60 && package.longestSide <= 34 && package.thickness <= 3 && package.weight <= 1_000),
            (.yuPacket, 230, package.longestSide <= 34 && package.middleSide <= 23 && package.thickness <= 3 && package.weight <= 1_000),
            (.yuPacketPost, 215, package.totalSize <= 60 && package.longestSide <= 34 && package.thickness <= 3 && package.weight <= 2_000),
            (.yuPacketPostMini, 160, package.longestSide <= 21.1 && package.middleSide <= 16.8 && package.weight <= 2_000),
            (.yuPacketPlus, 455, package.longestSide <= 24 && package.middleSide <= 17 && package.thickness <= 7 && package.weight <= 2_000),
            (.clickPost, 185, package.longestSide <= 34 && package.middleSide <= 25 && package.thickness <= 3 && package.weight <= 1_000),
            (.standardMail, 110, package.longestSide <= 23.5 && package.middleSide <= 12 && package.thickness <= 1 && package.weight <= 50),
            (.takkyubinCompact, 450, package.longestSide <= 34 && package.middleSide <= 25 && package.thickness <= 5),
            (.takkyubin60, 750, package.totalSize <= 60 && package.weight <= 2_000),
            (.takkyubin80, 850, package.totalSize <= 80 && package.weight <= 5_000),
            (.takkyubin100, 1_050, package.totalSize <= 100 && package.weight <= 10_000),
            (.takkyubin120, 1_200, package.totalSize <= 120 && package.weight <= 15_000),
            (.takkyubin140, 1_450, package.totalSize <= 140 && package.weight <= 20_000),
            (.takkyubin160, 1_700, package.totalSize <= 160 && package.weight <= 25_000),
            (.takkyubin180, 2_100, package.totalSize <= 180 && package.weight <= 30_000),
            (.takkyubin200, 2_500, package.totalSize <= 200 && package.weight <= 30_000),
            (.yuPack60, 750, package.totalSize <= 60 && package.weight <= 25_000),
            (.yuPack80, 870, package.totalSize <= 80 && package.weight <= 25_000),
            (.yuPack100, 1_070, package.totalSize <= 100 && package.weight <= 25_000),
            (.yuPack120, 1_200, package.totalSize <= 120 && package.weight <= 25_000),
            (.yuPack140, 1_450, package.totalSize <= 140 && package.weight <= 25_000),
            (.yuPack160, 1_700, package.totalSize <= 160 && package.weight <= 25_000),
            (.yuPack170, 1_900, package.totalSize <= 170 && package.weight <= 25_000),
            (.nonStandardMailStandardSize, standardSizeMailPrice ?? 0, standardSizeMailPrice != nil),
            (.nonStandardMailNonStandardSize, nonStandardSizeMailPrice ?? 0, nonStandardSizeMailPrice != nil),
            (.letterPackLight, 430, package.longestSide <= 34 && package.middleSide <= 24.8 && package.thickness <= 3 && package.weight <= 4_000),
            (.letterPackPlus, 600, package.longestSide <= 34 && package.middleSide <= 24.8 && package.weight <= 4_000),
            (.smartLetter, 210, package.longestSide <= 25 && package.middleSide <= 17 && package.thickness <= 2 && package.weight <= 1_000),
            (.konekoBin420, 420, package.longestSide <= 34 && package.middleSide <= 24.8 && package.thickness <= 3)
        ]

        let matchingOptions = rules
            .filter { $0.2 }
            .map { ShippingOption(method: $0.0, price: $0.1) }

        return minimumSizedOptions(from: matchingOptions)
            .sorted {
                if $0.price == $1.price {
                    return $0.method.sortOrder < $1.method.sortOrder
                }

                return $0.price < $1.price
            }
    }

    private static func minimumSizedOptions(from options: [ShippingOption]) -> [ShippingOption] {
        let takkyubinOptions = options.filter { $0.method.isTakkyubinSize }
        let yuPackOptions = options.filter { $0.method.isYuPackSize }

        return options.filter { !$0.method.isTakkyubinSize && !$0.method.isYuPackSize }
            + Array(takkyubinOptions.prefix(1))
            + Array(yuPackOptions.prefix(1))
    }

    private static func nonStandardMailStandardSizePrice(
        longestSide: Decimal,
        middleSide: Decimal,
        thickness: Decimal,
        weight: Decimal
    ) -> Decimal? {
        guard longestSide <= 34, middleSide <= 25, thickness <= 3 else {
            return nil
        }

        return price(for: weight, tiers: [
            (50, 140),
            (100, 180),
            (150, 270),
            (250, 320),
            (500, 510),
            (1_000, 750)
        ])
    }

    private static func nonStandardMailNonStandardSizePrice(totalSize: Decimal, weight: Decimal) -> Decimal? {
        guard totalSize <= 90 else {
            return nil
        }

        return price(for: weight, tiers: [
            (50, 260),
            (100, 290),
            (150, 390),
            (250, 450),
            (500, 660),
            (1_000, 920),
            (2_000, 1_350),
            (4_000, 1_750)
        ])
    }

    private static func price(for weight: Decimal, tiers: [(maxWeight: Decimal, price: Decimal)]) -> Decimal? {
        tiers.first { weight <= $0.maxWeight }?.price
    }
}

private extension ShippingMethod {
    var isTakkyubinSize: Bool {
        switch self {
        case .takkyubin60, .takkyubin80, .takkyubin100, .takkyubin120, .takkyubin140, .takkyubin160, .takkyubin180, .takkyubin200:
            return true
        default:
            return false
        }
    }

    var isYuPackSize: Bool {
        switch self {
        case .yuPack60, .yuPack80, .yuPack100, .yuPack120, .yuPack140, .yuPack160, .yuPack170:
            return true
        default:
            return false
        }
    }
}
