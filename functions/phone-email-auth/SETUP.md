# Phone.Email OTP to Appwrite

The Flutter sign-in opens Phone.Email directly. The user enters first and last name in Deep Care, then Phone.Email collects
and verifies the phone number. After verification, this function validates the
SDK access token with Phone.Email and creates or reuses the matching Appwrite
account using the submitted name and verified number. The verified first name, last name, profile name,
and phone are returned to Flutter and saved locally. If Phone.Email does not return a name, the function uses
Deep Care User as a fallback.

## Configure in Appwrite

1. Create a Function with ID phone-email-auth, runtime Node.js 22, and
   entrypoint index.js. Upload/deploy this folder as its function source.
2. Set Execute access to Any. This only allows the HTTP execution; it does not
   grant access to Appwrite user APIs.
3. Under the Function Settings Scopes, enable users.write and users.read for
   its ephemeral Function API key. users.write is required to create users,
   mark phone verification, and create custom tokens. users.read is required
   when checking an existing account at repeat sign-in.
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
