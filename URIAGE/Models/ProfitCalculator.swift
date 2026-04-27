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

enum SupplyCostCalculator {
    static func monthlySupplyCost(
        soldItems: [SoldItem],
        supplies: [SupplyItem],
        in month: Date,
        calendar: Calendar = .current
    ) -> Decimal {
        guard let interval = calendar.dateInterval(of: .month, for: month) else {
            return 0
        }

        let supplyPurchaseCost = supplies
            .filter { $0.purchaseDate >= interval.start && $0.purchaseDate < interval.end }
            .reduce(Decimal(0)) { $0 + $1.totalCost }

        let directPackagingCost = soldItems
            .filter { $0.soldAt >= interval.start && $0.soldAt < interval.end }
            .reduce(Decimal(0)) { $0 + $1.directPackagingCost }

        return supplyPurchaseCost + directPackagingCost
    }
}
