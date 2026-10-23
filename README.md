# Deep Care

Deep Care is one Flutter project that builds three separate Android apps: **Client**, **Admin**, and **Provider**. They share the Appwrite project and common configuration/theme, while keeping app-specific screens, models, and services in their own folders.

## Requirements

- Flutter SDK and Dart, with `flutter` available on your `PATH`.
- Android Studio and Android SDK/platform tools. Flutter/Gradle downloads the required Gradle components during the first build.
- Java 17 or newer. Android Studio's bundled Java runtime is suitable.
- For a physical Android phone: enable Developer options and USB debugging, connect the phone, and accept the USB debugging prompt. An Android emulator also works.
- Optional: VS Code with the Flutter and Dart extensions.

Check the local setup and accept Android SDK licenses if requested:

```shell
flutter doctor -v
flutter doctor --android-licenses
```

## Get the project

```shell
git clone https://github.com/sdeepankar/physioapp.git
cd physioapp
flutter pub get
flutter devices
```

Open the `physioapp` project root in your IDE. Do not copy `android/local.properties` from another computer; it contains machine-specific SDK paths. Keep the project and Flutter package cache on the same drive when possible.

## Apps and flavors

The Android product flavors are defined in [`android/app/build.gradle.kts`](android/app/build.gradle.kts). Each app has its own application ID and display name:

| App | Flavor | Entrypoint | Android application ID |
| --- | --- | --- | --- |
| Client | `client` | `lib/main_client.dart` | `com.example.physio` |
| Admin | `admin` | `lib/main_admin.dart` | `com.example.physio.admin` |
| Provider | `provider` | `lib/main_provider.dart` | `com.example.physio.provider` |

The root entrypoints delegate to the app implementations under `lib/client/`, `lib/admin/`, and `lib/provider/`. Shared code is under `lib/core/` and `lib/services/`.

## Run on a device or emulator

From the project root, run one app at a time:

```shell
flutter run --flavor client --target lib/main_client.dart
flutter run --flavor admin --target lib/main_admin.dart
flutter run --flavor provider --target lib/main_provider.dart
```

To choose a specific connected device, first run `flutter devices`, then add `-d <device-id>` to a command, for example:

```shell
flutter run -d <device-id> --flavor admin --target lib/main_admin.dart
```

### Run from VS Code

1. Open the project root folder in VS Code.
2. Connect a phone or start an emulator, then select it in the status bar.
3. Open **Run and Debug** and choose **Deep Care Client**, **Deep Care Admin**, or **Deep Care Provider**.
4. Press **F5**. The matching launch configuration is in [`.vscode/launch.json`](.vscode/launch.json).

## Build Android APKs

Build debug APKs for local installation:

```shell
flutter build apk --debug --flavor client --target lib/main_client.dart
flutter build apk --debug --flavor admin --target lib/main_admin.dart
flutter build apk --debug --flavor provider --target lib/main_provider.dart
```

Build release APKs:

```shell
flutter build apk --release --flavor client --target lib/main_client.dart
flutter build apk --release --flavor admin --target lib/main_admin.dart
flutter build apk --release --flavor provider --target lib/main_provider.dart
```

APK files are written to `build/app/outputs/flutter-apk/` with flavor-specific names, such as `app-client-debug.apk`, `app-admin-release.apk`, and `app-provider-release.apk`.

Install a debug APK on a connected device using Android Debug Bridge:

```shell
adb install -r build/app/outputs/flutter-apk/app-client-debug.apk
adb install -r build/app/outputs/flutter-apk/app-admin-debug.apk
adb install -r build/app/outputs/flutter-apk/app-provider-debug.apk
```

The current Gradle configuration signs release builds with the debug key to simplify local builds. Before distributing apps, configure a private release keystore and signing configuration in `android/app/build.gradle.kts`; do not publish a production app signed with the debug key.

## Build Android App Bundles

For Google Play distribution, build a separate Android App Bundle for each flavor:

```shell
flutter build appbundle --release --flavor client --target lib/main_client.dart
flutter build appbundle --release --flavor admin --target lib/main_admin.dart
flutter build appbundle --release --flavor provider --target lib/main_provider.dart
```

Bundles are written to `build/app/outputs/bundle/`.

## Appwrite configuration

The shared Appwrite endpoint, project, database, and table IDs are configured in [`lib/core/appwrite_config.dart`](lib/core/appwrite_config.dart). The apps use the existing `registered-email-otp` Function for backend operations. Deploy and configure that Function using [`functions/registered-email-otp/README.md`](functions/registered-email-otp/README.md), then confirm its IDs and permissions against the Appwrite Console.

Current app data uses the Appwrite `user_profiles`, `services`, `provider_profiles`, `orders`, and `order_events` tables. Saved addresses and app preferences are stored on-device. The UPI payment page is a demo and does not charge or verify payments.

## Location permissions

Android location permissions are declared in `android/app/src/main/AndroidManifest.xml`. Allow location access when prompted to use automatic location lookup. If permission is declined, location can be retried from the address selector or Service Address page. The resulting area and PIN depend on device location and geocoding availability.

## Current implementation status

- Client: email OTP account access, profile sync/editing, service browsing, booking creation/history/details, booking cancellation, location lookup, settings, and support UI.
- Admin: review provider profiles and assign orders to providers.
- Provider: flavor and app scaffold are in place; sign-in, availability, and assigned-booking workflows remain to be implemented.
- Payment: UPI is a non-transactional demo; a payment provider and server-side confirmation are still needed.
- Other future work: booking notifications/reminders, saved-address and medical-history backend storage with access controls, Hindi translations, and a complete support contact flow.

## Project layout

```text
lib/
  main_client.dart             # Client flavor entrypoint
  main_admin.dart              # Admin flavor entrypoint
  main_provider.dart           # Provider flavor entrypoint
  client/                      # Client screens, models, services, settings, widgets
  admin/                       # Admin app and screens
  provider/                    # Provider app scaffold
  core/                        # Shared Appwrite config and theme
  services/                    # Shared Appwrite access/authentication
functions/registered-email-otp/ # Appwrite backend function source
android/app/build.gradle.kts   # Android flavor names, IDs, and app labels
.vscode/launch.json            # VS Code launch profiles
```
