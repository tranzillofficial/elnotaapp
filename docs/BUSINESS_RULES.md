# ElNota | Business and Financial Rules

> Preserve existing production behavior unless a change is explicitly approved. This document records agreed behavior and labels unresolved policy questions.

## Core customer account model
- A customer can have multiple invoices.
- Record **one customer-level payment action** from customer details, not a separate payment button for each invoice.
- Customer payment reduces **total outstanding customer balance**, independent of which invoice originally created the debt.
- Invoices remain separately viewable with their individual totals/history.
- Customer account screen shows total invoiced, discounts/credits, total receipts and outstanding balance.
- Support a manual amount-only invoice/credit sale without mandatory product lines.

## Money representation
- Use a single consistent unit: integer piasters for EGP, or exact decimal representation with documented conversion.
- Never calculate using `double` / binary floating point.
- Rounding policy (tax/discount/partial installments) must be specified and tested; don't invent a rule.

## Suggested balance formula
```text
outstanding = posted_invoice_debits
            - posted_invoice_discounts
            - customer_payment_credits
            + posted_adjustment_debits
            - posted_adjustment_credits
```
A negative result means **advance/customer credit** if negative balances are permitted; never silently clamp to zero.

## Posting workflow
1. Validate amount > 0 (unless adjustment explicitly permits otherwise), owner/workspace, currency and applicable period.
2. Create immutable source record and balanced corresponding ledger event(s) transactionally.
3. Enqueue sync operation in the same local transaction.
4. Present pending sync indicator, not false server confirmation.
5. When server accepts, retain original operation ID; never recreate a payment during retry.

## Invoices
- Status candidates: `draft`, `posted`, `voided`; confirm final status model with product owner.
- Drafts may be editable. Posted invoices should use documented correction/void workflow rather than silent rewriting of history.
- If product supports discounts, track their exact source, operator and timestamp; maintain a clear net vs gross display.
- No product rows required for manual-amount invoice, but it must have a clear description/category for reporting.

## Payments
- A single customer-level `Add Payment` action records payment amount, date, optional method and notes.
- Duplicate taps and network retries must not create duplicate payment records; generate operation UUID once.
- Editing a posted payment should create an adjustment/reversal with audit log, not overwrite financial history.
- Accepting an advance exceeding current debt is **a product policy decision**; if enabled, display credit clearly.

## Installments
- Scheduled dues are not automatically separate customer debts if invoice already posted; prevent double-counting.
- Keep scheduled/due/paid representations separate from actual ledger events.
- Overdue calculations use explicit local business timezone and agreed date cutoff.
- Partial payment allocation to installment periods is **not yet decided**; avoid implicit FIFO without approval.

## Examples (EGP)
| Event | Effect on customer balance |
|---|---:|
| Invoice A posted: 500 | +500 |
| Invoice B posted: 300 | +300 |
| Customer-level payment: 250 | -250 |
| Approved discount: 50 | -50 |
| **Outstanding** | **500** |

## Reporting and UI rules
- Display a payment button **once** on the customer details header.
- List every invoice separately, but show customer-level balance and payment history once.
- Use explicit labels for `total invoiced`, `total received`, `discounts`, `remaining`, `advance`.
- Dashboard totals are projections from confirmed local ledger; sync state visible if some events remain pending.

## Open decisions requiring product approval
- Tax / VAT, receipt numbering, refund and void policies.
- Discount before/after tax, invoice status transitions, multiple currencies.
- Overpayments, installment allocations, multiple cashiers/permissions.
- Historical data migration from the web version without modifying past totals.
