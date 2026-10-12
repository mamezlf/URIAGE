//
//  YearlyReportTests.swift
//  URIAGETests
//

import XCTest
@testable import URIAGE

final class YearlyReportTests: XCTestCase {
    private let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Tokyo")!
        return calendar
    }()

    func testBucketsItemsAndSuppliesByMonth() {
        let items = [
            SoldItem(title: "1月A", salePrice: 1_000, purchaseCost: 400, soldAt: date(2026, 1, 5)),
            SoldItem(title: "1月B", salePrice: 2_000, purchaseCost: 500, soldAt: date(2026, 1, 31, hour: 23)),
            SoldItem(title: "3月", salePrice: 3_000, purchaseCost: 1_000, soldAt: date(2026, 3, 1)),
            SoldItem(title: "前年", salePrice: 9_999, soldAt: date(2025, 12, 31, hour: 23))
        ]
        let supplies = [
            SupplyItem(name: "箱", totalCost: 300, quantity: 10, purchaseDate: date(2026, 3, 10))
        ]

        let report = YearlyReport(
            year: date(2026, 6, 1),
            soldItems: items,
            supplies: supplies,
            now: date(2026, 12, 31),
            calendar: calendar
        )

        XCTAssertEqual(report.months.count, 12)
        XCTAssertEqual(report.months[0].soldCount, 2)
        XCTAssertEqual(report.months[0].sales, 3_000)
        XCTAssertEqual(report.months[0].profit, 2_100)
        XCTAssertEqual(report.months[1].soldCount, 0)
        XCTAssertEqual(report.months[2].profit, 2_000 - 300)
        XCTAssertEqual(report.sales, 6_000)
        XCTAssertEqual(report.soldCount, 3)
        XCTAssertEqual(report.bestMonth?.index, 1)
    }

    func testYearlyTotalsMatchSumOfMonthlyCalculator() {
        let items = (1...12).map { month in
            SoldItem(
                title: "\(month)月",
                salePrice: Decimal(month * 1_000),
                purchaseCost: 200,
                packagingCost: 65,
                soldAt: date(2025, month, 15)
            )
        }
        let supplies = [
            SupplyItem(name: "封筒", totalCost: 500, quantity: 5, purchaseDate: date(2025, 4, 1)),
            SupplyItem(name: "テープ", totalCost: 250, quantity: 1, purchaseDate: date(2025, 11, 20))
        ]

        let report = YearlyReport(
            year: date(2025, 1, 1),
            soldItems: items,
            supplies: supplies,
            now: date(2026, 10, 12),
            calendar: calendar
        )

        let monthlyProfitSum = (1...12).reduce(Decimal(0)) { sum, month in
            sum + SupplyCostCalculator.monthlyProfitAfterRegisteredSupplyCost(
                soldItems: items, supplies: supplies, in: date(2025, month, 1), calendar: calendar
            )
        }
        let monthlySupplySum = (1...12).reduce(Decimal(0)) { sum, month in
            sum + SupplyCostCalculator.monthlySupplyCost(
                soldItems: items, supplies: supplies, in: date(2025, month, 1), calendar: calendar
            )
        }

        XCTAssertEqual(report.profit, monthlyProfitSum)
        XCTAssertEqual(report.supplyCost, monthlySupplySum)
        XCTAssertFalse(report.isCurrentYear)
        XCTAssertEqual(report.elapsedMonthCount, 12)
    }

    func testCurrentYearComparesWithSamePeriodOfPreviousYear() {
        let items = [
            SoldItem(title: "前年3月", salePrice: 1_000, soldAt: date(2025, 3, 1)),
            SoldItem(title: "前年11月", salePrice: 50_000, soldAt: date(2025, 11, 1)),
            SoldItem(title: "今年3月", salePrice: 1_500, soldAt: date(2026, 3, 1))
        ]

        let report = YearlyReport(
            year: date(2026, 1, 1),
            soldItems: items,
            supplies: [],
            now: date(2026, 10, 12),
            calendar: calendar
        )

        XCTAssertTrue(report.isCurrentYear)
        XCTAssertEqual(report.elapsedMonthCount, 10)
        XCTAssertTrue(report.months[10].isFuture)
        XCTAssertFalse(report.months[9].isFuture)
        // 前年11月は「同期間」に含めない
        XCTAssertEqual(report.previousPeriod?.sales, 1_000)
        XCTAssertEqual(report.salesChangeRate, Decimal(0.5))
    }

    func testNoPreviousPeriodWhenPreviousYearHasNoSales() {
        let report = YearlyReport(
            year: date(2026, 1, 1),
            soldItems: [SoldItem(title: "今年", salePrice: 1_000, soldAt: date(2026, 2, 1))],
            supplies: [],
            now: date(2026, 10, 12),
            calendar: calendar
        )

        XCTAssertNil(report.previousPeriod)
        XCTAssertNil(report.salesChangeRate)
    }

    func testChangeRateIsNilWhenPreviousIsNotPositive() {
        XCTAssertNil(YearlyReport.changeRate(current: 100, previous: 0))
        XCTAssertNil(YearlyReport.changeRate(current: 100, previous: -50))
        XCTAssertEqual(YearlyReport.changeRate(current: 50, previous: 100), Decimal(-0.5))
    }

    private func date(_ year: Int, _ month: Int, _ day: Int, hour: Int = 12) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day, hour: hour))!
    }
}
