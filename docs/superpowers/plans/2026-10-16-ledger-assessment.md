# Ledger Assessment Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a runnable Swift ledger replay and a 2-4 page architecture PDF for the Mal Careers assessment.

**Architecture:** Immutable event values are folded in arrival order. Authorization decisions remain fixed, while value-dated daily projections and fees are reconciled with append-only adjustments. Interest is rounded per day and capitalized once.

**Tech Stack:** Swift 6.2, Swift Package Manager, XCTest, Foundation Decimal; Python ReportLab for the PDF.

**Spec:** `docs/superpowers/specs/2026-10-16-ledger-assessment-design.md`

## Global Constraints

- Six-day fixture in supplied E1-E10 order; no web, persistence, UI, or database layer.
- AED has 2 decimal places and BHD has 3; money storage uses signed Int64 minor units.
- Events and fee corrections are append-only; arrival order and value date are separate.
- Overdraft fee is AED 25.00 once per negative day; interest is 0.04% on positive closing balances and capitalizes at end of Day 6.
- Default test suite is green; a separate annotated failing test demonstrates an omitted production behavior.
- Keep intact commit history, real timestamped WORKLOG, and truthful decisions/limitations.

## Review Focus

1. Replayed E6 without Auth-Z must leave ACC-001 unchanged and record an error (Task 2).
2. E8 after a backdated debit and fee adjustments must be declined using the balance known then (Task 3).
3. E9 cannot erase fee records; compensating entries must restore net historical balances (Task 3).
4. Three BHD installments must sum to 10.000 without floating point (Task 1).
5. Day 6 capitalization must equal the sum of individually rounded daily accruals (Task 3).

---

### Task 1: Package, money, and event values

**Files:** Create `Package.swift`, `Sources/LedgerCore/Money.swift`, `Sources/LedgerCore/Event.swift`, `Tests/LedgerCoreTests/MoneyTests.swift`.

**Interfaces:** `Money(currency: Currency, minorUnits: Int64)`, `Money.split(count: Int) throws -> [Money]`; `Event(id: String, arrival: Int, bookedDay: Int, valueDay: Int, account: AccountID, kind: EventKind)`.

- [ ] Write `MoneyTests` first: AED 1000.00 in minor units is 100000; BHD 10.000 split three ways is 3334, 3333, 3333; splitting zero or into zero parts throws.
- [ ] Run `swift test --filter MoneyTests` and observe missing module/type failure.
- [ ] Add package manifest and smallest `Money`, `Currency`, `Event` values; use quotient and remainder to split minor units, with deterministic first-installment remainder.
- [ ] Run `swift test --filter MoneyTests` and verify pass; commit as `feat: add exact money and event values`.

### Task 2: Authorization reducer and validation

**Files:** Create `Sources/LedgerCore/Ledger.swift`, `Tests/LedgerCoreTests/AuthorizationTests.swift`.

**Interfaces:** `Ledger.apply(_ event: Event) -> EventOutcome`; `Ledger.snapshot(afterArrival: Int) -> LedgerSnapshot`; `AuthorizationState` is `approved`, `declined`, or `settled`; `EventOutcome` holds accepted/rejected status and reason.

- [ ] Write tests for E3 approval with AED 50.00 remaining available, E5 settlement of AED 185.00 releasing a AED 200.00 hold, E6 unknown authorization rejection without debit, and duplicate event ID rejection.
- [ ] Run `swift test --filter AuthorizationTests`; confirm meaningful failures.
- [ ] Implement append-only accepted and rejected event records and authorization state transitions. Settlement requires a previously approved active authorization; a hold changes available balance, never ledger balance.
- [ ] Run filtered tests and full `swift test`; commit as `feat: preserve authorization decisions during replay`.

### Task 3: Value dates, fees, reversal, interest

**Files:** Create `Sources/LedgerCore/Projection.swift`, `Tests/LedgerCoreTests/ProjectionTests.swift`; extend `Ledger.swift`.

**Interfaces:** `Ledger.dailyReport(day: Int, asOfArrival: Int?) -> DailyReport`; `Ledger.reconcileFees(through day: Int)` appends charge or reversal entries; `Ledger.capitalizeInterest(on day: Int) -> [Money]`.

- [ ] Write tests proving the pre-fee Day 2 close after E7 is AED -370.00, fees arise on every eligible negative day, E8 declines, E9 retains charge records but creates compensations, E10 exact BHD split, and rounded interest sums exactly to capitalization.
- [ ] Run `swift test --filter ProjectionTests`; confirm meaningful failures.
- [ ] Implement daily sums by value date, excluding the same day's fee from its own eligibility calculation and including prior-day net fees. Reconcile days in order; reversal E9 is a new positive entry linked to E7. Use `Decimal` only for the rate calculation and round half-up to an integer minor unit.
- [ ] Run filtered tests and full `swift test`; commit as `feat: reconcile value-dated fees and interest`.

### Task 4: Fixture runner and required repository documents

**Files:** Create `Sources/LedgerReplay/main.swift`, `README.md`, `NUMBERS.md`, `AMBIGUITIES.md`, `REJECTED.md`, `WORKLOG.md`, `Tests/LedgerCoreTests/FixtureTests.swift`, `Tests/KnownLimitations/HoldExpiryFailingTest.swift`.

**Interfaces:** `swift run LedgerReplay` prints Day 1-Day 6 rows with balances, fees, auth states, and errors; known limitation test is invoked separately from the default package test suite.

- [ ] Write a fixture test that asserts acceptance/rejection of E1-E10 and final report invariants; run it red.
- [ ] Implement the runner and exact fixture; run `swift test` and `swift run LedgerReplay`, checking each day's output.
- [ ] Write the five required Markdown documents with verifiable arithmetic, chosen constants and half-value alternatives, real ambiguous choices, every refused criterion, and actual timestamped actions. Include the intentionally failing hold-expiry test with an inline explanation; run it separately and record its expected failure.
- [ ] Commit as `docs: explain replay decisions and limitations`.

### Task 5: Architecture PDF and visual verification

**Files:** Create `docs/architecture.md`, `output/pdf/architecture-tradeoffs.pdf`; optionally keep the PDF authoring script under `tools/`.

**Interfaces:** Final PDF is 2-4 pages, covers all four mandated sections, and can be read without the code open.

- [ ] Draft four sections grounded in the actual implementation: 100x bottleneck and cheapest structural relief; UAE value-date operations/regulatory surface and one control; all non-settlement authorization endings and mandated behavior; every scope cut and risk.
- [ ] Run the PDF skill's `mark_artifact_operation_started.mjs` exactly once immediately before authoring, then create PDF with ReportLab.
- [ ] Render pages with `pdftoppm`, inspect every page, and verify page count and readable text; commit as `docs: add architecture tradeoffs PDF`.

### Task 6: Delivery

**Files:** No new implementation files; update WORKLOG with actual final checks if needed.

- [ ] Run fresh `swift test` and `swift run LedgerReplay`; inspect `git log --oneline` and `git status --short`.
- [ ] Create a public GitHub repository with intact commit history, verify anonymous access in an incognito window, then enter its URL in Part 1.
- [ ] Upload the verified 2-4 page PDF to Part 2, check both completion indicators, and submit the assessment as authorized by the user.
