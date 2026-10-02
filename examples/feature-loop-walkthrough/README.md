# Walkthrough: one feature through the build loop

This mirrors the restaurant example from the AI LABS video, in the shape
this package produces. Nothing here runs; it shows what you should see.

## 1. Ask
```
/build guests can order food for pickup from the restaurant site
```

## 2. features.md gets an entry
```
## pickup-ordering
- status: todo
- summary: a guest picks menu items, gives name + email + pickup time, submits.
- entry point: /order page, "Order for pickup" button in the nav
### Rules
1. Guest selects one or more menu items with quantities ≥ 1.
2. Guest provides name, a valid email, and a pickup time within opening hours.
3. Submitting creates an order record and shows a confirmation with order id.
4. Missing/invalid fields show inline errors; nothing is saved.
...
```

## 3. write-checks produces checks/pending/pickup-ordering/
```
CHECKLIST.md
 1. The /order page renders and shows the menu with quantity controls.
 2. An order with two items and valid details is saved and returns an id.
 3. An order with quantity 0 is rejected with an error on that line.
 4. A malformed email is rejected and nothing is saved.
 5. A pickup time outside opening hours is rejected.
 ...
11. The nav shows "Order for pickup" linking to /order.      <- wiring check
```
You read this, say "also require a real email address", it adds the check,
you say go.

## 4. approve-checks locks them
```
.claude/kloop/approve-checks.sh pickup-ordering
locked 3 file(s) into checks/locked/pickup-ordering at 4f2a9c1
```
From here the guard hook refuses any edit under `checks/locked/`.

## 5. feature-builder rounds (results.tsv)
```
round  feature          commit   passed total status   failing                    description
0      pickup-ordering  4f2a9c1  0      11    baseline  (all)                     baseline before any change
1      pickup-ordering  8b11e0d  11     11    keep      none                      order model + /order page + nav link + validation
```
One round, all green, and the builder also wired the form because the
Definition of done in program.md requires reachability, not just checks.

## 6. Report
`reports/2026-10-02-pickup-ordering.md` with the table above, what the
checks did not cover, and habits suggested for `## How to work`.

## 7. With /auto-loop instead
After each feature, `## How to work` in program.md is rewritten from the
evidence, e.g.
```
2. Connect the feature to the app in the same round that makes its checks
   pass. (evidence: shared-db r1, mentions r1)
3. Before changing shared behaviour, grep for every place the app already
   does that job. (evidence: mentions r1, shared-projects r1)
```
