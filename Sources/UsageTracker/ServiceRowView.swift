import SwiftUI
import UsageTrackerCore

struct ServiceRowView: View {
    let service: ServiceID
    let status: ServiceStatus?

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(service.displayName)
                    .font(.subheadline)
                Spacer()
                Text(valueText)
                    .font(.subheadline.monospacedDigit())
                    .foregroundStyle(.secondary)
            }

            if let fraction = status?.snapshot?.fraction {
                ProgressView(value: fraction)
            }

            if let error = status?.error {
                Text(error)
                    .font(.caption2)
                    .foregroundStyle(.red)
                    .lineLimit(2)
            } else if status?.isConfigured != true {
                Text("Not configured")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            } else if let fetchedAt = status?.snapshot?.fetchedAt {
                Text(fetchedAt, style: .relative)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(8)
        .background(Color.gray.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private var valueText: String {
        guard let snapshot = status?.snapshot else { return "—" }
        if snapshot.unit == "USD" {
            let used = String(format: "$%.2f", snapshot.used)
            if let limit = snapshot.limit {
                return "\(used) / $\(String(format: "%.0f", limit))"
            }
            return used
        }
        if let limit = snapshot.limit {
            return "\(Int(snapshot.used))\(snapshot.unit) / \(Int(limit))\(snapshot.unit)"
        }
        return "\(Int(snapshot.used))\(snapshot.unit)"
    }
}
