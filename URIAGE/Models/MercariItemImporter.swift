//
//  MercariItemImporter.swift
//  URIAGE
//
//  Created by Codex on 2026/04/27.
//

import Foundation

struct MercariItemImportResult: Equatable, Hashable, Identifiable {
    let itemID: String
    let url: URL
    let title: String?
    let price: Decimal?

    var id: String {
        itemID
    }
}

enum MercariItemImportError: LocalizedError {
    case invalidURL
    case unsupportedURL
    case downloadFailed

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Mercariのリンクを入力してください。"
        case .unsupportedURL:
            return "jp.mercari.com/item/ 形式のリンクを入力してください。"
        case .downloadFailed:
            return "商品ページを読み込めませんでした。リンクを保存して、商品名と価格を手入力してください。"
        }
    }
}

enum MercariItemImporter {
    static func fetch(from input: String) async throws -> MercariItemImportResult {
        let normalized = try normalize(input)
        let data: Data
        do {
            let response = try await URLSession.shared.data(for: request(for: normalized.url))
            data = response.0
        } catch {
            throw MercariItemImportError.downloadFailed
        }

        guard let html = String(data: data, encoding: .utf8) ?? String(data: data, encoding: .shiftJIS) else {
            throw MercariItemImportError.downloadFailed
        }

        return parse(html: html, fallback: normalized)
    }

    static func normalize(_ input: String) throws -> MercariItemImportResult {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let url = URL(string: trimmed), let host = url.host(percentEncoded: false) else {
            throw MercariItemImportError.invalidURL
        }

        guard host == "jp.mercari.com" || host == "www.mercari.com" else {
            throw MercariItemImportError.unsupportedURL
        }

        let pathComponents = url.pathComponents
        guard let itemIndex = pathComponents.firstIndex(of: "item"),
              pathComponents.indices.contains(itemIndex + 1) else {
            throw MercariItemImportError.unsupportedURL
        }

        let itemID = pathComponents[itemIndex + 1]
        guard itemID.range(of: #"^m\d+$"#, options: .regularExpression) != nil else {
            throw MercariItemImportError.unsupportedURL
        }

        var components = URLComponents()
        components.scheme = "https"
        components.host = "jp.mercari.com"
        components.path = "/item/\(itemID)"

        guard let canonicalURL = components.url else {
            throw MercariItemImportError.invalidURL
        }

        return MercariItemImportResult(itemID: itemID, url: canonicalURL, title: nil, price: nil)
    }

    static func parse(html: String, fallback: MercariItemImportResult) -> MercariItemImportResult {
        let metaTitle = metaContent(named: "og:title", in: html) ?? metaContent(named: "twitter:title", in: html)
        let metaDescription = metaContent(named: "og:description", in: html) ?? metaContent(named: "description", in: html)
        let metaPrice = metaContent(named: "product:price:amount", in: html)
        let nextData = nextDataProduct(from: html)
        let jsonLD = jsonLDProduct(from: html)

        return MercariItemImportResult(
            itemID: fallback.itemID,
            url: fallback.url,
            title: cleanTitle(metaTitle ?? nextData.title ?? jsonLD.title),
            price: price(from: metaPrice) ?? nextData.price ?? jsonLD.price ?? prosePrice(from: metaDescription)
        )
    }

    private static func request(for url: URL) -> URLRequest {
        var request = URLRequest(url: url)
        request.timeoutInterval = 15
        request.setValue(
            "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1",
            forHTTPHeaderField: "User-Agent"
        )
        request.setValue("ja-JP,ja;q=0.9,en-US;q=0.6,en;q=0.4", forHTTPHeaderField: "Accept-Language")
        return request
    }

    private static func metaContent(named name: String, in html: String) -> String? {
        let escapedName = NSRegularExpression.escapedPattern(for: name)
        let patterns = [
            #"<meta[^>]+(?:property|name)=["']\#(escapedName)["'][^>]+content=["']([^"']+)["'][^>]*>"#,
            #"<meta[^>]+content=["']([^"']+)["'][^>]+(?:property|name)=["']\#(escapedName)["'][^>]*>"#
        ]

        for pattern in patterns {
            guard let match = firstMatch(pattern: pattern, in: html),
                  match.numberOfRanges >= 2 else {
                continue
            }

            let contentRangeIndex = pattern.contains("content=[\"']([^\"']+)") ? 1 : 2
            guard let range = Range(match.range(at: contentRangeIndex), in: html) else {
                continue
            }

            return htmlUnescaped(String(html[range]))
        }

        return nil
    }

    private static func nextDataProduct(from html: String) -> (title: String?, price: Decimal?) {
        guard let json = scriptContent(id: "__NEXT_DATA__", in: html),
              let data = json.data(using: .utf8),
              let object = try? JSONSerialization.jsonObject(with: data) else {
            return (nil, nil)
        }

        return productValue(from: object)
    }

