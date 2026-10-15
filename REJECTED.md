# Acceptance criteria: accepted or refused

The prompt deliberately mixes correct and incorrect statements. The result
below uses the specified event order and the assumptions in `AMBIGUITIES.md`.

| Criterion | Decision | Reason |
| --- | --- | --- |
| Day 2 pre-fee close at end of Day 5 is AED -370.00 | Accept | E1-E2 leave AED 250.00; E7 is AED -620.00 value-dated Day 2; 250 - 620 = -370 before the Day 2 fee. |
| E7 causes exactly one fee, on Day 2 | **Refuse** | After E7, Day 2 is -370 before its fee, Day 3 is +5 after the Day 2 fee, Day 4 is -180 before its fee, and Day 5 is -205 before its fee. It causes charges on Days 2, 4, and 5, each AED 25.00. |
| Day 4 Auth-A settlement must be accepted | Accept | E3 approved Auth-A with AED 50.00 remaining available. Its recorded approval remains valid when the AED 185.00 settlement arrives. E7 cannot retroactively alter that decision. |
| Settlement with unknown authorization must be rejected without debiting | Accept | E6's Auth-Z does not exist; E6 is recorded as rejected and posts no AED 180.00 debit. |
| Approved Auth-B hold reduces available, not ledger, balance | Accept as a conditional rule | The rule is correct; E8 is actually declined because the known ledger is negative, so this hold is not active. |
| After E9, all balances and fees return to pre-E7 values | **Refuse literally** | Principal and net fees can be restored by E9 and compensating fee reversals. The original three fee charges remain in the append-only audit trail. E8's historical decline also remains. Calling all fees/history identical erases the very evidence needed to explain the correction. |
| All three BHD installments are 3.334 | **Refuse** | 3 x 3.334 = BHD 10.002. The conserved allocation is 3.334 + 3.333 + 3.333 = BHD 10.000. |
| Discard any remainder between rounded daily interest and capitalization | **Refuse** | The capitalized credit must equal the sum of rounded daily accruals exactly. This model sums the rounded minor-unit amounts, so no remainder exists to discard. |

## Approaches abandoned during the build

- A draft test compared an `ArraySlice<EventOutcome>` directly with an
  `Array<EventOutcome>`. The compiler rejected the mismatched collection
  types; the test now checks every expected outcome in each slice. This was
  a test assertion correction, not a ledger rule change.
- Running `swift test` and `swift run` concurrently made SwiftPM wait for
  the shared `.build` lock. Subsequent verification runs are sequential.
- Recomputing and overwriting historical authorization outcomes was
  considered in design and rejected before coding: it would make E5 appear
  inconsistent with the approval actually recorded at E3.
