import Foundation

extension Decimal {
    var displayText: String {
        let number = NSDecimalNumber(decimal: self)
        return number.stringValue
    }
}
