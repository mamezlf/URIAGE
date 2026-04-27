//
//  SupplyItem.swift
//  URIAGE
//
//  Created by Codex on 2026/04/26.
//

import Foundation
import SwiftData

@Model
final class SupplyItem {
    var id: UUID
    var name: String
    var type: String
    var totalCost: Decimal
    var quantity: Int
    var remainingQuantity: Int
    var purchaseDate: Date
    var notes: String?

    init(
        id: UUID = UUID(),
        name: String,
        type: String = SupplyItemType.packaging,
        totalCost: Decimal,
        quantity: Int,
        remainingQuantity: Int,
        purchaseDate: Date = Date(),
        notes: String? = nil
    ) {
        self.id = id
        self.name = name
        self.type = type
        self.totalCost = totalCost
        self.quantity = quantity
        self.remainingQuantity = remainingQuantity
        self.purchaseDate = purchaseDate
        self.notes = notes
    }

    var unitCost: Decimal {
        guard quantity > 0 else {
            return 0
        }

        return totalCost / Decimal(quantity)
    }

    var displayType: String {
        SupplyItemType.displayName(for: type)
    }
}

enum SupplyItemType {
    static let packaging = "梱包材"
    static let postage = "切手・送料"
    static let other = "その他"

    static let all = [packaging, postage, other]

    static func displayName(for type: String) -> String {
        switch type {
        case "包装材料":
            return packaging
        case "邮票或邮资":
            return postage
        case "其他":
            return other
        default:
            return type
        }
    }
}
