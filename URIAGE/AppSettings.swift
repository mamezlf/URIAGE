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

    func string(from value: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currencyCode
        formatter.maximumFractionDigits = 0
        return formatter.string(from: value as NSDecimalNumber) ?? "\(currencyCode) 0"
    }
}

enum AppDateFormatter {
    static func dateString(from date: Date) -> String {
        date.formatted(.dateTime.year().month().day().locale(Locale(identifier: "ja_JP")))
    }

    static func monthString(from date: Date) -> String {
        date.formatted(.dateTime.year().month(.wide).locale(Locale(identifier: "ja_JP")))
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
