# Deep Care Appwrite Function

One Appwrite Function handles registered-email OTP and the Deep Care API. Keep
the existing function ID `registered-email-otp`; Flutter sends OTP requests to
`/` and backend requests to their respective paths such as `/services`,
`/profile/sync`, and `/orders`.

Configure it with:

- Runtime: Node.js 22
- Entrypoint: `src/main.js`
- Build command: `npm install`
- Execute access: Any (the login screen is used before a session exists)
- Scopes: `users.read`, `databases.read`, `rows.read`, `rows.write`

Deploy the contents of this directory as the source for the existing function.
The `users.read` scope supports the login email check; database and row scopes
are needed for the authenticated API routes. Function execution access must
remain `Any` because the registered-email check runs before a session exists.

Configure these function variables if you use table IDs different from the
defaults embedded in `src/main.js`:

- `DEEP_CARE_DATABASE_ID` (default `6acbac6a0016d4551f12`, Deep Care Dev)
- `DEEP_CARE_USER_PROFILES_TABLE`
- `DEEP_CARE_SERVICES_TABLE`
- `DEEP_CARE_PROVIDER_PROFILES_TABLE`
- `DEEP_CARE_ORDERS_TABLE`
- `DEEP_CARE_ORDER_EVENTS_TABLE`
- `DEEP_CARE_BOOKING_COUNTERS_TABLE` (default table ID `6adba477000bac6a2804`)

## Sequential booking IDs

New booking row IDs are allocated by the function in this format:

```text
DC + two-character service code + appointment YYYYMM + five-digit sequence
```

For example, `DCAM20261000001` is the first Ambulance booking for October 2026.
The sequence increments independently for each service and appointment month.
The five-digit number is server allocated; it is not generated on the phone.

Before deploying this version, add the following schema to the `orders` table:

- `clientRequestId`: varchar, max size 36, optional for existing rows
- Unique index named `clientRequestId_unique` on `clientRequestId`

The function uses table ID `6adba477000bac6a2804` for booking counters by
default. If your counter table has another ID, set
`DEEP_CARE_BOOKING_COUNTERS_TABLE` to that ID. The table needs one column:

- `value`: integer, required, default `0`, range `0` to `99999`

The function uses each counter row's `$id` as its key, such as `DCAM202610`,
and increments `value` atomically. Keep this table; deleting its rows resets the
corresponding sequences and can cause booking ID collisions.

For login, `/` checks Appwrite's Users service. It returns
`{ "registered": false }` without sending an OTP when the email is unknown; for
an existing email it sends a code and returns `{ "registered": true, "userId":
"..." }`. Signup still uses the Appwrite client directly.

All other routes require an authenticated Appwrite session. Client, provider,
and admin permissions are checked against each user's `user_profiles.role`.

The provider app uses these routes:

- `GET /provider/status` reads the signed-in account's role and provider profile.
- `POST /provider/apply` submits or resubmits provider details, selected active
  services, and service areas. It creates or updates the user profile with the
  `provider` role and sets provider verification to `pending` and availability
  to `false`. A client account applying this way becomes a provider account;
  use separate Appwrite accounts if the same person needs distinct client and
  provider logins.
- Admin approves or rejects the submitted profile in the Admin app.
- `POST /provider/availability` changes availability only after approval.
- `GET /provider/orders` returns bookings assigned to the verified provider,
  including the client's name and phone from `user_profiles` for those assigned
  bookings.
- `POST /provider/orders/{orderId}/accept`, `reject`, `out-for-service`,
  `start`, and `complete` update the assigned booking and record order events.
  A declined booking is offered to another matching available provider; if
  none is available, it returns to admin for manual assignment.

Redeploy this existing function after changing `src/main.js`. Do not create a
separate function for the provider app.

Because function execution access is `Any`, only the `/` login route is
unauthenticated; it checks the registered email before sending an OTP. Protect
it with execution limits or CAPTCHA/rate limiting before production use. The
email existence check also reveals whether an account is registered.
