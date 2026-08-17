# Access and roles

qorder has three surfaces, one per role. The customer surface is open; the staff
and owner surfaces are behind a config access code (until real auth via Ebriza).

| Surface | Path | Who | How to enter |
| --- | --- | --- | --- |
| Menu / ordering | `/` (or `/menu`) | Customer | Open, no login. The table comes from the QR link `/t/<n>`. |
| Account / loyalty | `/me` → `/sign-in` | Customer (identified) | Optional phone sign-in (OTP), for loyalty |
| Waiter surface | `/waiter` | Staff (waiter + barman, shared account) | Staff access code |
| Owner dashboard | `/owner` | Owner | Owner access code |

## Demo access codes

- Staff (`/waiter`): **2468**
- Owner (`/owner`): **1357**
- Customer phone sign-in (OTP): any phone, demo code **000000** (mock, no SMS)

## Notes

- Codes are config-driven per venue: `AppConfig.staffAccessCode` and
  `AppConfig.ownerAccessCode` in `lib/core/config/app_config.dart`.
- Each guarded surface has a logout that returns to the code gate.
- The signed-in role is remembered on the device (a waiter tablet stays signed
  in across restarts).
- Real staff/owner auth (ideally the Ebriza users) replaces the codes later.

## Testing on the phone / browser

Append the path to the demo URL, e.g. `http://<lan-ip>:8082/#/owner`, then enter
the code. (`go_router` on web uses the `/#/` prefix.)
