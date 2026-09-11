import SwiftUI
import UsageTrackerCore

struct ContentView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.colorScheme) private var scheme

    private var palette: Palette { Palette.current(scheme) }

    var body: some View {
        TimelineView(.periodic(from: .now, by: appState.isWatching ? 1 : 15)) { context in
            let budget = appState.budget(now: context.date)
            VStack(spacing: 0) {
                hero(budget, now: context.date)
                Divider().overlay(palette.hairline)
                subscriptions(now: context.date)
                Divider().overlay(palette.hairline)
                footer
            }
            .frame(width: Space.popoverWidth)
            .background(palette.washi)
            .environment(\.palette, palette)
        }
    }

    private func hero(_ budget: WeeklyBudget, now: Date) -> some View {
        VStack(spacing: Space.tight) {
            Text("THIS WEEK")
                .font(Typeface.label(10))
                .tracking(1.6)
                .foregroundStyle(palette.muted)

            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [palette.petalPale.opacity(0.9), palette.washi.opacity(0)],
                            center: .center,
                            startRadius: 8,
                            endRadius: 78
                        )
                    )
                    .frame(width: 156, height: 156)

                BloomView(budget: budget, size: 112, showsPistil: true)
            }
            .frame(height: 124)

            Text(heroFigure(budget))
                .font(Typeface.display(28))
                .monospacedDigit()
                .foregroundStyle(budget.isOver ? palette.over : palette.bark)
                .accessibilityAddTraits(.isHeader)

            Text(heroCaption(budget, now: now))
                .font(Typeface.ui(11))
                .foregroundStyle(appState.isWatching ? palette.over : palette.muted)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, Space.section)
        .padding(.bottom, Space.section)
        .padding(.horizontal, Space.section)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityHero(budget, now: now))
    }

    private func subscriptions(now: Date) -> some View {
        VStack(alignment: .leading, spacing: Space.tight) {
            Text("WATCHING")
                .font(Typeface.label(10))
                .tracking(1.4)
                .foregroundStyle(palette.muted)
                .padding(.horizontal, 4)

            if appState.enabledServices.isEmpty {
                Text("Turn on a subscription in Settings. Add a bundle id or site if a new model shows up.")
                    .font(Typeface.ui(11))
                    .foregroundStyle(palette.muted)
                    .padding(.horizontal, 4)
                    .padding(.vertical, Space.tight)
            } else {
                ScrollView {
                    VStack(spacing: Space.micro + 2) {
                        ForEach(appState.enabledServices) { service in
                            ServiceRowView(
                                service: service,
                                hoursUsed: appState.hoursUsed(now: now, serviceID: service.id),
                                budgetHours: appState.weeklyBudgetHours,
                                isLive: appState.isWatching && appState.sessionServiceID == service.id
                            )
                        }
                    }
                }
                .frame(maxHeight: 260)
            }
        }
        .padding(.horizontal, Space.section)
        .padding(.vertical, Space.row)
    }

    private var footer: some View {
        HStack {
            SettingsLink {
                Text("Settings")
            }
            .buttonStyle(PetalButtonStyle())
            Spacer()
            Button("Quit") { NSApplication.shared.terminate(nil) }
                .buttonStyle(PetalButtonStyle())
        }
        .padding(.horizontal, Space.section)
        .padding(.vertical, 10)
    }

    private func heroFigure(_ budget: WeeklyBudget) -> String {
        if budget.isOver {
            return DurationFormat.longHours(budget.hoursUsed - budget.hoursLimit) + " over"
        }
        return DurationFormat.longHours(budget.hoursRemaining) + " left"
    }

    private func heroCaption(_ budget: WeeklyBudget, now: Date) -> String {
        let used = "\(DurationFormat.longHours(budget.hoursUsed)) of \(DurationFormat.longHours(budget.hoursLimit))"
        if appState.isIdle {
            return "Idle · \(used)"
        }
        if let name = appState.watchingName, appState.isWatching {
            return "Watching \(name) · \(used)"
        }
        return used
    }

    private func accessibilityHero(_ budget: WeeklyBudget, now: Date) -> String {
        heroCaption(budget, now: now)
    }
}

struct PetalButtonStyle: ButtonStyle {
    var filled: Bool = false

    @Environment(\.palette) private var palette

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Typeface.ui(11, weight: .medium))
            .foregroundStyle(filled ? palette.washi : palette.bark)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: Radius.chip, style: .continuous)
                    .fill(filled ? palette.over : palette.row)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Radius.chip, style: .continuous)
                    .stroke(palette.hairline, lineWidth: filled ? 0 : 1)
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.easeOut(duration: Motion.press), value: configuration.isPressed)
            .opacity(configuration.isPressed ? 0.9 : 1)
    }
}
