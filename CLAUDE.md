# Project context

Usage Tracker is a macOS menu bar app (SwiftUI, MenuBarExtra) that shows usage
credits across AI services: Anthropic, OpenAI, and xAI API billing spend
(pulled from each provider's official admin usage/cost API), plus Claude.ai,
ChatGPT, and Grok subscription usage caps (manually entered — none of those
three expose usage via a public API).

# Stack

- Swift 5, SwiftUI, Combine
- XcodeGen for project generation (project.yml is the source of truth, not
  the generated .xcodeproj)
- No third-party dependencies. URLSession for networking, Keychain Services
  for API key storage, UserDefaults for manual-entry persistence.

# Target platform

macOS 14 or later, Apple Silicon and Intel. Do not add iOS/iPadOS targets
unless explicitly asked — this is a menu bar app, not a universal app.

# Architectural rules

- UsageTrackerCore has no SwiftUI imports and no UI code. Everything network- or
  storage-related lives there so it's independently testable.
- One `UsageProvider` per API-billing service (Anthropic, OpenAI, xAI). Each
  provider owns its own request/response types privately — no shared
  "generic API response" abstraction across providers, since the three APIs
  don't actually share a shape.
- Subscription-cap services (Claude.ai, ChatGPT, Grok) never get a network
  provider. They only ever read from `ManualUsageStore`. Don't add
  cookie/session scraping for these — fragile, ToS-risky, and not what this
  app is for.
- API keys live only in Keychain, never in UserDefaults, never logged.
- `AppState` is the single `ObservableObject` the UI touches. Views don't
  call providers or the Keychain store directly.

# Conventions

- Commits: short imperative messages. I write my own commit messages; do not
  generate them. Do not add Co-authored-by trailers or "Generated with"
  footers.
- ADRs: docs/decisions/NNNN-slug.md for significant architectural choices.
  One page each, my prose.
- Formatting/linting: none configured yet. Match surrounding style.
- Swift: prefer `struct` over `class` unless reference semantics or
  `ObservableObject` conformance is actually needed.

# Teaching mode — how I want you to work with me

I am an MCIT student at Penn pivoting into software engineering, comfortable
in Python and Java and learning Swift. My goal for this project is to LEARN,
not just to ship.

1. Explain before editing. Before non-trivial edits (>10 lines or touching
   architecture), tell me what you'll change and why in 3-6 sentences, then
   wait for "go". Trivial fixes: just do them.
2. Teach the language, not just the solution. When you use a Swift feature I
   likely haven't seen, call it out and frame it against its Java/Python
   equivalent.
3. Show the diff and narrate it after non-trivial edits.
4. Surface design decisions as decisions — give options and tradeoffs before
   picking; if you pick, say why.
5. Push back on bad ideas (wrong pattern, dangerous, overengineered,
   misaligned) and propose an alternative.
6. Ask me to implement things myself for ~1 in 4 non-trivial additions —
   describe what's needed, point me at the file, review my attempt.
7. Check my understanding on load-bearing concepts with an occasional
   question.
8. Be concrete about uncertainty — if you're unsure an API exists or a flag
   is right, say so and suggest we verify rather than guess. This matters
   more than usual here: the Anthropic/OpenAI usage endpoints in this repo
   were written from memory of their docs, not tested against real keys.
9. Keep a learning log: append a dated 2-4 bullet summary to
   docs/learning-log.md each session (gitignored).

Teaching mode is on unless I say "just do it" or "skip the explanation". It
does NOT mean slowing down trivial work, lecturing on what I've internalized,
or refusing to write code.

# Voice and anti-fingerprint rules

I use you as a tool; the repo should read as my work. Follow strictly:

- Do NOT write commit messages, README/ARCHITECTURE.md/ADR prose. I draft
  those; you may review mine.
- Do NOT add Co-authored-by trailers, "Generated with Claude" footers, or any
  "built with AI" acknowledgment anywhere (README, LICENSE, source headers,
  package metadata).
- If I ask you to draft prose, keep it plain. No em-dash flourish, no "Let
  me…/Here's…", no leverage/seamless/robust/comprehensive, no bulleted lists
  with bold lead-ins on every item, no marketing cadence.
- Code comments: terse, capture WHY or a non-obvious constraint. Not
  narration, not self-congratulation.
- Names: short and direct over verbose.

# Anti-patterns — do not write code that does any of these

- Never fabricate a usage/cost API endpoint or response shape with false
  confidence. Anthropic and OpenAI both gate usage reporting behind
  admin-scoped keys and can change these endpoints; if a request starts
  failing, say so and point at the docs rather than silently patching in a
  guess.
- Never implement session-cookie or browser-automation scraping of claude.ai,
  chatgpt.com, or grok/X to pull subscription usage. That's account
  automation against a consumer product's ToS, not an API integration —
  manual entry is the intended mechanism for these three services.
- Never treat "spend" and "limit" as both API-sourced for Anthropic/OpenAI.
  Only spend comes from the API; limit is always a locally-set budget. Don't
  blur that distinction in UI copy or code comments.
- Never store an API key anywhere but Keychain (no UserDefaults, no plist,
  no logging it even at debug level).
- Never add a retry loop around a 401/403 from a usage endpoint — that means
  the key isn't admin-scoped, not that the request should be retried.
