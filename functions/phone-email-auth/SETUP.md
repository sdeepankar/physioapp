# Phone.Email OTP to Appwrite

Deep Care provides separate Log in and Create account choices. Both use the
Phone.Email Flutter SDK to collect and verify the phone number. Registration
also asks for first and last name in Deep Care. The Appwrite Function validates
the SDK access token with Phone.Email, then either finds the existing phone
account (log in) or creates a new one (registration). Registration writes the
entered first and last name to Appwrite, including replacing the generic name
on accounts created by the earlier prototype. It returns that same name and
the verified phone to Flutter. The app persists the profile locally after the
user confirms the details.

Logging in with a phone that has no account asks the user to create an account.
Registering a phone that already has an account updates its name and continues
the sign-in flow, so previously created placeholder-name accounts are repaired.

## Configure in Appwrite

1. Create a Function with ID phone-email-auth, runtime Node.js 22, and
   entrypoint index.js. Upload/deploy this folder as its function source.
2. Set Execute access to Any. This only allows the HTTP execution; it does not
   grant access to Appwrite user APIs.
3. Under the Function Settings Scopes, enable users.write and users.read for
   its ephemeral Function API key. users.write is required to create users,
   mark phone verification, and create custom tokens. users.read is required
   when checking an existing account at sign-in and registration.
4. Add this Function variable:
   - PHONE_EMAIL_CLIENT_ID: the client ID from the Phone.Email dashboard.
5. Deploy the function and confirm its ID matches phoneEmailAuthFunctionId in
   lib/core/auth_config.dart.

Appwrite injects the function endpoint, project ID, and x-appwrite-key at
runtime. Do not add an Appwrite API key to the Flutter project. For a rejected
Appwrite API request, the function log records the response type and message,
but never logs the Phone.Email access token or Appwrite key.

## Phone.Email response note

The Flutter SDK provides an accessToken. The function sends it to Phone.Email's
/getuser endpoint and uses only the provider's successful verified phone response.
No Phone.Email API key is required.
