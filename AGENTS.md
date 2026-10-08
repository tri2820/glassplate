# AGENTS.md

Guidance for agents (and humans) working in this repo. Keep it short; the commands below are
the ones that are easy to get wrong.

## Layout

- `ios/` — SwiftUI app. Xcode project: `ios/Glassplate.xcodeproj` (scheme `Glassplate`). Tabs: Home, Chat, Explore, Profile.
- `api/` — Cloudflare Worker (Wrangler) that proxies `POST /chat/completions` to the Command Code Provider API.
- `README.md` — setup, release, and App Store Connect docs.

## Run

This repo uses **bun**, not npm (`bun.lock` is committed).

```sh
cd api
bun install
bun run dev                    # serves http://localhost:8787 (loopback only)
curl -s http://127.0.0.1:8787/health   # -> {"ok":true}
```

iOS: open `ios/Glassplate.xcodeproj` and build the `Glassplate` scheme. The Chat tab reads
`ChatScreen.workerBaseURL` in `ios/Glassplate/Features/Chat/ChatView.swift`, chosen by config:

- **DEBUG** → `https://envy.tailc3387.ts.net` (Tailscale Serve on this Mac, see below).
- **Release** → `https://glassplate.nguyenvantri2820.workers.dev`.

The Worker injects `COMMANDCODE_API_KEY` from `api/.dev.vars` (gitignored). Never commit it.

## How a device reaches the local Worker (and why HTTPS)

`https://envy.tailc3387.ts.net` is **Tailscale Serve**: it terminates TLS and proxies `/` to
`http://127.0.0.1:8787`. The app must use HTTPS because plain `http://<ip>` — including the
Tailscale IP `100.x` — is blocked by App Transport Security with `-1022`,
"requires the use of a secure connection". `NSAllowsLocalNetworking` does **not** cover IP literals.

**The URL is persistent.** The Serve config is stored in tailscaled's backend state, so it survives
CLI exit, reboots, and Worker restarts. It only changes if the Mac's Tailscale node name (`envy`) or
the tailnet suffix (`tailc3387.ts.net`) changes.

### Next time you develop

You only need to start the Worker — the URL is already wired up:

```sh
cd api && bun run dev      # now https://envy.tailc3387.ts.net/health -> {"ok":true}
```

If the URL ever stops proxying (e.g. Serve was reset, or a new machine), re-apply it — the Worker
must be running on :8787 first:

```sh
tailscale serve --bg 8787              # proxy https://envy.tailc3387.ts.net -> 127.0.0.1:8787
tailscale serve status                 # confirm the mapping
tailscale serve --https=443 off        # undo
```

Any device on the tailnet can hit the URL (it is tailnet-only, not Funnel).

## Common commands (error-prone — copy these)

### Build for a physical device

The project has no `DEVELOPMENT_TEAM` in build settings, so a bare `xcodebuild` fails with
`Signing for "Glassplate" requires a development team. Select a development team...`.

```sh
# Team id = the TeamIdentifier shown by: codesign -dv --verbose=4 <a previously built app>
# (or just pick your team once in Xcode > target > Signing & Capabilities)
xcodebuild -project ios/Glassplate.xcodeproj -scheme Glassplate -configuration Debug \
  -destination 'generic/platform=iOS' -allowProvisioningUpdates \
  DEVELOPMENT_TEAM=<TEAM_ID> CODE_SIGN_STYLE=Automatic build
```

### Install / launch on the iPhone

```sh
# Paired devices — copy the UDID from here
xcrun devicectl list devices

# Install a built .app (path is under DerivedData/.../Build/Products/Debug-iphoneos/)
xcrun devicectl device install app --device <UDID> /path/to/Glassplate.app

# Launch
xcrun devicectl device process launch --device <UDID> com.example.glassplate
```

Pitfall: the installed bundle id is `PRODUCT_BUNDLE_IDENTIFIER` (`com.example.glassplate`).
Installing under a *different* id silently creates a **second** "Glassplate" app. Confirm exactly one:

```sh
xcrun devicectl device info apps --device <UDID> | grep -i glassplate
# remove an extra one by bundle id
xcrun devicectl device uninstall app --device <UDID> com.vantri.glassplate
```

### Diagnose "secure connection" (-1022) and "-1009 appears to be offline"

- `-1022` = App Transport Security blocked cleartext. Use the HTTPS Tailscale URL, not `http://<ip>`.
- `-1009` on a device hitting a local address = the address is unreachable (Tailscale not connected
  on the phone, or Serve not applied).

```sh
tailscale status                       # are the Mac and iPhone online on the tailnet?
tailscale serve status                 # is the envy -> 127.0.0.1:8787 mapping present?
curl -s https://envy.tailc3387.ts.net/health   # -> {"ok":true}
lsof -nP -iTCP:8787 -sTCP:LISTEN       # workerd on 127.0.0.1:8787
```

## UI tests & screenshots

`GlassplateUITests` drives the Chat tab with XCUITest and attaches screenshots to the result
bundle — no source hacks. The app exposes debug-only launch arguments (read in
`ios/Glassplate/Support/UITestSupport.swift`) and a `ScriptedChatTransport`, so tests run offline
and deterministically.

```sh
# Run only the UI tests, writing a result bundle
xcodebuild test -project ios/Glassplate.xcodeproj -scheme Glassplate \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -only-testing:GlassplateUITests \
  -resultBundlePath .asc/artifacts/uitests.xcresult

# Pull the screenshots out (PNGs + manifest.json) into the repo-root screenshots/ dir
xcrun xcresulttool export attachments \
  --path .asc/artifacts/uitests.xcresult \
  --output-path screenshots
```

Launch arguments the app understands (only honored with `-uitest`, DEBUG builds only):

- `-uitest` — enables the hooks; inert in Release.
- `-uitest-tab chat` — start on a given tab.
- `-uitest-transcript conversation` — seed a fixture transcript.
- `-uitest-reply "text"` — override the scripted assistant reply.
- `-uitest-delay 4000` — hold the reply (ms) to capture the thinking state.

Screenshots are `XCTAttachment`s with `lifetime = .keepAlways`, so they are kept even when the test
passes. To capture a new screen, add an assertion plus a `capture(named:)` call in
`ios/GlassplateUITests/ChatScreenshotTests.swift`.

## Conventions

- Package manager is **bun**. Do not reintroduce npm or `package-lock.json`.
- No secrets in the repo. The key lives in `api/.dev.vars` (gitignored) or the deployed Worker secret.
- Verify before claiming done: `curl` the HTTPS health endpoint, and `xcrun devicectl ... info apps` after installs.
- Don't leave stray build products or duplicate device installs behind; see the cleanup commands above.
