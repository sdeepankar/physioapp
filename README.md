# Deep Care

Deep Care is a Flutter app prototype for booking at-home healthcare services. It currently runs as a client-side demo. Patient accounts, provider management, server-backed bookings, and real payments are not connected.

## First-time setup

### Requirements

- Install the Flutter SDK and add `flutter` to your `PATH`.
- Install Android Studio with the Android SDK and platform tools. Android Studio also provides the Java runtime used by Android builds; you do not need to install or configure Kotlin or Gradle separately.
- For a physical Android phone, enable Developer options and USB debugging, connect it by USB, and accept the debugging prompt. An Android emulator also works.
- Install the Flutter and Dart extensions in VS Code if you use VS Code.

### Get the code and run it

```bash
git clone https://github.com/sdeepankar/physioapp.git
cd physioapp
flutter doctor -v
flutter pub get
flutter devices
flutter run
```

On the first Android run, Flutter/Gradle downloads the required build components automatically. In VS Code, open the cloned `physioapp` folder, choose a device from the status bar, and press **F5** (or run `flutter run` in the terminal). If `flutter doctor -v` reports a missing Android license, run `flutter doctor --android-licenses` and accept the licenses.

Keep the project and Flutter's package cache on the same drive when possible. This avoids Android Gradle errors caused by moving generated build files across drive roots. Do not copy `local.properties` from another computer; Flutter creates machine-specific Android SDK paths for the current machine when resolving packages/building.

## Current progress

- Branded launch screen with a white background and the supplied Deep Care mark as the Android app icon.
- First-run profile form for a name and Indian mobile number. There is no OTP, password, or phone verification. The details are saved on the device and shown in Profile on later launches.
- Profile editing and a Log out action. Logging out removes the saved name and number and returns to the profile form.
- Automatic location lookup after the profile form and on later app launches. The home screen displays the detected area, city, state, and PIN code. Location permission is requested from Android when needed.
- Service address form prefilled from the home location, with a **Use my current location** action to fetch the details again. The exact house or street address remains a separate field.
- Care-service browsing and search, appointment date and time selection, address entry, booking review, confirmation, My Bookings, booking details, and cancellation.
- The home screen's **Your next visit** card selects the nearest future booking, shows its service, date/time, and locality, and opens the booking details. With no upcoming appointment, it links to service browsing.
- UPI is the only payment option shown. It is a demo flow and does not open a UPI app or charge a payment.
- Profile area with personal details, bookings, address book, payment methods, settings, and help and support. Medical history, documents, family members, payment methods, and help and support still need their real flows.
- Settings for the in-app booking badge, app-wide text size, reduced motion, location permissions, and clearing the locally saved profile. Settings are stored on the device.
- English interface and Android app display name **Deep Care**.

## Run and build

To run after the first-time setup:

```bash
flutter run
```

To build a release APK:

```bash
flutter build apk --release
```

The APK is normally written to `build/app/outputs/flutter-apk/app-release.apk`.

Android location permissions are declared in `android/app/src/main/AndroidManifest.xml`. On first launch, allow location access for automatic location lookup. If access is declined, the home location can be retried from the address selector, and the Service address page also has its own location button. Area and PIN results depend on the device's location services and geocoding results.

## Local data and integrations

The name, phone number, and app settings use on-device preferences. They are not uploaded to a backend. Demo bookings are held in memory and do not survive an app restart. A name and phone number do not prove a user's identity; add a real phone verification and account flow before relying on them for healthcare bookings.

Before launch, the app still needs:

- A backend for patient, provider, staff, booking, and service data. Appwrite is the currently selected backend direction.
- Genuine phone verification and account recovery.
- Provider onboarding, verification, availability, and booking management.
- A real UPI payment provider and server-side payment confirmation.
- Push or messaging notifications for booking status and reminders.
- Persistent bookings, addresses, and profile data on the backend, with appropriate privacy and access controls.
- Hindi translations and a complete help/support contact flow.

## Project structure

- `lib/main.dart` — current Flutter UI and client-side demo flows.
- `assets/images/` — app branding and launcher icon source.
- `android/app/src/main/` — Android app label, launcher resources, location permissions, and launch-screen theme.
- `pubspec.yaml` — Flutter dependencies and launcher icon configuration.
