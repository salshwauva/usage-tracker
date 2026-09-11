import SwiftUI
import UsageTrackerCore

struct MenuBarLabel: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        TimelineView(.periodic(from: .now, by: appState.isWatching ? 1 : 15)) { context in
            let budget = appState.budget(now: context.date)
            HStack(spacing: 5) {
                BloomView(budget: budget, size: 15, showsPistil: false)
                Text(DurationFormat.remaining(budget.hoursRemaining))
                    .font(.system(size: 12, weight: .medium, design: .rounded).monospacedDigit())
            }
            .environment(\.palette, Palette.current(scheme))
            .accessibilityLabel(label(budget))
        }
    }

    private func label(_ budget: WeeklyBudget) -> String {
        if budget.isOver {
            return "Over weekly budget by \(DurationFormat.longHours(budget.hoursUsed - budget.hoursLimit))"
        }
        return "\(DurationFormat.longHours(budget.hoursRemaining)) left of \(DurationFormat.longHours(budget.hoursLimit)) this week"
    }
}
