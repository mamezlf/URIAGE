//
//  ProfitCalculator.swift
//  URIAGE
//
//  Created by Codex on 2026/04/26.
//

import Foundation

enum ProfitCalculator {
    static func totalCost(
        purchaseCost: Decimal,
        shippingCost: Decimal,
        platformFee: Decimal,
        packagingCost: Decimal,
        otherCosts: Decimal
    ) -> Decimal {
        purchaseCost + shippingCost + platformFee + packagingCost + otherCosts
    }

    static func profit(
        salePrice: Decimal,
        purchaseCost: Decimal,
        shippingCost: Decimal,
        platformFee: Decimal,
        packagingCost: Decimal,
        otherCosts: Decimal
    ) -> Decimal {
        salePrice - totalCost(
            purchaseCost: purchaseCost,
            shippingCost: shippingCost,
            platformFee: platformFee,
            packagingCost: packagingCost,
            otherCosts: otherCosts
        )
    }

    static func profitRate(profit: Decimal, salePrice: Decimal) -> Decimal? {
        guard salePrice != 0 else {
            return nil
        }

        return profit / salePrice
    }
}
