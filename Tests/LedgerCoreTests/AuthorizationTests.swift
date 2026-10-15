import XCTest
@testable import LedgerCore

final class AuthorizationTests: XCTestCase {
    func testApprovedHoldChangesAvailableNotLedgerBalance() {
        let ledger = Ledger()
        XCTAssertEqual(ledger.apply(event("E1", 1, 1, .credit(aed(1_200_00)))), .accepted)
        XCTAssertEqual(ledger.apply(event("E2", 2, 1, .debit(aed(950_00)))), .accepted)
        XCTAssertEqual(ledger.apply(event("E3", 3, 2, .authorization(id: "Auth-A", hold: aed(200_00)))), .accepted)

        let snapshot = ledger.snapshot(afterArrival: 3)
        XCTAssertEqual(snapshot.ledgerBalances[.acc001], aed(250_00))
        XCTAssertEqual(snapshot.availableBalances[.acc001], aed(50_00))
        XCTAssertEqual(snapshot.authorizations["Auth-A"], .approved)
    }

    func testSettlementUsesApprovedHoldAndReleasesIt() {
        let ledger = Ledger()
        _ = ledger.apply(event("E1", 1, 1, .credit(aed(1_200_00))))
        _ = ledger.apply(event("E2", 2, 1, .debit(aed(950_00))))
        _ = ledger.apply(event("E3", 3, 2, .authorization(id: "Auth-A", hold: aed(200_00))))
        _ = ledger.apply(event("E4", 4, 3, .credit(aed(400_00))))
        XCTAssertEqual(ledger.apply(event("E5", 5, 4, .settlement(id: "Auth-A", amount: aed(185_00)))), .accepted)

        let snapshot = ledger.snapshot(afterArrival: 5)
        XCTAssertEqual(snapshot.ledgerBalances[.acc001], aed(465_00))
        XCTAssertEqual(snapshot.availableBalances[.acc001], aed(465_00))
        XCTAssertEqual(snapshot.authorizations["Auth-A"], .settled)
    }

    func testUnknownAuthorizationRejectsSettlementWithoutDebit() {
        let ledger = Ledger()
        _ = ledger.apply(event("E1", 1, 1, .credit(aed(250_00))))
        let outcome = ledger.apply(event("E6", 6, 4, .settlement(id: "Auth-Z", amount: aed(180_00))))

        XCTAssertEqual(outcome, .rejected("unknown authorization Auth-Z"))
        XCTAssertEqual(ledger.snapshot(afterArrival: 6).ledgerBalances[.acc001], aed(250_00))
        XCTAssertEqual(ledger.processed.count, 2)
    }

    func testDuplicateEventIDIsRejected() {
        let ledger = Ledger()
        _ = ledger.apply(event("E1", 1, 1, .credit(aed(100_00))))
        XCTAssertEqual(ledger.apply(event("E1", 2, 1, .credit(aed(100_00)))), .rejected("duplicate event ID E1"))
        XCTAssertEqual(ledger.snapshot(afterArrival: 2).ledgerBalances[.acc001], aed(100_00))
    }

    private func aed(_ minorUnits: Int64) -> Money {
        Money(currency: .aed, minorUnits: minorUnits)
    }

    private func event(_ id: String, _ arrival: Int, _ day: Int, _ kind: EventKind) -> Event {
        Event(id: id, arrival: arrival, bookedDay: day, valueDay: day, account: .acc001, kind: kind)
    }
}
