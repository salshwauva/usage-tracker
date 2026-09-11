import SwiftUI
import UsageTrackerCore

struct ServiceRowView: View {
    let service: Service
    let hoursUsed: Double
    let budgetHours: Double
    let isLive: Bool

    @Environment(\.palette) private var palette

    var body: some View {
        HStack(alignment: .center, spacing: Space.tight) {
            MiniBloom(
                fraction: budgetHours > 0 ? min(hoursUsed / budgetHours, 1) : 0,
                over: hoursUsed > budgetHours && budgetHours > 0
            )

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(service.displayName)
                        .font(Typeface.ui(13, weight: .medium))
                        .foregroundStyle(palette.bark)
                        .lineLimit(1)
                    if isLive {
                        Text("now")
                            .font(Typeface.label(9))
                            .tracking(0.8)
                            .foregroundStyle(palette.over)
                    }
                }

                if !service.models.isEmpty {
                    Text(service.models.prefix(3).joined(separator: " · "))
                        .font(Typeface.ui(10))
                        .foregroundStyle(palette.muted)
                        .lineLimit(1)
                }
            }

            Spacer(minLength: 8)

            Text(hoursUsed > 0.001 ? DurationFormat.longHours(hoursUsed) : "—")
                .font(Typeface.ui(12, weight: .medium).monospacedDigit())
                .foregroundStyle(hoursUsed > 0.001 ? palette.barkSoft : palette.muted)
        }
        .padding(.horizontal, Space.row)
        .padding(.vertical, 10)
        .background(isLive ? palette.petalPale.opacity(0.55) : palette.row)
        .clipShape(RoundedRectangle(cornerRadius: Radius.row, style: .continuous))
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityText)
    }

    private var accessibilityText: String {
        var text = "\(service.displayName), \(DurationFormat.longHours(hoursUsed)) this week"
        if isLive { text += ", watching now" }
        return text
    }
}
