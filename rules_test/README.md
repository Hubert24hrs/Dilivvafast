# Security-rules tests

Executable tests for `firestore.rules` and `storage.rules`. They load the real
rules files from the repo root and run them against the Firebase emulators, so
a change that loosens a permission boundary fails here instead of in
production.

**88 tests, 22 suites.**

## Running them

Needs a JDK (the Firestore emulator is a Java process). This machine has no
`java` on `PATH`, but Android Studio ships one:

```bash
export JAVA_HOME="/c/Program Files/Android/Android Studio/jbr"
export PATH="$JAVA_HOME/bin:$PATH"
cd rules_test && npm install && npm test
```

The emulators run under the project id `demo-dilivvafast`. The `demo-` prefix
tells the Firebase CLI to stay fully offline — it never contacts, and cannot
touch, the real `fast-delivery-d8d5c` project.

## What is covered

| Area | Boundary held |
| --- | --- |
| `users` create (SEC-3) | No self-assigning `admin`/`driver`, no pre-funded wallet, no pre-set `isVerifiedDriver` |
| `users` update | Role, wallet, and rating counters unwritable by the owner |
| Driver gate | Only a driver with `isVerifiedDriver == true` may go online |
| `orders` create (SEC-6) | Must start `pending`, unassigned, unpaid, in your own name |
| `orders` update | Customer cannot reprice, assign, mark paid, or cancel directly; driver cannot raise earnings or steal an assigned order |
| Support threads | `support_<uid>` readable only by its owner |
| `messages` | Sender id cannot be forged; sent messages immutable |
| `transactions`, `driver_payouts` | Server-written only |
| `driver_applications` | Cannot self-approve; only admin flips status |
| `referrals` | Client cannot name `referrerId` and mint a bonus |
| `sos_alerts`, `ratings`, `zones` | Ownership and immutability |
| Catch-all | Unlisted collections and storage paths denied |

## Notes for whoever maintains this

- `--test-concurrency=1` is deliberate. `node --test` runs files in parallel by
  default, and both files share one emulator — the `clearFirestore()` in one
  file wipes the other's fixtures mid-run. Removing that flag produces
  confusing, non-deterministic failures that look like rule bugs but are not.

- The suite has been mutation-tested: reintroducing the original SEC-3 hole
  (dropping the role/wallet guards from the `users` create rule) fails exactly
  four tests and no others. If you change the rules and nothing here goes red,
  check that the tests still exercise what you think they do.
