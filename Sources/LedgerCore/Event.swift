public enum AccountID: String, CaseIterable, Sendable {
    case acc001 = "ACC-001"
    case acc002 = "ACC-002"

    public var currency: Currency { self == .acc001 ? .aed : .bhd }
}

public enum EventKind: Equatable, Sendable {
    case credit(Money)
    case debit(Money)
    case authorization(id: String, hold: Money)
    case settlement(id: String, amount: Money)
    case reversal(of: String)
    case feeCharge(Money)
    case feeReversal(Money)
    case interestCredit(Money)
}

public struct Event: Equatable, Sendable {
    public let id: String
    public let arrival: Int
    public let bookedDay: Int
    public let valueDay: Int
    public let account: AccountID
    public let kind: EventKind

    public init(
        id: String,
        arrival: Int,
        bookedDay: Int,
        valueDay: Int,
        account: AccountID,
        kind: EventKind
    ) {
        self.id = id
        self.arrival = arrival
        self.bookedDay = bookedDay
        self.valueDay = valueDay
        self.account = account
        self.kind = kind
    }
}
