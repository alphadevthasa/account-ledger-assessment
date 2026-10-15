public enum EventOutcome: Equatable, Sendable {
    case accepted
    case rejected(String)
}

public enum AuthorizationStatus: Equatable, Sendable {
    case approved
    case declined
    case settled
}

public struct ProcessedEvent: Equatable, Sendable {
    public let event: Event
    public let outcome: EventOutcome
}

public struct LedgerSnapshot: Equatable, Sendable {
    public let ledgerBalances: [AccountID: Money]
    public let availableBalances: [AccountID: Money]
    public let authorizations: [String: AuthorizationStatus]
    public let errors: [String]
}

struct LedgerEntry: Equatable {
    enum Source: Equatable {
        case event(String)
        case feeCharge(day: Int)
        case feeReversal(day: Int)
        case interest(day: Int)
    }

    let account: AccountID
    let valueDay: Int
    let minorUnits: Int64
    let source: Source
}

struct AuthorizationRecord {
    let account: AccountID
    let hold: Money
    var status: AuthorizationStatus
}

public final class Ledger {
    public private(set) var processed: [ProcessedEvent] = []
    var entries: [LedgerEntry] = []
    var authorizations: [String: AuthorizationRecord] = [:]
    private var snapshots: [Int: LedgerSnapshot] = [:]

    public init() {}

    @discardableResult
    public func apply(_ event: Event) -> EventOutcome {
        let outcome: EventOutcome
        if processed.contains(where: { $0.event.id == event.id }) {
            outcome = .rejected("duplicate event ID \(event.id)")
        } else if event.valueDay < 1 || event.valueDay > 6 || event.bookedDay < 1 || event.bookedDay > 6 {
            outcome = .rejected("day outside six-day window")
        } else if let amount = event.kind.amount, amount.currency != event.account.currency {
            outcome = .rejected("currency mismatch")
        } else if let amount = event.kind.amount, amount.minorUnits <= 0 {
            outcome = .rejected("amount must be positive")
        } else {
            outcome = applyValidated(event)
        }

        processed.append(ProcessedEvent(event: event, outcome: outcome))
        snapshots[event.arrival] = currentSnapshot()
        return outcome
    }

    public func snapshot(afterArrival arrival: Int) -> LedgerSnapshot {
        let last = snapshots.keys.filter { $0 <= arrival }.max()
        return last.flatMap { snapshots[$0] } ?? emptySnapshot()
    }

    private func applyValidated(_ event: Event) -> EventOutcome {
        switch event.kind {
        case .credit(let amount):
            entries.append(LedgerEntry(account: event.account, valueDay: event.valueDay,
                                       minorUnits: amount.minorUnits, source: .event(event.id)))
            return .accepted
        case .debit(let amount):
            entries.append(LedgerEntry(account: event.account, valueDay: event.valueDay,
                                       minorUnits: -amount.minorUnits, source: .event(event.id)))
            return .accepted
        case .authorization(let id, let hold):
            guard authorizations[id] == nil else { return .rejected("duplicate authorization \(id)") }
            let available = currentSnapshot().availableBalances[event.account]!.minorUnits
            let status: AuthorizationStatus = available >= hold.minorUnits ? .approved : .declined
            authorizations[id] = AuthorizationRecord(account: event.account, hold: hold, status: status)
            return .accepted
        case .settlement(let id, let amount):
            guard var authorization = authorizations[id] else {
                return .rejected("unknown authorization \(id)")
            }
            guard authorization.account == event.account, authorization.status == .approved else {
                return .rejected("authorization \(id) is not active for account")
            }
            guard amount.minorUnits <= authorization.hold.minorUnits else {
                return .rejected("settlement exceeds hold \(id)")
            }
            authorization.status = .settled
            authorizations[id] = authorization
            entries.append(LedgerEntry(account: event.account, valueDay: event.valueDay,
                                       minorUnits: -amount.minorUnits, source: .event(event.id)))
            return .accepted
        case .reversal, .feeCharge, .feeReversal, .interestCredit:
            return .rejected("unsupported event kind")
        }
    }

    private func currentSnapshot() -> LedgerSnapshot {
        var balances: [AccountID: Money] = [:]
        var available: [AccountID: Money] = [:]
        for account in AccountID.allCases {
            let total = entries.filter { $0.account == account }.reduce(Int64.zero) { $0 + $1.minorUnits }
            let holds = authorizations.values
                .filter { $0.account == account && $0.status == .approved }
                .reduce(Int64.zero) { $0 + $1.hold.minorUnits }
            balances[account] = Money(currency: account.currency, minorUnits: total)
            available[account] = Money(currency: account.currency, minorUnits: total - holds)
        }
        let statuses = authorizations.mapValues(\.status)
        let errors = processed.compactMap { item -> String? in
            if case .rejected(let reason) = item.outcome { return "\(item.event.id): \(reason)" }
            return nil
        }
        return LedgerSnapshot(ledgerBalances: balances, availableBalances: available,
                              authorizations: statuses, errors: errors)
    }

    private func emptySnapshot() -> LedgerSnapshot {
        let balances = Dictionary(uniqueKeysWithValues: AccountID.allCases.map {
            ($0, Money(currency: $0.currency, minorUnits: 0))
        })
        return LedgerSnapshot(ledgerBalances: balances, availableBalances: balances,
                              authorizations: [:], errors: [])
    }
}

private extension EventKind {
    var amount: Money? {
        switch self {
        case .credit(let amount), .debit(let amount), .interestCredit(let amount),
             .feeCharge(let amount), .feeReversal(let amount): amount
        case .authorization(_, let hold): hold
        case .settlement(_, let amount): amount
        case .reversal: nil
        }
    }
}
