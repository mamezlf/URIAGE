//
//  AllTimeReportTests.swift
//  URIAGETests
//

import XCTest
@testable import URIAGE

final class AllTimeReportTests: XCTestCase {
    private let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Tokyo")!
        return calendar
    }()

    func testBucketsByYearFromFirstRecordToCurrentYear() {
        let items = [
            SoldItem(title: "2024", salePrice: 1_000, purchaseCost: 200, soldAt: date(2024, 5, 1)),
            SoldItem(title: "2026", salePrice: 3_000, purchaseCost: 500, soldAt: date(2026, 2, 1))
        ]
        let supplies = [
            SupplyItem(name: "箱", totalCost: 300, quantity: 10, purchaseDate: date(2026, 1, 10))
        ]

        let report = AllTimeReport(soldItems: items, supplies: supplies, now: date(2026, 10, 12), calendar: calendar)

        // 記録は 2024 年からでも、最低 5 年分（2022〜2026）並ぶ
        XCTAssertEqual(report.years.map(\.year), [2022, 2023, 2024, 2025, 2026])
        XCTAssertEqual(report.years[0].sales, 0)
        XCTAssertEqual(report.years[1].soldCount, 0)
        XCTAssertEqual(report.years[2].profit, 800)
        XCTAssertEqual(report.years[3].soldCount, 0)
        XCTAssertEqual(report.years[4].profit, 2_500 - 300)
        XCTAssertEqual(report.sales, 4_000)
        XCTAssertEqual(report.bestYear?.year, 2026)
    }

    func testAllTimeProfitMatchesSumOfYearlyReports() {
        let items = [
            SoldItem(title: "a", salePrice: 1_200, purchaseCost: 300, packagingCost: 65, soldAt: date(2025, 3, 1)),
            SoldItem(title: "b", salePrice: 2_400, purchaseCost: 900, soldAt: date(2026, 7, 1))
        ]
        let supplies = [
            SupplyItem(name: "封筒", totalCost: 500, quantity: 5, purchaseDate: date(2025, 4, 1))
        ]
        let now = date(2026, 10, 12)

        let report = AllTimeReport(soldItems: items, supplies: supplies, now: now, calendar: calendar)
        let yearlySum = [2025, 2026].reduce(Decimal(0)) { sum, year in
            sum + YearlyReport(year: date(year, 1, 1), soldItems: items, supplies: supplies, now: now, calendar: calendar).profit
        }

        XCTAssertEqual(report.profit, yearlySum)
    }

    func testKeepsAllYearsWhenRecordsAreOlderThanFiveYears() {
        let items = [SoldItem(title: "古い", salePrice: 500, soldAt: date(2019, 6, 1))]
        let report = AllTimeReport(soldItems: items, supplies: [], now: date(2026, 10, 12), calendar: calendar)

        XCTAssertEqual(report.years.first?.year, 2019)
        XCTAssertEqual(report.years.last?.year, 2026)
        XCTAssertEqual(report.years.count, 8)
    }

    func testEmptyWhenNoRecords() {
        let report = AllTimeReport(soldItems: [], supplies: [], calendar: calendar)
        XCTAssertTrue(report.isEmpty)
        XCTAssertTrue(report.years.isEmpty)
        XCTAssertNil(report.bestYear)
    }

    private func date(_ year: Int, _ month: Int, _ day: Int) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day, hour: 12))!
    }
}
