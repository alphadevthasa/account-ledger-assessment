# Architecture tradeoffs | In-memory account ledger core

Staff Software Engineer assessment | 16 October 2026

This note explains how the bounded replay would need to change before it could support a UAE-licensed bank. The executable remains a deliberately small, in-memory exercise. References to Central Bank standards below identify relevant control surfaces; they are not a claim that this package satisfies those standards.

## 1. Append-only at 100x volume

The first failure is replay cost and memory, not integer precision. Every accepted event, rejection, journal entry, fee adjustment, and snapshot remains resident. `dailyReport` scans entries for each requested day; `reconcileFees` repeats historical projections as backdated events arrive. At 100x, a batch of value-dated corrections can repeatedly revisit the same account history, while the process has no durable recovery point. An append-only list alone is an audit shape, not a production journal.

The cheapest structural relief is an account-scoped projection keyed by value day, with checkpoints and an index of affected days. A correction invalidates the earliest impacted checkpoint and recomputes forward for that account only. Keep arrival-ordered decisions and fee reversals as immutable records; never rewrite the past event to make the cache look clean. Partition by account so one account's correction does not stall every other account. Before production, put the event journal, idempotency keys, checkpoints, and reconciliation cursor in durable storage with atomic append-and-project semantics; measure worst-case backdating and recovery time under load.

<!-- PAGE -->

## 2. Value dates in a regulated operation

A backdated posting changes balances and may change fees, accrual, statements, and the customer's explanation of past activity. The implementation recomputes a final value-dated view, appends compensating fee records, and keeps the authorization decision made at arrival. In a live bank, the same correction needs an effective date, a recorded reason and approver, a link to the original entry, a notification decision, a statement restatement path, and a ledger-to-general-ledger reconciliation. Recomputed interest cannot silently replace interest already paid or reported: it needs a delta posting and a product-approved rounding rule.

The CBUAE Consumer Protection Standards require transaction notifications as transactions occur (2.1.1.44), monthly transaction account statements with interest/profit and fee breakdowns (2.1.2.9), and correction of institution-caused errors with refunds and consumer communication (5.1.1.38-40). Their data-retention and UAE data-location provisions also affect the journal and its backups (6.1.6.1, 6.1.6.3). These are reasons to preserve both the original and corrected customer-visible facts. The assessment calls the accrual “interest”; an Islamic bank would need product and Sharia governance review of the applicable profit/interest treatment and disclosures before release (2.1.1.42, 11.1.1.1-4).

**One release gate:** route every value-date correction through a maker-checker workflow that shows the before/after impact by day, fee, accrual, and statement period. Approval must atomically append the correction and any compensating postings, record the reason, and queue customer communication and reconciliation. Fail the correction closed if the resulting journal and general-ledger totals do not agree. Test this gate with late reversals across a closed statement period.

<!-- PAGE -->

## 3. Authorization endings other than matched settlement

In the executable, an authorization request can be **declined** at decision time. It creates no hold; E8 stays declined even after a later backdated reversal. An **approved** authorization has only one implemented ending: its matching settlement releases the full hold and posts the actual debit. An approved hold with no settlement remains active indefinitely; the annotated failing test demonstrates this omission. Thus there is no other post-approval ending in the current model.

Production must add explicit, append-only transitions for these omitted endings:

- **Expiry:** a merchant never presents a hotel deposit or card purchase. At the network/product deadline, release the remaining hold once, keep the approval and expiry records, notify or expose the released available balance, and reject a late settlement unless the scheme permits a documented exception.
- **Void or cancellation:** a merchant cancels before clearing. Validate the merchant/network reference, release the specified remaining hold exactly once, and preserve the reason; duplicate voids are idempotent.
- **Authorization reversal or partial release:** a merchant reduces a fuel preauthorization before final clearing. Release only the indicated amount; retain the remaining hold and cap later clearing to the allowed rule. The current all-or-nothing settlement path cannot express this.
- **Risk or account intervention:** fraud review or account closure stops an outstanding authorization. Record who or what acted, release or ring-fence the hold according to network and legal obligations, and give any later clearing a deterministic exception path rather than silently dropping it.

A chargeback or refund **after settlement** is a new transaction and dispute lifecycle, not an ending of an active hold. A failed settlement attempt must likewise leave the original hold in a defined state until a valid retry, reversal, or expiry.

<!-- PAGE -->

## 4. Deliberate cuts and risk carried forward

- **Memory-only journal and single process:** easiest way to show deterministic folding; crashes lose history and no two writers can safely share an account. Add durable atomic storage and idempotent ingestion before real funds.
- **Six fixed days and two accounts:** exposes value-date arithmetic; no calendar, cut-off, time zone, holiday, closed period, or account lifecycle. Define these with operations and product owners.
- **One AED overdraft rule, no FX:** avoids inventing a BHD conversion; a negative BHD balance or changed tariff needs an explicit product contract and versioned fee schedule.
- **Simple authorization and settlement:** no expiry, void, partial clearing, incremental approval, network advice, dispute, or late presentment. Available balance can be stuck; model lifecycle events and scheme-specific limits.
- **Final recomputation of accrual:** enough to prove rounding and capitalization conservation; live corrections require delta credits/debits, payout cut-offs, statement repair, and product/Sharia approval.
- **No identity, access control, privacy workflow, observability, or general ledger:** appropriate for a code exercise; production requires controlled operations, protected customer data, audit monitoring, and independent reconciliation.

Source: Central Bank of the UAE, *Consumer Protection Standards*, clauses cited above, https://www.centralbank.ae/media/5crd24gm/cp-standards-pdf.pdf (accessed 16 October 2026).
