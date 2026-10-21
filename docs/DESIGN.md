# ElNota — UI/UX Design System

## Product direction
A calm, premium, fast accounting tool for small shops and independent businesses. Arabic-first with reliable RTL, optional English and desktop-quality information density. Minimal, practical design: compact controls, little wasted space, clear totals, and efficient repeat workflows.

## Principles
1. **Clarity over decoration:** users should recognize debt, payments, balances, due dates, and pending sync instantly.
2. **Compact but readable:** avoid oversized dashboard cards, excessive blank space, and noisy gradients.
3. **One primary action per view:** e.g., “إضافة عميل”, “فاتورة جديدة”, “تسجيل دفعة”. Secondary actions live in a contextual menu.
4. **Financial correctness in UI:** always show currency, signs, status, and whether totals include discounts or credits.
5. **Trustworthy offline behavior:** visibly differentiate saved locally, waiting for sync, synced and failed.
6. **Responsive by intent:** mobile is stacked and touch-friendly; desktop shows denser tables, search and keyboard shortcuts.

## Visual tokens (starting points; tune with real-device review)
- `canvas.light`: `#F7F6F2` (warm cream)
- `surface.light`: `#FFFFFF`
- `text.primary.light`: `#1F2528`
- `text.secondary.light`: `#687078`
- `accent`: `#246B5A` (restrained green)
- `danger`: `#C44B46`
- `warning`: `#B7791F`
- `border.light`: `#E7E7E1`
- `canvas.dark`: `#121619`
- `surface.dark`: `#1C2226`
- `text.primary.dark`: `#F3F5F4`
- `border.dark`: `#30383C`
- Spacing: 4px grid (4 / 8 / 12 / 16 / 24); default content padding 16 mobile, 20–24 desktop.
- Radii: 8–12px standard, 14px only for major surfaces; avoid pill-shaped everything.
- Typography: Arabic typeface with clear numerals (e.g., Cairo or IBM Plex Sans Arabic); hierarchy approximately 12 / 14 / 16 / 20 / 24sp. Respect platform text scaling.
- Icons: one consistent outline family, 18–20px normal.
- Contrast: aim for WCAG AA; never indicate financial status using color alone.

## Responsive layout
- `<600px`: single-column mobile; contextual actions; bottom nav only for primary destinations.
- `600–1023px`: tablet layout, adaptable side navigation.
- `>=1024px`: persistent sidebar, compact header, content max-width where sensible, data tables with sorting/filtering.
- Do not force desktop-only grids onto narrow screens. Use appropriate Flutter breakpoints rather than device-type checks alone.

## Screens
### Overview
Show only meaningful KPIs: customer count, total receivables, total collected, outstanding installments, upcoming dues. Compact summary cards and recent activity; avoid decorative cards without action.

### Customers
Search is prominent. Mobile customer tile: name, total due/credit, last activity and one overflow action. Desktop table: customer, phone, outstanding, last transaction, status and overflow menu. Customer details show invoice history and total customer balance; **one customer-level “تسجيل دفعة” action**, not repeated payment actions per invoice.

### Invoices
Quick-create flow supports either itemized products or manual amount, with customer, amount, date, due date and optional note. Show discounts clearly and maintain audit trail for edits.

### Payments
Prominent amount field, customer summary, optional note, confirmation summary and receipt. Always indicate whether a payment is saved locally, synced or conflicted. Prevent duplicate submit UI while retaining server-side idempotency.

### Installments
Show schedule, paid/remaining, overdue status and next due date. Make partial payments and reconciliation clear.

### Settings
Group by Account, Business, Backup & Sync, Printing, Appearance, Security, and About. Display last successful sync, pending operations and manual sync. Avoid huge tiles and irrelevant toggles.

## Component patterns
- Buttons: filled primary, quiet secondary, subtle destructive confirmation.
- Forms: inline validation, numeric keyboard on mobile, tab/focus traversal desktop, clear required indicators.
- Data: formatted currency and aligned numbers; amounts use tabular figures where possible.
- Feedback: concise snackbar for success; actionable error message and retry for failure.
- Dialogs: only for destructive/irreversible operations or crucial financial confirmation.
- Empty state: one sentence and one useful action, not large art.
- Navigation: preserve search/filter on returning; use GetX routes with well-scoped bindings.

## States to design and test
Loading, empty, offline, syncing, synced, conflict, permission denied, stale session, validation error, and no data. Test long Arabic names, large balances, dynamic text size, RTL/LTR mixed phone numbers, and keyboard-only navigation.

## Implementation guardrails
- Centralize `ThemeData`, color tokens, typography and reusable primitives under `app/theme` and `core/widgets`.
- Use `LayoutBuilder`/responsive widgets, not duplicated full screens for every size.
- Use `Obx()` only around reactive subtrees; avoid rebuilding full screens when a single number changes.
- Keep destructive actions away from frequent primary actions.
- Avoid user-visible AI branding or generic dashboard illustrations unless explicitly required.
