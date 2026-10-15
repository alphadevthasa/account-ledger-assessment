import LedgerCore

let ledger = Ledger()
print("Event replay (arrival order; booked day and value day may differ)")
for event in LedgerFixture.events {
    let outcome = ledger.apply(event)
    switch outcome {
    case .accepted:
        print("\(event.id): accepted (booked Day \(event.bookedDay), value Day \(event.valueDay))")
    case .rejected(let reason):
        print("\(event.id): rejected - \(reason)")
    }
}

let capitalized = ledger.capitalizeInterest(on: 6)
print("\nDaily report (final value-dated view; interest credit appears only on Day 6)")
for day in 1...6 {
    let report = ledger.dailyReport(day: day)
    let balances = AccountID.allCases.map { account in
        "\(account.rawValue) \(report.closingBalances[account]!)"
    }.joined(separator: "; ")
    let fees = AccountID.allCases.map { account in
        "\(account.rawValue) charge=\(report.feeCharges[account] ?? 0) reversal=\(report.feeReversals[account] ?? 0)"
    }.joined(separator: "; ")
    let auth = report.authorizations.keys.sorted().map { id in
        "\(id)=\(report.authorizations[id]!)"
    }.joined(separator: ", ")
    let errors = report.errors.joined(separator: "; ")
    print("Day \(day): \(balances) | fees: \(fees) | auth: \(auth.isEmpty ? "none" : auth) | errors: \(errors.isEmpty ? "none" : errors)")
}

print("Capitalized Day 6: \(capitalized.map(\.description).joined(separator: "; "))")
print("\nHistorical checkpoint after E7: Day 2 pre-fee \(ledger.dailyReport(day: 2, asOfArrival: 7).preFeeBalances[.acc001]!)")
print("Historical checkpoint after E9: Day 2 close \(ledger.dailyReport(day: 2, asOfArrival: 9).closingBalances[.acc001]!)")
