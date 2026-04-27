//
//  MercariItemImporterTests.swift
//  URIAGETests
//
//  Created by Codex on 2026/04/27.
//

import XCTest
@testable import URIAGE

final class MercariItemImporterTests: XCTestCase {
    func testNormalizeAcceptsSharedMercariItemURL() throws {
        let result = try MercariItemImporter.normalize(
            "https://jp.mercari.com/item/m36144759504?utm_source=ios&utm_medium=share&source_location=share"
        )

        XCTAssertEqual(result.itemID, "m36144759504")
        XCTAssertEqual(result.url.absoluteString, "https://jp.mercari.com/item/m36144759504")
    }

    func testNormalizeRejectsUnsupportedURL() {
        XCTAssertThrowsError(try MercariItemImporter.normalize("https://example.com/item/m36144759504"))
    }

    func testParsesOpenGraphTitleAndPrice() throws {
        let fallback = try MercariItemImporter.normalize("https://jp.mercari.com/item/m36144759504")
        let html = """
        <html>
        <head>
        <meta property="og:title" content="テスト商品 - メルカリ">
        <meta property="og:description" content="価格 ¥1,980 / 商品の説明">
        </head>
        </html>
        """

        let result = MercariItemImporter.parse(html: html, fallback: fallback)

        XCTAssertEqual(result.title, "テスト商品")
        XCTAssertEqual(result.price, 1_980)
    }

    func testParsesMercariProductPriceAmountBeforeDescriptionNumbers() throws {
        let fallback = try MercariItemImporter.normalize("https://jp.mercari.com/item/m36144759504")
        let html = """
        <html>
        <head>
        <meta name="description" content="折り鶴 和柄 26色 78羽 78柄 7.5cm角折り紙使用をメルカリでお得に通販">
        <meta name="product:price:currency" content="JPY">
        <meta name="product:price:amount" content="360">
        <meta property="og:title" content="折り鶴 和柄 26色 78羽 78柄 7.5cm角折り紙使用 by メルカリ">
        </head>
        </html>
        """

        let result = MercariItemImporter.parse(html: html, fallback: fallback)

        XCTAssertEqual(result.title, "折り鶴 和柄 26色 78羽 78柄 7.5cm角折り紙使用")
        XCTAssertEqual(result.price, 360)
    }

    func testParsesMercariSharedExamplesWithTitleNumbers() throws {
        let examples: [(url: String, title: String, price: Decimal)] = [
            (
                "https://jp.mercari.com/item/m88862671213",
                "千羽鶴完成品✨10色グラデーション✨美品",
                2_080
            ),
            (
                "https://jp.mercari.com/item/m34149077627",
                "期間限定価格！iPhone17対応 iFaceケース ホワイト 耐衝撃 新品",
                2_399
            )
        ]

        for example in examples {
            let fallback = try MercariItemImporter.normalize(example.url)
            let html = """
            <html>
            <head>
            <meta name="description" content="\(example.title)をメルカリでお得に通販">
            <meta name="product:price:amount" content="\(NSDecimalNumber(decimal: example.price).stringValue)">
            <meta property="og:title" content="\(example.title) by メルカリ">
            </head>
            </html>
            """

            let result = MercariItemImporter.parse(html: html, fallback: fallback)

            XCTAssertEqual(result.title, example.title)
            XCTAssertEqual(result.price, example.price)
        }
    }

    func testParsesJSONLDWhenMetaIsMissing() throws {
        let fallback = try MercariItemImporter.normalize("https://jp.mercari.com/item/m36144759504")
        let html = """
        <script type="application/ld+json">
        {"@type":"Product","name":"JSON商品","offers":{"price":"2400","priceCurrency":"JPY"}}
        </script>
        """

        let result = MercariItemImporter.parse(html: html, fallback: fallback)

        XCTAssertEqual(result.title, "JSON商品")
        XCTAssertEqual(result.price, 2_400)
    }
}
