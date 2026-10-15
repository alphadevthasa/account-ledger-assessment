import Foundation
import XCTest
@testable import LedgerCore

final class HoldExpiryFailingTest: XCTestCase {
    func testUnsettledHoldEventuallyExpires() throws {
        guard ProcessInfo.processInfo.environment["RUN_KNOWN_FAILURE"] == "1" else {
            throw XCTSkip("Set RUN_KNOWN_FAILURE=1 to demonstrate the omitted hold-expiry behavior")
        }

        let ledger = Ledger()
        _ = ledger.apply(Event(id: "C", arrival: 1, bookedDay: 1, valueDay: 1,
                               account: .acc001,
                               kind: .credit(Money(currency: .aed, minorUnits: 10_000))))
        _ = ledger.apply(Event(id: "A", arrival: 2, bookedDay: 1, valueDay: 1,
                               account: .acc001,
                               kind: .authorization(id: "Auth-X", hold: Money(currency: .aed, minorUnits: 8_000))))

        // Intentionally fails: this six-day model has no expiry event or expiry policy.
        // Production must release stale holds at a defined deadline with an auditable event.
        XCTAssertNil(ledger.dailyReport(day: 6).authorizations["Auth-X"])
    }
}
