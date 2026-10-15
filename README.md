# In-memory account ledger core

This Swift package replays the ten supplied events in arrival order. It has no
server, database, persistence, or UI. AI assistance was used to draft and
implement this assessment; the design choices and limitations are documented
so they can be examined in a live defense.

## Run

Requires Swift 6.2 on macOS 14 or later.

```sh
swift test
swift run LedgerReplay
```

The replay prints each event outcome, followed by Day 1-Day 6 final
value-dated balances, fee charge/reversal counts, authorization states, and
errors. `E6` is rejected because Auth-Z was never approved. Auth-A settles;
Auth-B is declined after the backdated E7 debit. Final Day 6 balances after
interest capitalization are AED 466.03 and BHD 10.008. The two historical
checkpoint lines distinguish the state after E7 from the state after E9.

The report shows a **final** value-dated view, so it includes corrections
learned later. The event outcome lines retain what was known at each arrival.
Fee charge and reversal counts are audit records; a `1/1` pair nets to zero
but neither record disappears. Daily interest accrues on positive closing
balances only and is credited once at the end of Day 6.

## Deliberately failing test

The default suite skips a test for a missing production behavior. To see the
one annotated failure requested by the assessment:

```sh
RUN_KNOWN_FAILURE=1 swift test --filter HoldExpiryFailingTest
```

It fails because an approved but unsettled hold never expires in this bounded
model. A production implementation needs an explicit expiry rule and an
append-only release event. This failure is not a claim that the supplied
Auth-B should expire: Auth-B is declined in the supplied stream.

## Read the decisions

- `NUMBERS.md` explains exact amounts, precision, and chosen numeric bounds.
- `AMBIGUITIES.md` states the assumptions needed to make replay deterministic.
- `REJECTED.md` evaluates every supplied acceptance criterion and records
  abandoned approaches.
- `WORKLOG.md` contains real, timestamped work and validation steps.
- `output/pdf/architecture-tradeoffs.pdf` is the separate architecture deliverable.
