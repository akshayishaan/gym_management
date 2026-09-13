# 16 — Flutter Payments + Invoice PDF

**What to build:** Payments screen (collected hero, month filter bottom-sheet, PaymentCard list with void/refund/reverse actions posting requestId) + client-side invoice as a shareable PDF built with `pdf` + `printing`, keeping the hardcoded gray/green / white-background styling (the only hardcoded-color surface).

**Blocked by:** 09, 14

**Status:** ready-for-agent

- [ ] Payments list + month/year filter bottom-sheet
- [ ] void/refund/reverse actions work via requestId (idempotent)
- [ ] Invoice renders as shareable/saveable PDF with the exact gray/green invoice styling
