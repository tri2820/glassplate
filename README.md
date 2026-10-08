# Glassplate

A small SwiftUI iOS app with an AI chat tab, backed by a Cloudflare Worker. SwiftUI Liquid Glass components and the [`asc`](https://asccli.sh/) App Store Connect CLI.

## Monorepo layout

```
ios/   SwiftUI app (Home, Chat, Explore, Profile tabs)
api/   Cloudflare Worker — proxies chat to the Command Code Provider API
```

## What is included

- SwiftUI app shell with Home, Chat, Explore, and Profile tabs.
- An AI chat tab powered by [swift-ai-sdk](https://github.com/zaidmukaddam/swift-ai-sdk) through the `api/` Worker. The Worker holds the `COMMANDCODE_API_KEY`; the app carries no key.
- Native `TabView` and navigation toolbars, which automatically adopt Liquid Glass on iOS 26.
- Reusable glass card and toolbar button components with an iOS 18 material fallback.
- An `asc` workflow (in `ios/`) for local builds, TestFlight uploads, and App Store release previews.
- A unit-test target and shared Xcode scheme.

## Requirements

- macOS with Xcode 26 or newer (the project targets iOS 18 and compiles Liquid Glass APIs conditionally).
- [Bun](https://bun.sh) for the Worker.
- `asc` 5.13 or newer: `brew install asc`.
- An Apple Developer account and App Store Connect API key only when you are ready to upload.

## Run locally

1. Open `ios/Glassplate.xcodeproj` in Xcode.
2. Set your Development Team and replace `com.example.glassplate` with your bundle identifier.
3. Pick an iOS 26 simulator and run the `Glassplate` scheme.

The chat tab needs the Worker running:

```sh
cd api
bun install
bun run dev          # http://localhost:8787
```

Then point the app at it. `ChatScreen.workerBaseURL` in `ios/Glassplate/Features/Chat/ChatView.swift` selects the URL by build configuration:

- **Simulator (DEBUG)** — `http://localhost:8787` works directly (App Transport Security allows `localhost`).
- **Physical iPhone (DEBUG)** — `https://envy.tailc3387.ts.net`, a persistent Tailscale Serve URL that terminates TLS and proxies to `http://127.0.0.1:8787` on this Mac. `localhost` on the phone means the phone, and plain `http://<ip>` is blocked by App Transport Security (`-1022`), so the HTTPS tailnet URL is how a device reaches the dev Worker.
- **Release** — the deployed Worker at `https://glassplate.nguyenvantri2820.workers.dev`.

The Serve URL persists across reboots and CLI exits (it lives in tailscaled's state), so next time you only need `bun run dev`. See [`AGENTS.md`](AGENTS.md) for the device build/install commands and troubleshooting.

## Deploy the Worker

```sh
cd api
bun install
bun run deploy
bunx wrangler secret put COMMANDCODE_API_KEY
```

The Worker then answers at `https://glassplate.nguyenvantri2820.workers.dev` with:

- `GET /health` — `{ "ok": true }`
- `POST /chat/completions` — OpenAI-compatible proxy to the Command Code Provider API, with the Bearer key injected from the Worker secret. Everything else returns 404.

## Run the iOS app from the command line

From `ios/`, after installing full Xcode:

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
  --private-key /absolute/path/AuthKey.p8

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

The TestFlight workflow performs real App Store Connect mutations. Review `ios/.asc/workflow.json`, signing, and runtime values before running it.

## Liquid Glass approach

The navigation UI intentionally uses system `TabView`, `NavigationStack`, and toolbar components. On iOS 26 those controls receive Liquid Glass from the system, preserving platform behavior, accessibility, and future refinements. Custom surfaces use `glassEffect` only where it adds hierarchy, with a material fallback for iOS 18–25.
