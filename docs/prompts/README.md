# Build prompts — run order

| File | Who | Branch | Starts |
|---|---|---|---|
| 00-bootstrap-backend-foundation.md | Backend Dev A | chore/bootstrap | 08:15 (after docs/ is on main) |
| 01-backend-a-registration.md | Backend Dev A | feature/backend-registration | after Prompt 0 is merged |
| 02-backend-b-auth-otp.md | Backend Dev B | feature/backend-auth-otp | after Prompt 0 is merged |
| 03-web-registration.md | Web Dev | feature/web-registration | 08:15 (mock mode) |
| 04-mobile-auth.md | Mobile Dev | feature/mobile-auth | 08:15 (mock mode) |

Paste the whole file into your coding agent from the repository root. Every prompt treats docs/api-contract.md as the source of truth.
Then follow docs/integration-runbook.md (14:30) and docs/acceptance-test.md (16:30).
Also save the original architecture document as docs/architecture.md.
