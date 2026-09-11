# Usage Tracker — interface system

Direction: cherry-blossom paper. A menu-bar glance for a 5-hour week, not a dashboard.

Feel: warm washi, ink bark, one petal accent. Calm enough to live in the menu bar. Dense, because the popover is 308pt wide.

## Signature

Five petals. Default budget is 5 hours, so each petal is one hour. If the budget changes, petals stay five and each one is an equal slice. The remaining-time figure is the focal point. The bloom is how you feel the week.

## Rejected defaults

- Stacked gray progress bars → bloom + compact subscription rows
- SF-only type hierarchy by size → New York (system serif) for the remaining figure, SF for UI, tracking on section labels
- Teal/pink generic “AI tool” palette → washi / bark / petal / pistil

## Depth

Surface-color shifts, not drop shadows. Rows sit one step darker than washi. Hairlines at 10% bark.

## Spacing

Base 4. Micro 4, tight 8, row 12, section 16. Popover width 308.

Radius: chip 8, row 12, bloom container 20. Nested chips follow concentric: outer = inner + padding.

## Type

- Display remaining: system serif 28, regular, tabular
- Menu bar remaining: rounded 12 medium, tabular
- Service name: 13 medium
- Meter: 12 medium tabular
- Section labels: 10 medium, tracking 1.4–1.6, muted
- Caption: 11 regular muted

Four text levels: bark, barkSoft, muted, petalPale (fills only).

## Palette (world names)

Light: washi `#FBF6F1`, row `#F7EEE9`, bark `#2C1F24`, barkSoft `#5C444C`, muted `#6E5359`, petal `#E8A4B8`, petalDeep `#C45C7A`, petalPale `#F7D6E0`, pistil `#C4A574`, over `#7A2E44`

Dark: dusk washi `#1A1216`, row `#241A1F`, bark `#F7EDE8`, muted `#C4A8AE`, same petal, petalPale `#5A3340`

Accent is petal, about 10% of the surface. It means hours used on the bloom. Live "Watching" copy and the now pill use over (`#7A2E44`) so 11pt text stays above 4.5:1 on washi.

## Hierarchy

1. Remaining hours (size + serif + contrast)
2. Bloom
3. "Watching Cursor" caption (live only)
4. Subscription rows (time this week, live row tinted petalPale)
5. Settings / Quit

## Motion

Press scale 0.97, 140ms ease-out. No bloom animation. TimelineView ticks the live session once a second. Honor reduced motion by keeping fills static (already static).

## Components

- BloomView — 112pt hero, 15pt menu-bar glyph, MiniBloom 18pt on rows
- PetalButtonStyle — 11/medium, 10×6 pad, 8 radius, filled uses petalDeep
- ServiceRowView — 12 pad, 12 radius, row fill, models as a truncated caption

## Data split (product, not just visual)

Weekly hour budget is Sophia’s time in matched AI surfaces. Rows are the same clock, split by subscription. No manual log. A new model is a bundle id or host.
