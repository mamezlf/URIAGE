//
//  Category.swift
//  URIAGE
//
//  Created by Codex on 2026/04/26.
//

import Foundation

struct Category: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var note: String?

    init(
        id: UUID = UUID(),
        name: String,
        note: String? = nil
    ) {
        self.id = id
        self.name = name
        self.note = note
    }

    var displayName: String {
        Self.displayName(for: name)
    }

    static func displayName(for name: String) -> String {
        switch name {
        case "Uncategorized":
            return "未分類"
        case "Fashion":
            return "ファッション"
        case "Electronics":
            return "家電・ガジェット"
        case "Books":
            return "本"
        case "Home":
            return "ホーム"
        default:
            return name
        }
    }
}

extension Category {
    static let uncategorized = Category(name: "未分類")

    static let samples: [Category] = [
        Category(name: "ファッション"),
        Category(name: "家電・ガジェット"),
        Category(name: "本"),
        Category(name: "ホーム")
    ]
}
