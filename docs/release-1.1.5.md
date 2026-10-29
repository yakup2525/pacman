# Ghost Runner 1.1.5 (16)

## Startup crash fixed

The existing 1.1.4 (15) release AAB crashes before Flutter starts. Installing an
APK generated from that exact bundle reproduces this on Android 15 emulators
with both 4 KB and 16 KB memory pages:

```text
Unable to get provider androidx.startup.InitializationProvider
Failed to create an instance of androidx.work.impl.WorkDatabase
```

Mobile Ads brings in WorkManager, whose AndroidX startup initializer creates a
Room database. The resolved Room 2.2.5 consumer rule keeps database class names,
but does not explicitly keep the no-argument constructor used by reflection.
Release R8 removes `WorkDatabase_Impl.<init>()`; the original release's
`usage.txt` lists that constructor as removed.

The release now includes the explicit constructor keep rule from
[AndroidX's upstream fix](https://android.googlesource.com/platform/frameworks/support/+/e4765e38e27a3f4d86188b996df97a52403dff46).
Shrinking and obfuscation remain enabled. Dart startup handling cannot catch
this failure because Android initializes providers before `main()`.

## Verification

Run `flutter analyze`, `flutter test`, and `flutter build appbundle --release`.
For this regression, also install an APK generated from the final release AAB
using Google's bundletool. Debug builds and Flutter widget tests alone do not
exercise the failing R8 path.

Check a clean install, an upgrade over build 15, repeated cold launches,
age selection, gameplay, and background/resume. Confirm the process stays alive
and its logcat contains no fatal exception. Test both 4 KB and 16 KB page sizes.

Verified on 2026-10-29: analysis clean; all 18 Flutter tests passed; signed
release AAB built successfully. Android 15 ARM64 emulators with 4 KB and 16 KB
pages both reproduced the original crash and launched build 16 successfully.
The final AAB was converted with bundletool for a clean-data launch (4 KB) and
an in-place build-15 upgrade (16 KB). Both reached the age gate and game after
selection, and survived three further cold launches each without app fatal or
Dart errors. Under-16 and adult selections, play, and background/resume were
exercised. The final R8 mapping retains `WorkDatabase_Impl.<init>()`.
These are emulator checks; no physical Android device was connected.

Final AAB SHA-256:
`07278dcdf7832459d4e0daf0c1c72fde606b003f57981ff62da055f629c9a687`.

Do not raise the website minimum version to 16 until this build is available to
all affected users, countries, devices and tracks. The existing privacy, age,
consent, and ad pacing behavior is unchanged.
