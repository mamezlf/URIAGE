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

nonisolated enum SupplyCostCalculator {
    // MARK: - Interval based（集計用の値型。バックグラウンドからも呼べる）

    /// `start <= date < end`（DateInterval.contains は end を含むため使わない）
    static func isDate(_ date: Date, in interval: DateInterval) -> Bool {
        date >= interval.start && date < interval.end
    }

    static func registeredSupplyCost(
        supplies: [SupplyRecord],
        in interval: DateInterval
    ) -> Decimal {
        supplies
            .filter { isDate($0.purchaseDate, in: interval) }
            .reduce(Decimal(0)) { $0 + $1.totalCost }
    }

    static func supplyCost(
        soldItems: [SoldRecord],
        supplies: [SupplyRecord],
        in interval: DateInterval
    ) -> Decimal {
        let directPackagingCost = soldItems
            .filter { isDate($0.soldAt, in: interval) }
            .reduce(Decimal(0)) { $0 + $1.directPackagingCost }

        return registeredSupplyCost(supplies: supplies, in: interval) + directPackagingCost
    }

    static func profitAfterRegisteredSupplyCost(
        soldItems: [SoldRecord],
        supplies: [SupplyRecord],
        in interval: DateInterval
    ) -> Decimal {
        let salesProfit = soldItems
            .filter { isDate($0.soldAt, in: interval) }
            .reduce(Decimal(0)) { $0 + $1.profit }

        return salesProfit - registeredSupplyCost(supplies: supplies, in: interval)
    }
}

// MARK: - SwiftData モデル版（ホーム・資材画面など、メインスレッドから直接使う）

@MainActor
extension SupplyCostCalculator {
    static func registeredSupplyCost(_ supplies: [SupplyItem]) -> Decimal {
        supplies.reduce(Decimal(0)) { $0 + $1.totalCost }
    }

    static func registeredSupplyCost(
        supplies: [SupplyItem],
        in interval: DateInterval
    ) -> Decimal {
        registeredSupplyCost(supplies: supplies.map(SupplyRecord.init), in: interval)
    }

    static func supplyCost(
        soldItems: [SoldItem],
        supplies: [SupplyItem],
        in interval: DateInterval
    ) -> Decimal {
        supplyCost(
            soldItems: soldItems.map(SoldRecord.init),
            supplies: supplies.map(SupplyRecord.init),
            in: interval
        )
    }

    static func profitAfterRegisteredSupplyCost(
        soldItems: [SoldItem],
        supplies: [SupplyItem],
        in interval: DateInterval
    ) -> Decimal {
        profitAfterRegisteredSupplyCost(
            soldItems: soldItems.map(SoldRecord.init),
            supplies: supplies.map(SupplyRecord.init),
            in: interval
        )
    }

    // MARK: - Monthly

    static func monthlyRegisteredSupplyCost(
        supplies: [SupplyItem],
        in month: Date,
        calendar: Calendar = .current
    ) -> Decimal {
        guard let interval = calendar.dateInterval(of: .month, for: month) else {
            return 0
        }

        return registeredSupplyCost(supplies: supplies, in: interval)
    }

    static func monthlySupplyCost(
        soldItems: [SoldItem],
        supplies: [SupplyItem],
        in month: Date,
        calendar: Calendar = .current
    ) -> Decimal {
        guard let interval = calendar.dateInterval(of: .month, for: month) else {
            return 0
        }

        return supplyCost(soldItems: soldItems, supplies: supplies, in: interval)
    }

    static func monthlyProfitAfterRegisteredSupplyCost(
        soldItems: [SoldItem],
        supplies: [SupplyItem],
        in month: Date,
        calendar: Calendar = .current
    ) -> Decimal {
        guard let interval = calendar.dateInterval(of: .month, for: month) else {
            return 0
        }

        return profitAfterRegisteredSupplyCost(soldItems: soldItems, supplies: supplies, in: interval)
    }
}
