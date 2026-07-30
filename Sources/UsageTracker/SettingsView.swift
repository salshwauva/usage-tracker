import SwiftUI
import UsageTrackerCore

struct SettingsView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        TabView {
            apiKeysTab
                .tabItem { Text("API Keys") }
            subscriptionsTab
                .tabItem { Text("Subscriptions") }
            generalTab
                .tabItem { Text("General") }
        }
        .padding(20)
        .frame(width: 420, height: 320)
    }

    private var apiKeysTab: some View {
        Form {
            Section {
                Text("Admin/organization-scoped API keys. Regular project keys can't read usage.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            apiKeyRow(.anthropicAPI)
            apiKeyRow(.openAIAPI)
            apiKeyRow(.xaiAPI)
        }
        .padding(.top, 8)
    }

    private func apiKeyRow(_ id: ServiceID) -> some View {
        APIKeyRow(service: id)
    }

    private var subscriptionsTab: some View {
        Form {
            Section {
                Text("No service exposes subscription usage via API — enter what you see in each app's own usage indicator.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            ManualUsageRow(service: .claudeSubscription)
            ManualUsageRow(service: .chatGPTSubscription)
            ManualUsageRow(service: .grokSubscription)
        }
        .padding(.top, 8)
    }

    private var generalTab: some View {
        Form {
            Stepper(value: $appState.refreshIntervalMinutes, in: 5...120, step: 5) {
                Text("Refresh every \(appState.refreshIntervalMinutes) min")
            }
        }
        .padding(.top, 8)
    }
}

private struct APIKeyRow: View {
    @EnvironmentObject private var appState: AppState
    let service: ServiceID
    @State private var key: String = ""
    @State private var budgetText: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            SecureField(service.displayName, text: $key)
                .onSubmit { appState.setAPIKey(key, for: service) }
            HStack {
                Text("Monthly budget for the progress bar")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                TextField("USD", text: $budgetText)
                    .frame(width: 70)
                    .onSubmit {
                        appState.setMonthlyBudget(Double(budgetText), for: service)
                    }
            }
        }
        .onAppear {
            key = appState.apiKey(for: service)
            if let budget = appState.monthlyBudget(for: service) {
                budgetText = String(format: "%.0f", budget)
            }
        }
    }
}

private struct ManualUsageRow: View {
    @EnvironmentObject private var appState: AppState
    let service: ServiceID
    @State private var usedText: String = ""
    @State private var limitText: String = ""

    var body: some View {
        HStack {
            Text(service.displayName)
                .frame(width: 100, alignment: .leading)
            TextField("used", text: $usedText)
                .frame(width: 60)
            Text("/")
            TextField("limit", text: $limitText)
                .frame(width: 60)
            Button("Save") {
                guard let used = Double(usedText) else { return }
                appState.setManualUsage(used: used, limit: Double(limitText), unit: "", for: service)
            }
        }
        .onAppear {
            if let snapshot = appState.statuses[service]?.snapshot {
                usedText = String(snapshot.used)
                limitText = snapshot.limit.map { String($0) } ?? ""
            }
        }
    }
}
