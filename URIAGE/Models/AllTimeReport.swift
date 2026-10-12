//
//  AllTimeReport.swift
//  URIAGE
//
//  「すべて」レポート：最初の記録から今年までを年ごとに集計する
//

import Foundation

struct AllTimeReport {
    static let minimumYearCount = 5

    struct Year: Identifiable, Equatable {
        let year: Int
        let start: Date
        var sales: Decimal = 0
        var itemProfit: Decimal = 0
        var registeredSupplyCost: Decimal = 0
        var directPackagingCost: Decimal = 0
        var soldCount: Int = 0

        var id: Int { year }
        var label: String { "\(year)年" }

        /// 月次・年次と同じ定義：販売利益 − 購入した資材費
        var profit: Decimal { itemProfit - registeredSupplyCost }
        var supplyCost: Decimal { registeredSupplyCost + directPackagingCost }
    }

    /// 古い年 → 新しい年。記録がなければ空
    let years: [Year]
    let topProfitItems: [SoldItem]

    init(
        soldItems: [SoldItem],
        supplies: [SupplyItem],
        now: Date = Date(),
        calendar: Calendar = .current
    ) {
        let dates = soldItems.map(\.soldAt) + supplies.map(\.purchaseDate)
        guard let earliest = dates.min() else {
            years = []
            topProfitItems = []
            return
        }

        let currentYear = calendar.component(.year, from: now)
        // 推移が分かるように最低 5 年分（今年を含む）は並べる。記録のない年は 0 のまま
        let firstYear = min(calendar.component(.year, from: earliest), currentYear - (Self.minimumYearCount - 1))
        let lastYear = max(currentYear, calendar.component(.year, from: dates.max() ?? now))

        var buckets: [Year] = (firstYear...lastYear).map { year in
            let start = calendar.date(from: DateComponents(year: year, month: 1, day: 1)) ?? earliest
            return Year(year: year, start: start)
        }

        for item in soldItems {
            let i = calendar.component(.year, from: item.soldAt) - firstYear
            buckets[i].sales += item.salePrice
            buckets[i].itemProfit += item.profit
            buckets[i].directPackagingCost += item.directPackagingCost
            buckets[i].soldCount += 1
        }

        for supply in supplies {
            let i = calendar.component(.year, from: supply.purchaseDate) - firstYear
            buckets[i].registeredSupplyCost += supply.totalCost
        }

        years = buckets
        topProfitItems = Array(soldItems.sorted { $0.profit > $1.profit }.prefix(5))
    }

    var sales: Decimal { years.reduce(0) { $0 + $1.sales } }
    var profit: Decimal { years.reduce(0) { $0 + $1.profit } }
    var supplyCost: Decimal { years.reduce(0) { $0 + $1.supplyCost } }
    var soldCount: Int { years.reduce(0) { $0 + $1.soldCount } }
    var isEmpty: Bool { soldCount == 0 }

    /// 利益がいちばん大きかった年（販売のあった年のみ対象）
    var bestYear: Year? {
        years.filter { $0.soldCount > 0 }.max { $0.profit < $1.profit }
    }

    var trendPoints: [ReportTrendPoint] {
        // 年が多いと 4 桁では x 軸に収まらないので短縮する
        let useShortLabel = years.count > 6
        return years.map { year in
            ReportTrendPoint(
                label: year.label,
                axisLabel: useShortLabel ? "'" + String(String(year.year).suffix(2)) : String(year.year),
                start: year.start,
                isFuture: false,
                sales: year.sales,
                profit: year.profit,
                soldCount: year.soldCount
            )
        }
    }

    func trendPoint(for year: Year?) -> ReportTrendPoint? {
        guard let year else { return nil }
        return trendPoints.first { $0.label == year.label }
    }
}
