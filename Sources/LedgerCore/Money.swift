import Foundation

public enum Currency: String, CaseIterable, Sendable {
    case aed = "AED"
    case bhd = "BHD"

    public var precision: Int { self == .aed ? 2 : 3 }
    public var scale: Int64 { self == .aed ? 100 : 1_000 }
}

public enum MoneyError: Error, Equatable {
    case invalidSplit
    case currencyMismatch
    case overflow
}

public struct Money: Equatable, Sendable, CustomStringConvertible {
    public let currency: Currency
    public let minorUnits: Int64

    public init(currency: Currency, minorUnits: Int64) {
        self.currency = currency
        self.minorUnits = minorUnits
    }

    public var description: String {
        let magnitude = minorUnits.magnitude
        let scale = UInt64(currency.scale)
        let whole = magnitude / scale
        let fraction = magnitude % scale
        let sign = minorUnits < 0 ? "-" : ""
        let paddedFraction = String(fraction).leftPadding(to: currency.precision)
        return "\(currency.rawValue) \(sign)\(whole).\(paddedFraction)"
    }

    public func split(count: Int) throws -> [Money] {
        guard minorUnits > 0, count > 0 else { throw MoneyError.invalidSplit }
        let divisor = Int64(count)
        let quotient = minorUnits / divisor
        let remainder = minorUnits % divisor
        return (0..<count).map { index in
            Money(currency: currency, minorUnits: quotient + (Int64(index) < remainder ? 1 : 0))
        }
    }

    public func adding(_ other: Money) throws -> Money {
        guard currency == other.currency else { throw MoneyError.currencyMismatch }
        let (result, overflow) = minorUnits.addingReportingOverflow(other.minorUnits)
        guard !overflow else { throw MoneyError.overflow }
        return Money(currency: currency, minorUnits: result)
    }
}

private extension String {
    func leftPadding(to width: Int) -> String {
        String(repeating: "0", count: max(0, width - count)) + self
    }
}
