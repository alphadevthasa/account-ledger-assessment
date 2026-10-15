import XCTest
@testable import LedgerCore

final class MoneyTests: XCTestCase {
    func testAEDIsStoredInMinorUnits() {
        let amount = Money(currency: .aed, minorUnits: 100_000)
        XCTAssertEqual(amount.minorUnits, 100_000)
        XCTAssertEqual(amount.description, "AED 1000.00")
    }

    func testBHDInstallmentsConserveTotal() throws {
        let amount = Money(currency: .bhd, minorUnits: 10_000)
        let parts = try amount.split(count: 3)
        XCTAssertEqual(parts.map(\.minorUnits), [3_334, 3_333, 3_333])
        XCTAssertEqual(parts.reduce(Int64.zero) { $0 + $1.minorUnits }, amount.minorUnits)
    }

    func testZeroAmountCannotBeSplit() {
        XCTAssertThrowsError(try Money(currency: .bhd, minorUnits: 0).split(count: 3))
    }

    func testZeroInstallmentCountIsInvalid() {
        XCTAssertThrowsError(try Money(currency: .bhd, minorUnits: 10_000).split(count: 0))
    }
}
