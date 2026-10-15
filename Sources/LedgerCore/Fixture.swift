public enum LedgerFixture {
    public static let events: [Event] = [
        event("E1", 1, 1, 1, .acc001, .credit(aed(120_000))),
        event("E2", 2, 1, 1, .acc001, .debit(aed(95_000))),
        event("E3", 3, 2, 2, .acc001, .authorization(id: "Auth-A", hold: aed(20_000))),
        event("E4", 4, 3, 3, .acc001, .credit(aed(40_000))),
        event("E5", 5, 4, 4, .acc001, .settlement(id: "Auth-A", amount: aed(18_500))),
        event("E6", 6, 4, 4, .acc001, .settlement(id: "Auth-Z", amount: aed(18_000))),
        event("E7", 7, 5, 2, .acc001, .debit(aed(62_000))),
        event("E8", 8, 5, 5, .acc001, .authorization(id: "Auth-B", hold: aed(9_000))),
        event("E9", 9, 6, 2, .acc001, .reversal(of: "E7")),
        event("E10", 10, 5, 5, .acc002, .installmentCredit(total: bhd(10_000), count: 3)),
    ]

    private static func event(_ id: String, _ arrival: Int, _ booked: Int, _ value: Int,
                              _ account: AccountID, _ kind: EventKind) -> Event {
        Event(id: id, arrival: arrival, bookedDay: booked, valueDay: value,
              account: account, kind: kind)
    }

    private static func aed(_ minor: Int64) -> Money { Money(currency: .aed, minorUnits: minor) }
    private static func bhd(_ minor: Int64) -> Money { Money(currency: .bhd, minorUnits: minor) }
}
