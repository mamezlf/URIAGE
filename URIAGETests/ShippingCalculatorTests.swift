//
//  ShippingCalculatorTests.swift
//  URIAGETests
//
//  Created by Codex on 2026/04/26.
//

import XCTest
@testable import URIAGE

final class ShippingCalculatorTests: XCTestCase {
    func testReturnsMatchingOptionsSortedByPrice() {
        let options = ShippingCalculator.options(length: 30, width: 20, height: 2, weight: 900)

        XCTAssertEqual(
            options.map(\.method),
            [
                .clickPost,
                .nekopos,
                .yuPacketPost,
                .yuPacket,
                .konekoBin420,
                .letterPackLight,
                .takkyubinCompact,
                .letterPackPlus,
                .takkyubin60,
                .yuPack60,
                .nonStandardMailStandardSize
            ]
        )
        XCTAssertEqual(options.map(\.price), [185, 210, 215, 230, 420, 430, 450, 600, 750, 750, 750])
    }

    func testStandardMailRequiresThinAndLightPackage() {
        let options = ShippingCalculator.options(length: 23, width: 12, height: 1, weight: 50)

        XCTAssertTrue(options.contains { $0.method == .standardMail })
        XCTAssertEqual(options.first?.method, .standardMail)
    }

    func testStandardMailRequiresStandardEnvelopeSize() {
        let options = ShippingCalculator.options(length: 30, width: 12, height: 1, weight: 50)

        XCTAssertFalse(options.contains { $0.method == .standardMail })
    }

    func testYuPacketPostAllowsUpToTwoKilograms() {
        let options = ShippingCalculator.options(length: 34, width: 20, height: 3, weight: 1_500)

        XCTAssertTrue(options.contains { $0.method == .yuPacketPost })
        XCTAssertTrue(options.contains { $0.method == .letterPackLight })
        XCTAssertTrue(options.contains { $0.method == .letterPackPlus })
        XCTAssertTrue(options.contains { $0.method == .konekoBin420 })
        XCTAssertFalse(options.contains { $0.method == .nekopos })
        XCTAssertFalse(options.contains { $0.method == .yuPacket })
        XCTAssertFalse(options.contains { $0.method == .clickPost })
    }

    func testSmallAndThinShippingMethods() {
        let options = ShippingCalculator.options(length: 21.1, width: 16.8, height: 2, weight: 800)
        let methods = options.map(\.method)

        XCTAssertTrue(methods.contains(.yuPacketPostMini))
        XCTAssertTrue(methods.contains(.smartLetter))
        XCTAssertTrue(methods.contains(.takkyubinCompact))
        XCTAssertEqual(options.first?.method, .yuPacketPostMini)
    }

    func testYuPacketPlusAllowsSevenCentimetersThickness() {
        let options = ShippingCalculator.options(length: 24, width: 17, height: 7, weight: 2_000)
        let methods = options.map(\.method)

        XCTAssertTrue(methods.contains(.yuPacketPlus))
        XCTAssertFalse(methods.contains(.letterPackLight))
        XCTAssertFalse(methods.contains(.clickPost))
    }

    func testTakkyubinCompactDoesNotApplyThicknessOverFiveCentimeters() {
        let options = ShippingCalculator.options(length: 24, width: 17, height: 6, weight: 500)

        XCTAssertFalse(options.contains { $0.method == .takkyubinCompact })
    }

    func testTakkyubinAndYuPackLargeSizes() {
        let options = ShippingCalculator.options(length: 50, width: 40, height: 20, weight: 12_000)
        let methods = options.map(\.method)

        XCTAssertFalse(methods.contains(.takkyubin100))
        XCTAssertTrue(methods.contains(.takkyubin120))
        XCTAssertFalse(methods.contains(.takkyubin140))
        XCTAssertFalse(methods.contains(.takkyubin160))
        XCTAssertFalse(methods.contains(.yuPack100))
        XCTAssertTrue(methods.contains(.yuPack120))
        XCTAssertFalse(methods.contains(.yuPack140))
        XCTAssertFalse(methods.contains(.yuPack160))
        XCTAssertFalse(methods.contains(.yuPack170))
    }

    func testTakkyubinLargeSizesRespectWeightLimits() {
        let options = ShippingCalculator.options(length: 50, width: 40, height: 20, weight: 22_000)
        let methods = options.map(\.method)

        XCTAssertFalse(methods.contains(.takkyubin120))
        XCTAssertFalse(methods.contains(.takkyubin140))
        XCTAssertTrue(methods.contains(.takkyubin160))
        XCTAssertTrue(methods.contains(.yuPack120))
        XCTAssertFalse(methods.contains(.yuPack140))
        XCTAssertFalse(methods.contains(.yuPack160))
        XCTAssertFalse(methods.contains(.yuPack170))
    }

    func testKeepsOnlyMinimumAvailableSizeForEachDeliverySeries() {
        let options = ShippingCalculator.options(length: 70, width: 30, height: 20, weight: 1_000)
        let methods = options.map(\.method)

        XCTAssertTrue(methods.contains(.takkyubin120))
        XCTAssertFalse(methods.contains(.takkyubin140))
        XCTAssertFalse(methods.contains(.takkyubin160))
        XCTAssertTrue(methods.contains(.yuPack120))
        XCTAssertFalse(methods.contains(.yuPack140))
        XCTAssertFalse(methods.contains(.yuPack160))
        XCTAssertFalse(methods.contains(.yuPack170))
    }

    func testYuPack170RequiresSizeWithinOneHundredSeventyCentimeters() {
        let options = ShippingCalculator.options(length: 100, width: 50, height: 30, weight: 1_000)

        XCTAssertFalse(options.contains { $0.method == .yuPack170 })
    }

    func testTakkyubinSupportsOneHundredEightyAndTwoHundredSizes() {
        let options = ShippingCalculator.options(length: 100, width: 55, height: 35, weight: 28_000)
        let methods = options.map(\.method)

        XCTAssertTrue(methods.contains(.takkyubin200))
        XCTAssertFalse(methods.contains(.takkyubin180))
        XCTAssertFalse(methods.contains(.yuPack170))
    }

    func testNonStandardMailStandardSizeUsesWeightTiers() {
        let options = ShippingCalculator.options(length: 34, width: 25, height: 3, weight: 500)

        XCTAssertTrue(options.contains { $0.method == .nonStandardMailStandardSize && $0.price == 510 })
        XCTAssertFalse(options.contains { $0.method == .nonStandardMailNonStandardSize })
    }

    func testNonStandardMailNonStandardSizeUsesWeightTiers() {
        let options = ShippingCalculator.options(length: 35, width: 25, height: 20, weight: 2_000)

        XCTAssertTrue(options.contains { $0.method == .nonStandardMailNonStandardSize && $0.price == 1_350 })
        XCTAssertFalse(options.contains { $0.method == .nonStandardMailStandardSize })
    }

    func testOversizedPackageReturnsNoOptions() {
        let options = ShippingCalculator.options(length: 120, width: 60, height: 30, weight: 1_000)

        XCTAssertTrue(options.isEmpty)
    }

    func testInvalidInputReturnsNoOptions() {
        let options = ShippingCalculator.options(length: 0, width: 20, height: 2, weight: 100)

        XCTAssertTrue(options.isEmpty)
    }
}
