# Usage Tracker

Usage Tracker is a macOS menu bar app that measures time spent in AI apps and websites. It combines that activity into one weekly hour budget, with totals for each service.

A flower in the menu bar shows progress through the budget. The popover shows the current service and the week's time entries.

## How time is counted

The app checks the frontmost application every two seconds and when the active app changes. Desktop apps match by bundle identifier. Supported browser tabs match by URL host.

A match starts a session. A different app ends that session or starts one for another service. Idle detection pauses the count. The default idle threshold is 90 seconds.

The default budget is five hours per week, with Monday as the first day. Settings can change the budget, first day, and idle threshold.

## Features

- Weekly time totals and totals for each service.
- Automatic sessions for configured apps and supported browser tabs.
- Built-in entries for services such as Claude, ChatGPT, Gemini, Grok, Cursor, and Perplexity.
- Custom services with app identifiers and website hosts.
- Local time entries, with recovery of interrupted sessions from the last saved sample.

## Build and run

Requirements: macOS 14 or later, Xcode 16 or later, and [XcodeGen](https://github.com/yonaskolb/XcodeGen).

```sh
xcodegen generate
open UsageTracker.xcodeproj
```

Select the `UsageTracker` scheme in Xcode and run the app. The app appears in the menu bar.

A command-line build uses:

```sh
xcodebuild -project UsageTracker.xcodeproj -scheme UsageTracker -configuration Debug build
```

## Browser access

macOS requests Automation permission when the app reads a browser's active tab. The current implementation includes URL access for Chrome, Safari, Brave, Edge, Arc, and Comet.

Browser support depends on AppleScript access. A denied permission prevents URL-based recognition in that browser. Some browser identifiers exist in the catalog without a URL adapter.

## Data and privacy

Time entries and settings stay in local `UserDefaults`. The app does not require provider API keys.

The monitor reads the active app identifier and, for supported browsers, the active tab URL. It uses the host to match a service. Stored time entries contain a date, duration, and service identifier.

The app does not collect prompt text or response text.

## What the totals mean

The totals measure foreground activity. They do not measure tokens, API spend, subscription credits, or a provider's usage limit.

An app match can include work unrelated to an AI feature. For example, the built-in Copilot entry matches VS Code activity. Website host matches can include account and settings pages.

Very short sessions may be omitted. Weekly totals assign an entry to the week in which the session started.

## Tests

```sh
xcodebuild -project UsageTracker.xcodeproj -scheme UsageTracker test
```

The core tests cover service matches, weekly calculations, state, and persistence.

## Source map

| Path | Purpose |
| --- | --- |
| `Sources/UsageTracker/` | Menu bar app, activity monitor, and browser access |
| `Sources/UsageTrackerCore/` | Service catalog, session state, weekly totals, and persistence |
| `Tests/UsageTrackerCoreTests/` | Unit tests |
| `project.yml` | XcodeGen project definition |
