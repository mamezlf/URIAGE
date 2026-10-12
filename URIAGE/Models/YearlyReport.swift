//
//  YearlyReport.swift
//  URIAGE
//
//  年次レポート用の集計。販売記録と資材を一度だけ走査して 12 か月のバケットに振り分ける。
//

import Foundation

nonisolated struct YearlyReport: Sendable {
    nonisolated struct Month: Identifiable, Equatable, Sendable {
        /// 1...12
        let index: Int
        let start: Date
        let isFuture: Bool
        var sales: Decimal = 0
        var itemProfit: Decimal = 0
        var registeredSupplyCost: Decimal = 0
        var directPackagingCost: Decimal = 0
        var soldCount: Int = 0

        var id: Int { index }
        var label: String { "\(index)月" }

        /// 月次レポートと同じ定義：販売利益 − その月に購入した資材費
        var profit: Decimal { itemProfit - registeredSupplyCost }
        var supplyCost: Decimal { registeredSupplyCost + directPackagingCost }
    }

    nonisolated struct PeriodTotals: Equatable, Sendable {
        let sales: Decimal
        let profit: Decimal
    }

    let yearStart: Date
    let months: [Month]
    let isCurrentYear: Bool
    /// 今年なら経過した月数（10月なら 10）、過去の年なら 12
    let elapsedMonthCount: Int
    /// 今年は前年の同じ期間（1/1〜前年の今日）、過去の年は前年通年。前年に販売がなければ nil
    let previousPeriod: PeriodTotals?
    let topProfitItems: [SoldRecord]

    init(
        year: Date,
        input: ReportInput,
        now: Date = Date(),
        calendar: Calendar = .current
    ) {
        let soldItems = input.soldItems
        let supplies = input.supplies

        let yearInterval = calendar.dateInterval(of: .year, for: year)
            ?? DateInterval(start: year, duration: 0)
        yearStart = yearInterval.start

        isCurrentYear = SupplyCostCalculator.isDate(now, in: yearInterval)
        elapsedMonthCount = isCurrentYear ? calendar.component(.month, from: now) : 12

        var buckets: [Month] = (0..<12).map { offset in
            let start = calendar.date(byAdding: .month, value: offset, to: yearInterval.start)
                ?? yearInterval.start
            return Month(index: offset + 1, start: start, isFuture: start > now)
        }

        var yearItems: [SoldRecord] = []
        for item in soldItems where SupplyCostCalculator.isDate(item.soldAt, in: yearInterval) {
            let i = calendar.component(.month, from: item.soldAt) - 1
            buckets[i].sales += item.salePrice
            buckets[i].itemProfit += item.profit
            buckets[i].directPackagingCost += item.directPackagingCost
            buckets[i].soldCount += 1
            yearItems.append(item)
        }

        for supply in supplies where SupplyCostCalculator.isDate(supply.purchaseDate, in: yearInterval) {
            let i = calendar.component(.month, from: supply.purchaseDate) - 1
            buckets[i].registeredSupplyCost += supply.totalCost
        }

        months = buckets
        topProfitItems = Array(yearItems.sorted { $0.profit > $1.profit }.prefix(5))

        // 前年比：今年はまだ途中なので、前年の「同じ期間」と比べる
        if let previousStart = calendar.date(byAdding: .year, value: -1, to: yearInterval.start),
           let previousEnd = isCurrentYear
               ? calendar.date(byAdding: .year, value: -1, to: now)
               : yearInterval.start,
           previousEnd > previousStart {
            let interval = DateInterval(start: previousStart, end: previousEnd)
            let previousItems = soldItems.filter { SupplyCostCalculator.isDate($0.soldAt, in: interval) }
            if previousItems.isEmpty {
                previousPeriod = nil
            } else {
                previousPeriod = PeriodTotals(
                    sales: previousItems.reduce(0) { $0 + $1.salePrice },
                    profit: SupplyCostCalculator.profitAfterRegisteredSupplyCost(
                        soldItems: previousItems,
                        supplies: supplies,
                        in: interval
                    )
                )
            }
        } else {
            previousPeriod = nil
        }
    }

    var sales: Decimal { months.reduce(0) { $0 + $1.sales } }
    var profit: Decimal { months.reduce(0) { $0 + $1.profit } }
    var supplyCost: Decimal { months.reduce(0) { $0 + $1.supplyCost } }
    var soldCount: Int { months.reduce(0) { $0 + $1.soldCount } }
    var isEmpty: Bool { soldCount == 0 }

    /// 利益がいちばん大きかった月（販売のあった月のみ対象）
    var bestMonth: Month? {
        months.filter { $0.soldCount > 0 }.max { $0.profit < $1.profit }
    }

    var salesChangeRate: Decimal? {
        Self.changeRate(current: sales, previous: previousPeriod?.sales)
    }

    var profitChangeRate: Decimal? {
        Self.changeRate(current: profit, previous: previousPeriod?.profit)
    }

    /// 前の値が 0 以下だと増減率に意味がないので nil
    static func changeRate(current: Decimal, previous: Decimal?) -> Decimal? {
        guard let previous, previous > 0 else { return nil }
        return (current - previous) / previous
    }

    var trendPoints: [ReportTrendPoint] {
        months.map { month in
            ReportTrendPoint(
                label: month.label,
                axisLabel: "\(month.index)",
                start: month.start,
                isFuture: month.isFuture,
                sales: month.sales,
                profit: month.profit,
                soldCount: month.soldCount
            )
        }
    }

    var bestTrendPoint: ReportTrendPoint? {
        guard let bestMonth else { return nil }
        return trendPoints.first { $0.label == bestMonth.label }
    }
}

// MARK: - SwiftData モデルから直接集計する（テスト・メインスレッド用）

extension YearlyReport {
    @MainActor
    init(
        year: Date,
        soldItems: [SoldItem],
        supplies: [SupplyItem],
        now: Date = Date(),
        calendar: Calendar = .current
    ) {
        self.init(
            year: year,
            input: ReportInput(items: soldItems, supplies: supplies),
            now: now,
            calendar: calendar
        )
    }
}
