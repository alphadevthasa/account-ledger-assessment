# Worklog

Times below are Asia/Jakarta (WIB, UTC+7), 2026-10-16. This is a record of
observed work, not a reconstructed claim of independent authorship. Codex
assisted with design, implementation, tests, and prose; candidate review is
required before submission and live defense.

| Time | Observed action |
| --- | --- |
| 00:25 | Inspected Swift 6.2 availability and initialized a separate Git repository; wrote and committed the design specification. |
| 00:31 | Ran `MoneyTests` red with `Money` missing, then green after exact minor-unit money and event values were added; committed the values. |
| 00:32 | Ran authorization tests red with `Ledger` missing, then green for holds, settlement, unknown Auth-Z, and duplicate event IDs; committed the reducer. |
| 00:33 | Ran projection tests red with missing `dailyReport` and installment event support, then green for backdated fees, E9 compensation, and exact interest capitalization; committed projection logic. |
| 00:34 | Ran the supplied fixture test red with `LedgerFixture` missing; implemented the fixture and replay runner. The first fixture test compile failed due to `ArraySlice` versus `Array` assertion types; corrected the assertion, then the fixture test passed. |
| 00:35 | Ran `RUN_KNOWN_FAILURE=1 swift test --filter HoldExpiryFailingTest`; it failed as intended because an approved hold does not expire in this model. |
| 00:36 | Ran the full default `swift test` suite: 13 tests, 1 expected skip, 0 failures. Ran `swift run LedgerReplay` and inspected all six reported days and both historical checkpoints. |
| 00:39 | Wrote the four-part architecture note, created a four-page PDF, rendered every page, and checked text extraction and page count. |
| 04:43 | Re-ran `swift test` (13 tests, 1 expected skip, 0 failures) and `swift run LedgerReplay`; created the public GitHub repository, pushed all seven commits, and confirmed anonymous access in Incognito. Uploaded the repository URL and four-page PDF to Mal Careers and received the successful-submission confirmation. |

The submission page confirmed that responses are being graded.
