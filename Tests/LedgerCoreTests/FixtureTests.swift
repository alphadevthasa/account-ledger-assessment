import XCTest
@testable import LedgerCore

final class FixtureTests: XCTestCase {
    func testSuppliedEventStreamAndFinalBalances() {
        let ledger = Ledger()
        XCTAssertEqual(LedgerFixture.events.count, 10)

        let outcomes = LedgerFixture.events.map(ledger.apply)
        XCTAssertTrue(outcomes[0...4].allSatisfy { $0 == .accepted })
        XCTAssertEqual(outcomes[5], .rejected("unknown authorization Auth-Z"))
        XCTAssertTrue(outcomes[6...9].allSatisfy { $0 == .accepted })

        XCTAssertEqual(ledger.dailyReport(day: 1).closingBalances[.acc001], Money(currency: .aed, minorUnits: 25_000))
        XCTAssertEqual(ledger.dailyReport(day: 2).closingBalances[.acc001], Money(currency: .aed, minorUnits: 25_000))
        XCTAssertEqual(ledger.dailyReport(day: 3).closingBalances[.acc001], Money(currency: .aed, minorUnits: 65_000))
        XCTAssertEqual(ledger.dailyReport(day: 4).closingBalances[.acc001], Money(currency: .aed, minorUnits: 46_500))
        XCTAssertEqual(ledger.dailyReport(day: 5).closingBalances[.acc002], Money(currency: .bhd, minorUnits: 10_000))
        XCTAssertEqual(ledger.dailyReport(day: 5).authorizations["Auth-B"], .declined)
        XCTAssertTrue(ledger.dailyReport(day: 4).errors.contains("E6: unknown authorization Auth-Z"))

        XCTAssertEqual(ledger.capitalizeInterest(on: 6), [
            Money(currency: .aed, minorUnits: 103), Money(currency: .bhd, minorUnits: 8)
        ])
        XCTAssertEqual(ledger.dailyReport(day: 6).closingBalances[.acc001], Money(currency: .aed, minorUnits: 46_603))
        XCTAssertEqual(ledger.dailyReport(day: 6).closingBalances[.acc002], Money(currency: .bhd, minorUnits: 10_008))
    }
}
