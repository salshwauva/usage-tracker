# Project context

Usage Tracker is a macOS menu bar app (SwiftUI, MenuBarExtra) that shows a
personal weekly hour budget (default 5h) as a five-petal bloom, broken down
by subscription. Time is live: it accrues while a matched desktop app is
frontmost, or while a browser tab host matches the catalog. There are no
API keys, no usage-bar scraping, and no manual logging. A new vendor is a
bundle id and/or URL host on the service, not a new network client.

# Stack

- Swift 5, SwiftUI, Combine
- XcodeGen for project generation (project.yml is the source of truth, not
  the generated .xcodeproj)
- No third-party dependencies. UserDefaults JSON for the weekly log and
  subscription readings. No Keychain. No network.

# Target platform

macOS 14 or later, Apple Silicon and Intel. Do not add iOS/iPadOS targets
unless explicitly asked — this is a menu bar app, not a universal app.

# Architectural rules

- UsageTrackerCore has no SwiftUI imports and no UI code. Models, catalog,
  week math, and persistence live there so they're independently testable.
- Do not add API keys, usage endpoints, or cookie/session scraping. Time
  comes from `ActivityRouter` (bundle id + URL host). `ActivityMonitor` in
  the app target owns NSWorkspace / AppleScript / idle; Core stays testable.
- Service identity is a string id, never a closed enum of vendors. Built-in
  catalog + custom services. `Catalog.merge` must keep working when a new
  built-in is added later.
- Meter kind is stored as a raw string. Unknown future kinds resolve to a
  generic used/limit editor (`count`). Do not crash on decode.
- Models are family names (Opus, GPT, Grok), not dated SKUs.
- Rows are this week's live time per service, not a vendor usage bar.
- `AppState` is the single `ObservableObject` the UI touches.

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
8. Be concrete about uncertainty — if you're unsure a vendor still meters
   a certain way, say so. The meter kind is the escape hatch; don't guess
   a live API.
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

- Never add API-key or scraping paths for subscription usage. Manual entry
  is the mechanism. If a vendor later publishes a real usage API, that is a
  new, explicit feature, not a silent add.
- Never encode a vendor's current meter as the only way that row can work.
  New kinds belong on `MeterKind` plus a Settings editor, not a rewrite of
  the service list.
- Never key persistence on a Swift enum of vendors. String ids only.
- Never treat weekly hours and a vendor usage bar as the same number.
