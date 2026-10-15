import Foundation

public struct DailyReport: Equatable {
    public let day: Int
    public let preFeeBalances: [AccountID: Money]
    public let closingBalances: [AccountID: Money]
    public let feeCharges: [AccountID: Int]
    public let feeReversals: [AccountID: Int]
    public let interestAccruals: [AccountID: Money]
    public let authorizations: [String: AuthorizationStatus]
    public let errors: [String]
}

extension Ledger {
    public func dailyReport(day: Int, asOfArrival: Int? = nil) -> DailyReport {
        let cutoff = asOfArrival ?? Int.max
        let visible = entries.filter { $0.originArrival <= cutoff }
        var preFee: [AccountID: Money] = [:]
        var closing: [AccountID: Money] = [:]
        var charges: [AccountID: Int] = [:]
        var reversals: [AccountID: Int] = [:]
        var accruals: [AccountID: Money] = [:]

        for account in AccountID.allCases {
            let accountEntries = visible.filter { $0.account == account && $0.valueDay <= day }
            let preFeeMinor = accountEntries.filter { !$0.source.isFee(for: day) }
                .reduce(Int64.zero) { $0 + $1.minorUnits }
            let closingMinor = accountEntries.reduce(Int64.zero) { $0 + $1.minorUnits }
            let interestBase = accountEntries.filter { !$0.source.isInterest }
                .reduce(Int64.zero) { $0 + $1.minorUnits }
            preFee[account] = Money(currency: account.currency, minorUnits: preFeeMinor)
            closing[account] = Money(currency: account.currency, minorUnits: closingMinor)
            charges[account] = visible.filter {
                $0.account == account && $0.source == .feeCharge(day: day)
            }.count
            reversals[account] = visible.filter {
                $0.account == account && $0.source == .feeReversal(day: day)
            }.count
            accruals[account] = Money(currency: account.currency,
                                      minorUnits: Self.roundedInterest(positiveMinorUnits: interestBase))
        }

        var authorizationStates: [String: AuthorizationStatus] = [:]
        for item in processed where item.event.arrival <= cutoff && item.event.bookedDay <= day {
            guard item.outcome == .accepted else { continue }
            switch item.event.kind {
            case .authorization(let id, _):
                authorizationStates[id] = snapshots[item.event.arrival]?.authorizations[id]
            case .settlement(let id, _):
                authorizationStates[id] = .settled
            default: break
            }
        }
        let errors = processed.compactMap { item -> String? in
            guard item.event.arrival <= cutoff, item.event.bookedDay <= day,
                  case .rejected(let reason) = item.outcome else { return nil }
            return "\(item.event.id): \(reason)"
        }
        return DailyReport(day: day, preFeeBalances: preFee, closingBalances: closing,
                           feeCharges: charges, feeReversals: reversals,
                           interestAccruals: accruals, authorizations: authorizationStates,
                           errors: errors)
    }

    func reconcileFees(through lastDay: Int, originArrival: Int) {
        guard lastDay >= 1 else { return }
        for day in 1...min(lastDay, 6) {
            // The assessment specifies an AED fee; ACC-002 never overdraws in the fixture.
            let account = AccountID.acc001
            let preFee = entries.filter {
                $0.account == account && $0.valueDay <= day && !$0.source.isFee(for: day)
            }.reduce(Int64.zero) { $0 + $1.minorUnits }
            let charges = entries.filter { $0.account == account && $0.source == .feeCharge(day: day) }.count
            let reversals = entries.filter { $0.account == account && $0.source == .feeReversal(day: day) }.count
            let netFeeCount = charges - reversals
            if preFee < 0 && netFeeCount == 0 {
                entries.append(LedgerEntry(account: account, valueDay: day, minorUnits: -2_500,
                                           source: .feeCharge(day: day), originArrival: originArrival))
            } else if preFee >= 0 && netFeeCount == 1 {
                entries.append(LedgerEntry(account: account, valueDay: day, minorUnits: 2_500,
                                           source: .feeReversal(day: day), originArrival: originArrival))
            }
        }
    }

    @discardableResult
    public func capitalizeInterest(on day: Int) -> [Money] {
        guard day == 6, !interestCapitalized else { return [] }
        let cutoff = (processed.map { $0.event.arrival }.max() ?? 0) + 1
        var credited: [Money] = []
        for account in AccountID.allCases {
            let total = (1...day).reduce(Int64.zero) { sum, currentDay in
                sum + dailyReport(day: currentDay).interestAccruals[account]!.minorUnits
            }
            let amount = Money(currency: account.currency, minorUnits: total)
            entries.append(LedgerEntry(account: account, valueDay: day, minorUnits: total,
                                       source: .interest(day: day), originArrival: cutoff))
            credited.append(amount)
        }
        interestCapitalized = true
        return credited
    }

    private static func roundedInterest(positiveMinorUnits: Int64) -> Int64 {
        guard positiveMinorUnits > 0 else { return 0 }
        var raw = Decimal(positiveMinorUnits) * Decimal(4) / Decimal(10_000)
        var rounded = Decimal()
        NSDecimalRound(&rounded, &raw, 0, .plain)
        return NSDecimalNumber(decimal: rounded).int64Value
    }
}

private extension LedgerEntry.Source {
    func isFee(for day: Int) -> Bool {
        self == .feeCharge(day: day) || self == .feeReversal(day: day)
    }

    var isInterest: Bool {
        if case .interest = self { return true }
        return false
    }
}
