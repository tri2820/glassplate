# Glassplate

A small SwiftUI iOS boilerplate built around Apple’s native Liquid Glass components and the [`asc`](https://asccli.sh/) App Store Connect CLI.

## What is included

- SwiftUI app shell with Home, Explore, and Profile tabs.
- Native `TabView` and navigation toolbars, which automatically adopt Liquid Glass on iOS 26.
- Reusable glass card and toolbar button components with an iOS 18 material fallback.
- An `asc` workflow for local builds, TestFlight uploads, and App Store release previews.
- A unit-test target and shared Xcode scheme.

## Requirements

- macOS with Xcode 26 or newer (the project targets iOS 18 and compiles Liquid Glass APIs conditionally).
- `asc` 5.13 or newer: `brew install asc`.
- An Apple Developer account and App Store Connect API key only when you are ready to upload.

## Run locally

1. Open `Glassplate.xcodeproj` in Xcode.
2. Set your Development Team and replace `com.example.glassplate` with your bundle identifier.
3. Pick an iOS 26 simulator and run the `Glassplate` scheme.

From the command line, after installing full Xcode:

```sh
asc xcode doctor --output table
asc workflow validate
asc workflow run build
```

## Connect App Store Connect

Keep credentials outside the repo. Log in once through Keychain:

```sh
asc auth login \
  --name "Glassplate" \
  --key-id "YOUR_KEY_ID" \
  --issuer-id "YOUR_ISSUER_ID" \
  --private-key /absolute/path/to/AuthKey.p8

asc auth status --validate
```

Pass release values at runtime rather than storing them in git:

```sh
# Preview the App Store plan. This does not upload or submit.
asc workflow run appstore_preview \
  APP_ID:1234567890 \
  VERSION:1.0.0

# Archive, export, upload, and distribute to an internal TestFlight group.
asc workflow run testflight \
  APP_ID:1234567890 \
  GROUP_ID:"Internal Testers"
```

The TestFlight workflow performs real App Store Connect mutations. Review `.asc/workflow.json`, signing, and runtime values before running it.

## Liquid Glass approach

The navigation UI intentionally uses system `TabView`, `NavigationStack`, and toolbar components. On iOS 26 those controls receive Liquid Glass from the system, preserving platform behavior, accessibility, and future refinements. Custom surfaces use `glassEffect` only where it adds hierarchy, with a material fallback for iOS 18–25.

