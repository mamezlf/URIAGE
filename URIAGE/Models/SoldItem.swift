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
        category: Category(name: "ファッション"),
        salePrice: 3_000,
        purchaseCost: 1_200,
        shippingCost: 210,
        platformFee: 300,
        packagingCost: 0,
        otherCosts: 0,
        tags: "サンプル, メルカリ",
        memo: "販売記録のサンプル"
    )
}
#endif
