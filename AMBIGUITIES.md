# Ambiguities resolved for this implementation

1. **Arrival versus booked day.** E10 says booked Day 5 but follows the Day 6
   E9 in the supplied stream. Replay follows E1-E10 order, stores booked day
   separately, and applies value date for the final daily projection. This
   makes the supplied order auditable without pretending E10 arrived earlier.
2. **What the daily report means.** The printed rows are a final value-dated
   view after all ten events, plus explicit after-E7 and after-E9 checkpoints.
   A report prepared at the actual close of Day 2 would differ after E7.
3. **Fee self-reference.** A fee booked on Day 2 can make Day 2 more negative.
   Eligibility is therefore measured before *that day's own fee*, while
   prior-day net fees are included. Days are reconciled in order.
4. **Backdated changes and prior fees.** When E7 makes prior daily closes
   negative, fee charges are appended with those value dates. When E9 makes
   them non-negative again, compensating fee reversals are appended. Original
   charges are never erased, so a report can show charge=1, reversal=1.
5. **Backdated changes and interest.** Daily accruals are recomputed from
   the final value-dated projection and capitalized once on Day 6. This is a
   final corrected view, not a claim about what was known or paid on each
   historical day in a live bank.
6. **Authorization decisions.** E3's approval is a historical decision made
   with AED 250.00 ledger and a AED 200.00 hold. E7 does not revoke it after
   the fact. E5 settles against that recorded approval. E8 is evaluated
   against the ledger known after E7 and is declined; E9 does not rewrite it.
7. **Settlement amount versus hold.** The given AED 185.00 settlement is
   smaller than the AED 200.00 hold. The entire hold is released and the
   actual settlement amount is debited. An amount exceeding the hold is
   rejected in this exercise; incremental/partial settlement is out of scope.
8. **Equal BHD installments.** Three equal payments are impossible at BHD
   0.001 precision. The deterministic near-equal allocation is 3.334,
   3.333, 3.333, with the first receiving the extra minor unit.
9. **Rounding rule.** The prompt specifies precision but not tie breaking.
   Daily interest uses decimal half-up rounding to a minor unit; each
   rounded accrual is summed exactly, then credited once at Day 6.
10. **AED fee on a BHD account.** The fee is specified only in AED, with no
    conversion rate or cross-currency account. ACC-002 never has a negative
    balance in the fixture. Applying this fee to an overdrawn BHD account
    would need an explicit product rule, not an invented FX conversion.
11. **Reversal scope.** E9 reverses the principal of accepted debit E7 with
    the same value date. Fee reversals are separate compensating records.
    It does not undo a historical authorization decision or delete entries.
12. **Authorization lifetime.** No expiry or cancellation event exists in
    the prompt. An approved unsettled hold would remain active indefinitely
    in this model. The annotated failing test makes this omission visible.
13. **Input validation.** Duplicate event IDs, zero/negative amounts,
    unknown or inactive authorization IDs, currency mismatch, and dates
    outside Days 1-6 are rejected. Production ingestion would need a fuller
    schema and durable idempotency ledger.
