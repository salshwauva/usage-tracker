import SwiftUI
import LedgerCore

struct ContentView: View {
    @EnvironmentObject private var appState: AppState

    private let apiServices: [ServiceID] = [.anthropicAPI, .openAIAPI, .xaiAPI]
    private let subscriptionServices: [ServiceID] = [.claudeSubscription, .chatGPTSubscription, .grokSubscription]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    section(title: "API billing", services: apiServices)
                    section(title: "Subscriptions", services: subscriptionServices)
                }
                .padding(12)
            }

            Divider()

            HStack {
                Button("Refresh") { appState.refreshAll() }
                Spacer()
                SettingsLink { Text("Settings…") }
                Button("Quit") { NSApplication.shared.terminate(nil) }
            }
            .padding(10)
        }
        .frame(width: 320)
    }

    private var header: some View {
        HStack {
            Text("Ledger")
                .font(.headline)
            Spacer()
        }
        .padding(12)
    }

    private func section(title: String, services: [ServiceID]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            ForEach(services) { id in
                ServiceRowView(service: id, status: appState.statuses[id])
            }
        }
    }
}
