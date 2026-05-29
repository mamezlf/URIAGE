import Foundation
import SwiftData

@Model
final class ShippingPreset {
    var title: String
    var length: Decimal
    var width: Decimal
    var height: Decimal
    var weight: Decimal
    var createdAt: Date

    init(title: String, length: Decimal, width: Decimal, height: Decimal, weight: Decimal) {
        self.title = title
        self.length = length
        self.width = width
        self.height = height
        self.weight = weight
        self.createdAt = Date()
    }

    var subtitle: String {
        "\(length.displayText) x \(width.displayText) x \(height.displayText) / \(weight.displayText)g"
    }
}
