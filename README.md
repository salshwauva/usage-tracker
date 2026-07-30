# Usage Tracker

A menu bar app that tracks AI usage credits in one place: Anthropic, OpenAI,
and xAI API spend, plus Claude.ai, ChatGPT, and Grok subscription usage.

## Status

First working build. Menu bar item, popover with per-service usage bars, and
a settings window for API keys and manual subscription entries. Not yet
tested against real API keys.

## How usage data gets in

Two different mechanisms, because the underlying services don't offer the
same access:

- **API billing** (Anthropic, OpenAI, xAI): pulled live from each provider's
  official usage/cost API on a timer. Requires an admin/organization-scoped
  API key, not a regular project key — usage reporting is admin-only on both
  Anthropic and OpenAI. xAI has no published usage endpoint yet, so that
  provider only confirms the key is valid.
- **Subscription caps** (Claude.ai, ChatGPT, Grok/X Premium): none of these
  expose usage via a public API. Usage Tracker stores whatever you last typed into
  Settings, timestamped, rather than pretending to poll something that
  doesn't exist.

None of the API-billing services expose a spending *limit* either — only
spend. The "limit" shown next to API usage is a personal budget you set
locally in Settings, not a value read from the provider.

## Requirements

- macOS 14 or later
- Xcode 16 or later
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) (`brew install xcodegen`)

## Building

```
xcodegen generate
open UsageTracker.xcodeproj
```

Or from the command line:

```
xcodegen generate
xcodebuild -project UsageTracker.xcodeproj -scheme UsageTracker -configuration Debug build
```

## Structure

- `Sources/UsageTrackerCore` — models, Keychain-backed API key storage, usage
  providers, the manual-entry store, and the `AppState` orchestrator.
- `Sources/UsageTracker` — the SwiftUI menu bar app: popover content and settings.
- `docs/decisions/` — ADRs for choices worth a paper trail.
