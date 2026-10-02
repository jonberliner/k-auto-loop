# features.md

Feature tracker for the build loop. One entry per feature. Status is one of
`todo`, `checks-pending`, `checks-locked`, `building`, `done`, `stuck`.

The **Rules** block is the contract the checks encode. Write rules as
observable behaviour, not implementation. When the human changes a rule after
checks are locked, the checks must be re-written and re-approved.

---

## example-feature

- status: todo
- summary: One sentence on what the user can do when this is done.
- entry point: where in the app this is reached (page, route, command).

### Rules
1. A guest can ... and sees ...
2. Submitting with a missing ... shows ... and nothing is saved.
3. ...

### Checks
- (filled in by `write-checks`: one line per check, plain English)

### Notes
- (constraints, out of scope, related features)