    private static func jsonLDProduct(from html: String) -> (title: String?, price: Decimal?) {
        let pattern = #"<script[^>]+type=["']application/ld\+json["'][^>]*>(.*?)</script>"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive, .dotMatchesLineSeparators]) else {
            return (nil, nil)
        }

        let range = NSRange(html.startIndex..<html.endIndex, in: html)
        for match in regex.matches(in: html, range: range) {
            guard let contentRange = Range(match.range(at: 1), in: html) else {
                continue
            }

            let json = htmlUnescaped(String(html[contentRange]))
            guard let data = json.data(using: .utf8),
                  let object = try? JSONSerialization.jsonObject(with: data) else {
                continue
            }

            let product = productValue(from: object)
            if product.title != nil || product.price != nil {
                return product
            }
        }

        return (nil, nil)
    }

    private static func scriptContent(id: String, in html: String) -> String? {
        let escapedID = NSRegularExpression.escapedPattern(for: id)
        let pattern = #"<script[^>]+id=["']\#(escapedID)["'][^>]*>(.*?)</script>"#
        guard let match = firstMatch(pattern: pattern, in: html, options: [.caseInsensitive, .dotMatchesLineSeparators]),
              let range = Range(match.range(at: 1), in: html) else {
            return nil
        }

        return htmlUnescaped(String(html[range]))
    }

    private static func productValue(from object: Any) -> (title: String?, price: Decimal?) {
        if let dictionary = object as? [String: Any] {
            let type = dictionary["@type"] as? String
            let hasProductShape = type == "Product" || dictionary["price"] != nil || dictionary["name"] != nil
            if hasProductShape {
                let title = dictionary["name"] as? String ?? dictionary["title"] as? String
                let price = price(from: dictionary["price"])
                    ?? price(from: (dictionary["offers"] as? [String: Any])?["price"])

                if title != nil || price != nil {
                    return (title, price)
                }
            }

            for value in dictionary.values {
                let product = productValue(from: value)
                if product.title != nil || product.price != nil {
                    return product
                }
            }
        }

        if let array = object as? [Any] {
            for value in array {
                let product = productValue(from: value)
                if product.title != nil || product.price != nil {
                    return product
                }
            }
        }

        return (nil, nil)
    }

    private static func price(from value: Any?) -> Decimal? {
        if let decimal = value as? Decimal {
            return decimal
        }

        if let number = value as? NSNumber {
            return number.decimalValue
        }

        if let string = value as? String {
            return price(from: string)
        }

        return nil
    }

    private static func price(from text: String?) -> Decimal? {
        guard let text else {
            return nil
        }

        let normalized = text.replacingOccurrences(of: ",", with: "")
        guard let range = normalized.range(of: #"¥\s*([0-9]+)|([0-9]+)\s*円|([0-9]+)"#, options: .regularExpression) else {
            return nil
        }

        let candidate = normalized[range].filter(\.isNumber)
        guard candidate.isEmpty == false else {
            return nil
        }

        return Decimal(string: String(candidate))
    }

    private static func prosePrice(from text: String?) -> Decimal? {
        guard let text else {
            return nil
        }

        let normalized = text.replacingOccurrences(of: ",", with: "")
        guard let range = normalized.range(of: #"¥\s*([0-9]+)|([0-9]+)\s*円"#, options: .regularExpression) else {
            return nil
        }

        let candidate = normalized[range].filter(\.isNumber)
        guard candidate.isEmpty == false else {
            return nil
        }

        return Decimal(string: String(candidate))
    }

    private static func cleanTitle(_ title: String?) -> String? {
        guard var title = title?.trimmingCharacters(in: .whitespacesAndNewlines), title.isEmpty == false else {
            return nil
        }

        let suffixes = [" - メルカリ", "｜メルカリ", " by メルカリ", " | Mercari", " - Mercari"]
        for suffix in suffixes where title.hasSuffix(suffix) {
            title.removeLast(suffix.count)
        }

        return title.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func firstMatch(
        pattern: String,
        in text: String,
        options: NSRegularExpression.Options = [.caseInsensitive]
    ) -> NSTextCheckingResult? {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: options) else {
            return nil
        }

        return regex.firstMatch(in: text, range: NSRange(text.startIndex..<text.endIndex, in: text))
    }

    private static func htmlUnescaped(_ text: String) -> String {
        var result = text
            .replacingOccurrences(of: "&quot;", with: "\"")
            .replacingOccurrences(of: "&#34;", with: "\"")
            .replacingOccurrences(of: "&#x27;", with: "'")
            .replacingOccurrences(of: "&#39;", with: "'")
            .replacingOccurrences(of: "&amp;", with: "&")
            .replacingOccurrences(of: "&lt;", with: "<")
            .replacingOccurrences(of: "&gt;", with: ">")

        while result.contains("\\/") {
            result = result.replacingOccurrences(of: "\\/", with: "/")
        }

        return result
    }
}
