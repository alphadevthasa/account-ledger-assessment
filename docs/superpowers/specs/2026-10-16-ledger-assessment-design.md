# In-memory account ledger assessment: design

Date: 2026-10-16 (Asia/Jakarta)
Status: candidate review draft

## Purpose and boundaries

Produce two assessment artifacts: a small Swift package containing an in-memory,
append-only ledger and a runnable replay, and a 2-4 page architecture PDF. The
package has no web, persistence, UI, or database layer. Its output shows each
day's closing ledger balance, assessed or reversed fees, authorization states,
and rejected events. The six-day fixture uses the stated event order E1-E10.
The PDF explains the implementation's actual trade-offs and production gaps.
The candidate must be able to explain every choice in a 45-minute live defense.

This is a separate repository from InterviewHelper. Swift 6.2 is available on
the machine. Swift is a working language choice inferred from the user's local
project, not a claim about their past work.

## Considered approaches

1. **Replay the immutable stream (chosen).** Fold events in arrival order for
   authorization decisions; reconstruct value-dated daily balances and fee
   eligibility after late events. Easy to audit and test for ten events. Full
   replay and retained events grow without bound.
2. **Mutate historical balances.** Less code, but erases the state known when
   an authorization was granted and cannot explain later adjustments. Rejected.
3. **Maintain incremental daily projections.** Better at scale, but late value
   dates force invalidation and cascading fee recalculation. Deferred until
   measurements justify snapshots and affected-day recomputation.

## Domain and money model

Money is a signed Int64 count of minor units, tagged with a currency. AED has
two decimal places; BHD has three. No binary floating point enters ledger
arithmetic. A distinct decimal calculation path computes 0.04% daily interest
from the integer closing balance and rounds once per day, half-up, to the
account currency's precision. The capitalized Day 6 credit equals the sum of
those already rounded daily accruals; no remainder is discarded.

An event has a unique ID, arrival sequence, booked day, value day, account,
and typed payload. Events are never edited or deleted. E10 expands into three
attributed BHD credits that sum to BHD 10.000; the extra 0.001 goes to the
first installment, producing 3.334, 3.333, 3.333. This is an explicit tie
break for amounts that cannot divide equally at currency precision.

## Replay and authorization flow

The reducer processes E1-E10 in the supplied sequence, even though E10 says
booked Day 5 and appears after a Day 6 event. `booked_day` is data; sequence
is the authoritative arrival order. A later event can change the final view
of an earlier value day but cannot retroactively rewrite a historical
authorization decision or a rejected settlement.

At E3, Auth-A is approved because AED 250.00 ledger less AED 200.00 hold leaves
AED 50.00 available. Holds affect available balance only. E5 settles Auth-A
for AED 185.00: the approved hold is released and the debit is booked with
Day 4 value date. E6 names absent Auth-Z and is rejected without a debit. E8
is evaluated against the balance known after E7 and fee reconciliation; a
negative available balance makes Auth-B declined, so it has no active hold.
An authorization can be approved, declined, settled, or still active; no
expiry, cancellation, or partial settlement is invented for this fixture.

For each accepted value-dated ledger change, compute balances for Day 1-Day 6
from all visible entries with `value_day <= day`. Fee eligibility for a day
uses that day's close *before its own fee or fee reversal*, while retaining
the net fees of prior days. This resolves the fee's otherwise self-referential
effect on its own close. A negative pre-fee balance calls for exactly one AED
25.00 fee per account and day. Reconcile desired fee state with the recorded
net fee by appending a charge or compensating reversal, value-dated to the
affected day. Process days in order because an earlier fee can alter later
closes. Never silently delete an assessed fee. One pass over six days is
sufficient because a day's fee only affects that day and later days. After E9,
fee reversals may restore the net balance, while the original fee records
remain in the audit stream.

Reports distinguish (a) the state known after each arrival and (b) the final
value-dated view. Interest is computed from final Day 1-Day 6 balances after
fee reconciliation and capitalized once at the end of Day 6. That timing is
an assessment choice because the prompt does not prescribe whether late
value-dated events reopen prior interest accruals.

## Criteria and ambiguities to document

The repository will explicitly accept or refuse each stated criterion in
`REJECTED.md`, with arithmetic and event-order evidence. In particular:

- E7 changes the pre-fee Day 2 balance from AED 250.00 to AED -370.00.
- E7 can make several daily closes negative; a single Day 2 fee is not enough.
- Auth-A's Day 4 settlement uses the approval actually recorded at E3.
- Auth-Z's missing authorization makes its settlement invalid.
- Auth-B's conditional hold rule is true, but E8 is declined in this stream.
- E9 can restore *net* balances through compensating entries; it cannot erase
  the original fee assessments or undo the historical decline of Auth-B.
- Three BHD 3.334 credits would total BHD 10.002, not BHD 10.000.
- Discarding an interest rounding remainder violates exact capitalization.

`AMBIGUITIES.md` will explain arrival order versus booked day, backdated
fee and interest reconciliation, reversal scope, fee effects on later days,
tie-breaking for installments, settlement versus current available balance,
half-up rounding, and whether an authorization is allowed to remain active
beyond Day 6. `NUMBERS.md` will identify both mandated and chosen numeric
constants and justify chosen bounds with the requested half-value comparison.
`WORKLOG.md` will record real timestamps and actions only.

## Code structure and verification

The package will separate money/event values, the reducer, daily projection
and fee reconciliation, the fixture runner, and tests. Tests cover currency
precision, installment conservation, holds, settlement and unknown-auth
rejection, backdated balances, fee compensation, E9 reversal, daily interest
and exact capitalization, and deterministic replay. A separately runnable,
annotated failing test will expose a deliberately omitted production behavior
such as hold expiry; the default verification suite remains green, and the
README will state how to reproduce the failure. This is a real limitation,
not a hidden broken core rule.

The README will give exact run commands and output interpretation. Commits
will preserve the design, implementation, correction, and documentation
history without squashing.

## Architecture PDF

The 2-4 page PDF will cover four required sections: append-only growth at
100x and the cheapest structural change; UAE-licensed-bank value-date
operational and regulatory concerns with one pre-live control; all modeled
and omitted authorization end states with required production behavior; and
every scope cut with its deferred risk. It will discuss specific
implementation choices and avoid repeating the event list or rules.

The PDF will not claim regulatory approval or user experience. Before
publication, the candidate reviews the choices and makes any changes needed
to defend them without AI.
