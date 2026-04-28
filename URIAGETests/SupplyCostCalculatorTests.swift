//
//  SupplyCostCalculatorTests.swift
//  URIAGETests
//
//  Created by Codex on 2026/04/27.
//

import XCTest
@testable import URIAGE

final class SupplyCostCalculatorTests: XCTestCase {
    func testMonthlyRegisteredSupplyCostUsesOnlySupplyPurchaseMonth() {
        let calendar = Calendar(identifier: .gregorian)
        let april = date(year: 2026, month: 4, day: 12, calendar: calendar)
        let may = date(year: 2026, month: 5, day: 2, calendar: calendar)

        let aprilSupply = SupplyItem(
            name: "4月の箱",
            totalCost: 1_200,
            quantity: 20,
            purchaseDate: april
        )
        let maySupply = SupplyItem(
            name: "5月の封筒",
            totalCost: 500,
            quantity: 5,
            purchaseDate: may
        )

        let result = SupplyCostCalculator.monthlyRegisteredSupplyCost(
            supplies: [aprilSupply, maySupply],
            in: april,
            calendar: calendar
        )

        XCTAssertEqual(result, 1_200)
    }

    func testMonthlySupplyCostCombinesBulkPurchasesAndDirectPackaging() {
        let calendar = Calendar(identifier: .gregorian)
        let april = date(year: 2026, month: 4, day: 12, calendar: calendar)
        let may = date(year: 2026, month: 5, day: 2, calendar: calendar)

        let bubbleWrap = SupplyItem(
            name: "プチプチ",
            totalCost: 1_200,
            quantity: 20,
            purchaseDate: april
        )
        let oldBox = SupplyItem(
            name: "先月の箱",
            totalCost: 500,
            quantity: 5,
            purchaseDate: may
        )
        let directBoxSale = SoldItem(
            title: "ゆうゆう専用箱の商品",
            salePrice: 2_000,
            packagingCost: 65,
            soldAt: april
        )
        let inventorySale = SoldItem(
            title: "プチプチ使用商品",
            salePrice: 1_500,
            packagingCost: 60,
            inventoryPackagingCost: 60,
            soldAt: april
        )

        let result = SupplyCostCalculator.monthlySupplyCost(
            soldItems: [directBoxSale, inventorySale],
            supplies: [bubbleWrap, oldBox],
            in: april,
            calendar: calendar
        )

        XCTAssertEqual(result, 1_265)
    }

    func testMonthlyProfitAfterRegisteredSupplyCostSubtractsCurrentMonthSupplies() {
        let calendar = Calendar(identifier: .gregorian)
        let april = date(year: 2026, month: 4, day: 12, calendar: calendar)
        let may = date(year: 2026, month: 5, day: 2, calendar: calendar)

        let aprilSale = SoldItem(
            title: "4月の商品",
            salePrice: 2_000,
            purchaseCost: 500,
            shippingCost: 210,
            platformFee: 200,
            packagingCost: 65,
            soldAt: april
        )
        let maySale = SoldItem(
            title: "5月の商品",
            salePrice: 1_500,
            purchaseCost: 400,
            soldAt: may
        )
        let aprilSupplies = SupplyItem(
            name: "4月の資材",
            totalCost: 300,
            quantity: 10,
            purchaseDate: april
        )
        let maySupplies = SupplyItem(
            name: "5月の資材",
            totalCost: 900,
            quantity: 30,
            purchaseDate: may
        )

        let result = SupplyCostCalculator.monthlyProfitAfterRegisteredSupplyCost(
            soldItems: [aprilSale, maySale],
            supplies: [aprilSupplies, maySupplies],
            in: april,
            calendar: calendar
        )

        XCTAssertEqual(result, 725)
    }

    private func date(year: Int, month: Int, day: Int, calendar: Calendar) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day))!
    }
}
