# AttendEase Teacher Mobile v5 — Build Instructions

## Requirements
- Flutter SDK 3.19+ (stable channel)
- Android SDK with Build-Tools 34, Platform 34
- Java 17 or 21

## Steps

```bash
# 1. Navigate to the project folder
cd attendease_teacher_mobile_v5_fixed

# 2. Scaffold missing iOS/web/linux boilerplate (won't overwrite lib/ or assets/)
flutter create . --project-name attendease_teacher_mobile_v5 --org com.ahgaaf

# 3. Fetch dependencies
flutter pub get

# 4. Build release APK (debug-signed, no keystore needed for testing)
flutter build apk --release

# Output:
#   build/app/outputs/flutter-apk/app-release.apk
```

## For a production-signed APK
1. Generate a keystore: `keytool -genkey -v -keystore release.jks -alias ahgaaf -keyalg RSA -keysize 2048 -validity 10000`
2. Create `android/key.properties` with your keystore path, alias, and passwords.
3. Update `android/app/build.gradle` signingConfigs block to reference it.
4. Run `flutter build apk --release` again.

## Fixes applied to source before packaging
| File | Fix |
|------|-----|
| lib/screens/login_screen.dart | Typo: INTERNATION → INTERNATIONAL |
| lib/screens/home_screen.dart | Typo: INTERNATION → INTERNATIONAL |
| lib/screens/attendance_screen.dart | Typo fix + DropdownButtonFormField `initialValue` → `value` (compile error fix) |
