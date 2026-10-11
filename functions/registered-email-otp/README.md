# Registered-email OTP Function

This email-only function replaces the previous Phone.Email registration flow.
Deploy it to the Appwrite Function already used by the app. Its ID must match
`appwriteRegisteredEmailFunctionId` in the Flutter app (`registered-email-otp`
by default).

Configure it with:

- Runtime: Node.js 22
- Entrypoint: `src/main.js`
- Build command: `npm install`
- Execute access: Any (the login screen is used before a session exists)
- Scope: `users.read`

Deploy the contents of this directory as the function source. For login, the
function checks Appwrite's Users service first. If the email is not registered,
it returns `{ "registered": false }` without sending an OTP. If it exists, the
function sends the code and returns `{ "registered": true, "userId": "..." }`.
Signup continues to use the Appwrite client directly and can create new users.

Because the function is executable before login, protect it with Appwrite
execution limits or CAPTCHA/rate limiting before production use. The email
existence check also reveals whether an account is registered.
