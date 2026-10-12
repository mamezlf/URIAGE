//
//  MonthlyReport.swift
//  URIAGE
//
//  月次レポート用の集計：サマリーと利益上位5件
//

import Foundation

nonisolated struct MonthlyReport: Sendable {
    let sales: Decimal
    /// 販売利益 − その月に購入した資材費
    let profit: Decimal
    let supplyCost: Decimal
    let soldCount: Int
    let topProfitItems: [SoldRecord]

    var isEmpty: Bool { soldCount == 0 }

    init(month: Date, input: ReportInput, calendar: Calendar = .current) {
        guard let interval = calendar.dateInterval(of: .month, for: month) else {
            sales = 0
            profit = 0
            supplyCost = 0
            soldCount = 0
            topProfitItems = []
            return
        }

        let monthItems = input.soldItems.filter { SupplyCostCalculator.isDate($0.soldAt, in: interval) }

        sales = monthItems.reduce(0) { $0 + $1.salePrice }
        profit = SupplyCostCalculator.profitAfterRegisteredSupplyCost(
            soldItems: monthItems,
            supplies: input.supplies,
            in: interval
        )
        supplyCost = SupplyCostCalculator.supplyCost(
            soldItems: monthItems,
            supplies: input.supplies,
            in: interval
        )
        soldCount = monthItems.count
        topProfitItems = Array(monthItems.sorted { $0.profit > $1.profit }.prefix(5))
    }
}
