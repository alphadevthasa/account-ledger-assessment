import XCTest
@testable import LedgerCore

final class ProjectionTests: XCTestCase {
    func testBackdatedDebitReconcilesEveryNegativeDayAndDeclinesAuthB() {
        let ledger = Ledger()
        replay(eventsThrough: 8, into: ledger)

        XCTAssertEqual(ledger.dailyReport(day: 2, asOfArrival: 7).preFeeBalances[.acc001], aed(-370_00))
        XCTAssertEqual(ledger.dailyReport(day: 2, asOfArrival: 7).closingBalances[.acc001], aed(-395_00))
        XCTAssertEqual(ledger.dailyReport(day: 3, asOfArrival: 7).feeCharges[.acc001], 0)
        XCTAssertEqual(ledger.dailyReport(day: 4, asOfArrival: 7).feeCharges[.acc001], 1)
        XCTAssertEqual(ledger.dailyReport(day: 5, asOfArrival: 7).feeCharges[.acc001], 1)
        XCTAssertEqual(ledger.dailyReport(day: 5, asOfArrival: 8).closingBalances[.acc001], aed(-230_00))
        XCTAssertEqual(ledger.snapshot(afterArrival: 8).authorizations["Auth-B"], .declined)
    }

    func testReversalCompensatesFeesWithoutErasingTheirAuditRecords() {
        let ledger = Ledger()
        replay(eventsThrough: 9, into: ledger)

        XCTAssertEqual(ledger.dailyReport(day: 2, asOfArrival: 9).closingBalances[.acc001], aed(250_00))
        XCTAssertEqual(ledger.dailyReport(day: 4, asOfArrival: 9).closingBalances[.acc001], aed(465_00))
        XCTAssertEqual(ledger.dailyReport(day: 5, asOfArrival: 9).closingBalances[.acc001], aed(465_00))
        for day in [2, 4, 5] {
            let report = ledger.dailyReport(day: day, asOfArrival: 9)
            XCTAssertEqual(report.feeCharges[.acc001], 1)
            XCTAssertEqual(report.feeReversals[.acc001], 1)
        }
        XCTAssertEqual(ledger.snapshot(afterArrival: 9).authorizations["Auth-B"], .declined)
    }

    func testBHDInstallmentsAndDailyInterestCapitalizeExactly() {
        let ledger = Ledger()
        replay(eventsThrough: 10, into: ledger)

        let installmentEntries = ledger.entries.filter { $0.source == .event("E10") }
        XCTAssertEqual(installmentEntries.map(\.minorUnits), [3_334, 3_333, 3_333])
        XCTAssertEqual(ledger.dailyReport(day: 5, asOfArrival: 10).closingBalances[.acc002], bhd(10_000))
        XCTAssertEqual((1...6).map { ledger.dailyReport(day: $0, asOfArrival: 10).interestAccruals[.acc001]!.minorUnits },
                       [10, 10, 26, 19, 19, 19])
        XCTAssertEqual((1...6).map { ledger.dailyReport(day: $0, asOfArrival: 10).interestAccruals[.acc002]!.minorUnits },
                       [0, 0, 0, 0, 4, 4])

        XCTAssertEqual(ledger.capitalizeInterest(on: 6), [aed(103), bhd(8)])
        XCTAssertEqual(ledger.dailyReport(day: 6, asOfArrival: nil).closingBalances[.acc001], aed(466_03))
        XCTAssertEqual(ledger.dailyReport(day: 6, asOfArrival: nil).closingBalances[.acc002], bhd(10_008))
    }

    private func replay(eventsThrough last: Int, into ledger: Ledger) {
        let events: [Event] = [
            event("E1", 1, 1, 1, .acc001, .credit(aed(1_200_00))),
            event("E2", 2, 1, 1, .acc001, .debit(aed(950_00))),
            event("E3", 3, 2, 2, .acc001, .authorization(id: "Auth-A", hold: aed(200_00))),
            event("E4", 4, 3, 3, .acc001, .credit(aed(400_00))),
            event("E5", 5, 4, 4, .acc001, .settlement(id: "Auth-A", amount: aed(185_00))),
            event("E6", 6, 4, 4, .acc001, .settlement(id: "Auth-Z", amount: aed(180_00))),
            event("E7", 7, 5, 2, .acc001, .debit(aed(620_00))),
            event("E8", 8, 5, 5, .acc001, .authorization(id: "Auth-B", hold: aed(90_00))),
            event("E9", 9, 6, 2, .acc001, .reversal(of: "E7")),
            event("E10", 10, 5, 5, .acc002, .installmentCredit(total: bhd(10_000), count: 3)),
        ]
        for item in events.prefix(last) { _ = ledger.apply(item) }
    }

    private func event(_ id: String, _ arrival: Int, _ booked: Int, _ value: Int,
                       _ account: AccountID, _ kind: EventKind) -> Event {
        Event(id: id, arrival: arrival, bookedDay: booked, valueDay: value, account: account, kind: kind)
    }

    private func aed(_ minor: Int64) -> Money { Money(currency: .aed, minorUnits: minor) }
    private func bhd(_ minor: Int64) -> Money { Money(currency: .bhd, minorUnits: minor) }
}
