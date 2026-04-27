//
//  SoldItem.swift
//  URIAGE
//
//  Created by Codex on 2026/04/26.
//

import Foundation
import SwiftData

@Model
final class SoldItem {
    var id: UUID
    var title: String
    var categoryName: String
    var salePrice: Decimal
    var quantity: Int = 1
    var purchaseCost: Decimal
    var shippingCost: Decimal
    var platformFee: Decimal
    var packagingCost: Decimal
    var inventoryPackagingCost: Decimal = 0
    var otherCosts: Decimal
    var soldAt: Date
    var tags: String?
    var memo: String?
    var sourceURL: String?

    var category: Category {
        get {
            Category(name: categoryName)
        }
        set {
            categoryName = newValue.name
        }
    }

    init(
        id: UUID = UUID(),
        title: String,
        category: Category = .uncategorized,
        salePrice: Decimal,
        quantity: Int = 1,
        purchaseCost: Decimal = 0,
        shippingCost: Decimal = 0,
        platformFee: Decimal = 0,
        packagingCost: Decimal = 0,
        inventoryPackagingCost: Decimal = 0,
        otherCosts: Decimal = 0,
        soldAt: Date = Date(),
        tags: String? = nil,
        memo: String? = nil,
        sourceURL: String? = nil
    ) {
        self.id = id
        self.title = title
        self.categoryName = category.name
        self.salePrice = salePrice
        self.quantity = quantity
        self.purchaseCost = purchaseCost
        self.shippingCost = shippingCost
        self.platformFee = platformFee
        self.packagingCost = packagingCost
        self.inventoryPackagingCost = inventoryPackagingCost
        self.otherCosts = otherCosts
        self.soldAt = soldAt
        self.tags = tags
        self.memo = memo
        self.sourceURL = sourceURL
    }

    var netIncome: Decimal {
        salePrice - platformFee - shippingCost
    }

    var totalCost: Decimal {
        ProfitCalculator.totalCost(
            purchaseCost: purchaseCost,
            shippingCost: shippingCost,
            platformFee: platformFee,
            packagingCost: packagingCost,
            otherCosts: otherCosts
        )
    }

    var profit: Decimal {
        ProfitCalculator.profit(
            salePrice: salePrice,
            purchaseCost: purchaseCost,
            shippingCost: shippingCost,
            platformFee: platformFee,
            packagingCost: packagingCost,
            otherCosts: otherCosts
        )
    }

    var profitRate: Decimal? {
        ProfitCalculator.profitRate(profit: profit, salePrice: salePrice)
    }

    var directPackagingCost: Decimal {
        max(packagingCost - inventoryPackagingCost, 0)
    }
}

#if DEBUG
extension SoldItem {
    static let sample = SoldItem(
        title: "メルカリ サンプル商品",
        category: Category.samples[0],
        salePrice: 3_000,
        purchaseCost: 1_200,
        shippingCost: 210,
        platformFee: 300,
        packagingCost: 0,
        otherCosts: 0,
        tags: "サンプル, メルカリ",
        memo: "販売記録のサンプル"
    )

    static let samples: [SoldItem] = [
        SoldItem(
            title: "Nike パーカー",
            category: Category.samples[0],
            salePrice: 4_200,
            purchaseCost: 1_800,
            shippingCost: 750,
            platformFee: 420,
            packagingCost: 80,
            soldAt: sampleDate(day: 25),
            tags: "ファッション, パーカー",
            memo: "状態良好"
        ),
        SoldItem(
            title: "iPhoneケース セット",
            category: Category.samples[1],
            salePrice: 2_100,
            purchaseCost: 650,
            shippingCost: 210,
            platformFee: 210,
            packagingCost: 60,
            soldAt: sampleDate(day: 21),
            tags: "スマホ, アクセサリー"
        ),
        SoldItem(
            title: "デザイン書籍",
            category: Category.samples[2],
            salePrice: 1_800,
            purchaseCost: 500,
            shippingCost: 450,
            platformFee: 180,
            packagingCost: 40,
            soldAt: sampleDate(day: 18),
            tags: "本"
        ),
        SoldItem(
            title: "陶器マグ セット",
            category: Category.samples[3],
            salePrice: 2_600,
            purchaseCost: 900,
            shippingCost: 750,
            platformFee: 260,
            packagingCost: 150,
            otherCosts: 120,
            soldAt: sampleDate(day: 10),
            tags: "ホーム, 割れ物"
        ),
        SoldItem(
            title: "ヴィンテージシャツ",
            category: Category.samples[0],
            salePrice: 3_500,
            purchaseCost: 1_500,
            shippingCost: 450,
            platformFee: 350,
            packagingCost: 70,
            soldAt: sampleDate(monthOffset: -1, day: 28),
            tags: "ファッション, ヴィンテージ"
        )
    ]

    private static func sampleDate(monthOffset: Int = 0, day: Int) -> Date {
        let calendar = Calendar.current
        let now = Date()
        let targetMonth = calendar.date(byAdding: .month, value: monthOffset, to: now) ?? now
        let components = calendar.dateComponents([.year, .month], from: targetMonth)

        return calendar.date(
            from: DateComponents(
                year: components.year,
                month: components.month,
                day: day,
                hour: 12
            )
        ) ?? now
    }
}
#endif
