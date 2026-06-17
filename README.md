# PolyfillsAuthFix

A small rootless tweak that stops [PoomSmart's Polyfills](https://github.com/PoomSmart/Polyfills) from breaking web authentication.

## The problem

Polyfills has a **Header Injection** feature (active on iOS 11.0–16.3) that registers a custom `WKURLSchemeHandler` for `http`/`https` and re-routes **all** web traffic through `NSURLSession`. That re-routing breaks sites with strict authentication — most visibly **new Google account sign-in** in Safari and in the in-app (`SafariViewService`) web view, which fail with *"something went wrong"*. Existing sessions and non-WebKit browsers (e.g. Reynard) are unaffected.

## What it does

Forces `PolyfillsHeaderInjectionEnabled = NO` in the `com.apple.UIKit` preferences domain (where Polyfills reads its settings), so the scheme handler never installs — while **every JavaScript polyfill keeps working**. It does this two ways, so it's robust regardless of tweak load order:

1. Hooks `CFPreferencesGetAppBooleanValue` / `CFPreferencesCopyAppValue` and returns `NO` for that exact key + domain.
2. Persists the value to `NO` on load — injected into SpringBoard, it runs before Safari ever launches.

It's a no-op if Polyfills isn't installed, and harmless on iOS 16.4+ (where Polyfills' header injection is already inactive).

## Alternative

You can instead toggle **Settings → Polyfills → Header Injection** off manually. This tweak makes that state permanent and reproducible.

## Building

```sh
export THEOS=~/theos
make clean package
```

Install the resulting rootless `.deb` via a Roothide-aware package manager (Sileo/Zebra) or the Roothide Patcher.
