# Numbers and why they are used

All amounts are signed `Int64` **minor units**, with a currency tag. The
assessment's amounts and rates are inputs, not tuning choices. Halving one
would answer a different problem. The table makes that distinction explicit.

| Number | Origin and use | Why not half? |
| --- | --- | --- |
| Days 1-6 | Mandated reporting window | Three days would omit E5-E10 and capitalization. |
| AED 2 decimal places; BHD 3 | Currency precision mandated in the prompt | Halving either precision is not a meaningful money representation and loses exact supplied amounts. |
| AED 25.00 = 2,500 minor units | Mandated daily overdraft fee | AED 12.50 contradicts the fee rule. |
| 0.04% per day = decimal 0.0004 | Mandated interest rate | 0.02% contradicts the rate rule. Decimal arithmetic rounds the result to a minor unit, half-up, once per day. |
| Three installments | Mandated for E10 | One or two installments would not represent the event; 1.5 installments is invalid. |
| BHD 10.000 = 10,000 minor units | Mandated E10 total | BHD 5.000 would not conserve the supplied credit. |
| Six-day end-of-window capitalization | Mandated timing | Day 3 capitalization would put interest into later daily bases and change the result. |
| `Int64` (chosen) | Exact signed minor-unit storage, up to about 9.22e18 units | A 32-bit range is half the bit width and can overflow at roughly 21.5 million AED; `Int64` leaves headroom. Production still needs checked aggregate arithmetic. |
| First installment gets the extra BHD 0.001 (chosen) | Deterministic tie break when 10,000 minor units are divided by three | Splitting the remainder in half is impossible at 0.001 precision; any chosen recipient gives the same total, so the first is easiest to reproduce. |
| Zero available balance (mandated by authorization rule) | An authorization is approved if post-hold available balance is at least zero | Half of zero is zero; changing the threshold would change the rule. |

No batch size, cache duration, retry count, hold timeout, or performance
threshold was introduced. The absence of those values is deliberate: this is
an in-memory six-day exercise, and inventing production limits would create
unsupported claims. `Int64` aggregate overflow and the absence of a hold
expiry policy are recorded as production gaps.

With the final corrected ledger before capitalization, ACC-001 accrues AED
0.10, 0.10, 0.26, 0.19, 0.19, and 0.19; the exact sum is AED 1.03. ACC-002
accrues BHD 0.004 on Days 5 and 6, totaling BHD 0.008.
