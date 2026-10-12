//
//  AppSettings.swift
//  URIAGE
//
//  Created by Codex on 2026/04/26.
//

import Foundation

enum AppSettingsKey {
    static let defaultMercariFeeRate = "defaultMercariFeeRate"
    static let defaultShippingCost = "defaultShippingCost"
    static let defaultPackagingCost = "defaultPackagingCost"
    static let currencyCode = "currencyCode"
}

enum AppDefaults {
    static let mercariFeeRate = 0.10
    static let shippingCost = 0.0
    static let packagingCost = 0.0
    static let currencyCode = "JPY"
}

struct AppCurrencyFormatter {
    var currencyCode: String

    /// NumberFormatter の生成は重いので、通貨ごとに 1 つだけ作って使い回す
    /// （一覧の行ごとに作っていたため、タブ切り替え時の描画が遅くなっていた）
    private static var formatters: [String: NumberFormatter] = [:]

    private var formatter: NumberFormatter {
        if let cached = Self.formatters[currencyCode] {
            return cached
        }

        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currencyCode
        formatter.maximumFractionDigits = 0
        Self.formatters[currencyCode] = formatter
        return formatter
    }

    func string(from value: Decimal) -> String {
        formatter.string(from: value as NSDecimalNumber) ?? "\(currencyCode) 0"
    }
}

enum AppDateFormatter {
    private static let locale = Locale(identifier: "ja_JP")
    private static let dateStyle = Date.FormatStyle.dateTime.year().month().day().locale(locale)
    private static let monthStyle = Date.FormatStyle.dateTime.year().month(.wide).locale(locale)
    private static let yearStyle = Date.FormatStyle.dateTime.year().locale(locale)

    static func dateString(from date: Date) -> String {
        date.formatted(dateStyle)
    }

    static func monthString(from date: Date) -> String {
        date.formatted(monthStyle)
    }

    static func yearString(from date: Date) -> String {
        date.formatted(yearStyle)
    }
}

struct AppPercentFormatter {
    private let formatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .percent
        formatter.maximumFractionDigits = 1
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter
    }()

    func string(from value: Decimal?) -> String {
        guard let value else {
            return "-"
        }

        return formatter.string(from: value as NSDecimalNumber) ?? "-"
    }
}

extension Decimal {
    var roundedScale0: Decimal {
        var value = self
        var result = Decimal()
        NSDecimalRound(&result, &value, 0, .plain)
        return result
    }
}
