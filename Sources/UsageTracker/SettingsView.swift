import SwiftUI
import UsageTrackerCore

struct SettingsView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.colorScheme) private var scheme

    private var palette: Palette { Palette.current(scheme) }

    var body: some View {
        TabView {
            weekTab
                .tabItem { Text("Week") }
            servicesTab
                .tabItem { Text("Subscriptions") }
        }
        .padding(Space.section)
        .frame(width: 480, height: 440)
        .background(palette.washi)
        .environment(\.palette, palette)
    }

    private var weekTab: some View {
        Form {
            Section {
                Stepper(value: $appState.weeklyBudgetHours, in: 1...40, step: 0.5) {
                    Text("Weekly budget  \(DurationFormat.longHours(appState.weeklyBudgetHours))")
                }
                Picker("Week starts", selection: $appState.firstWeekday) {
                    Text("Monday").tag(2)
                    Text("Sunday").tag(1)
                }
                Stepper(value: $appState.idleSeconds, in: 30...600, step: 15) {
                    Text("Pause after \(Int(appState.idleSeconds))s idle")
                }
            }

            Section("This week") {
                let entries = appState.entriesThisWeek()
                if appState.isWatching, let name = appState.watchingName {
                    Text("Watching \(name)")
                }
                if entries.isEmpty {
                    Text("No tracked time yet. Open Claude, Cursor, ChatGPT, or a matched site.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(entries) { entry in
                        HStack {
                            Text(label(for: entry))
                            Spacer()
                            Text(DurationFormat.longHours(entry.hours))
                                .monospacedDigit()
                            Button("Remove", role: .destructive) {
                                appState.removeEntry(entry.id)
                            }
                        }
                    }
                }
            }
        }
        .formStyle(.grouped)
    }

    private var servicesTab: some View {
        VStack(alignment: .leading, spacing: Space.tight) {
            Text("Time counts while the desktop app is frontmost, or while a browser tab matches a host. Add a bundle id or host when a vendor ships a new app. No API keys.")
                .font(Typeface.ui(11))
                .foregroundStyle(palette.muted)
                .fixedSize(horizontal: false, vertical: true)

            List {
                ForEach(appState.services) { service in
                    ServiceEditor(serviceID: service.id)
                }
            }
            .listStyle(.inset)
            .scrollContentBackground(.hidden)

            AddCustomServiceRow()
        }
    }

    private func label(for entry: TimeEntry) -> String {
        if let id = entry.serviceID, let name = appState.service(id: id)?.displayName {
            return name
        }
        return "Unassigned"
    }
}

private struct ServiceEditor: View {
    @EnvironmentObject private var appState: AppState
    let serviceID: String

    @State private var modelsText = ""
    @State private var bundlesText = ""
    @State private var hostsText = ""

    var body: some View {
        if let service = appState.service(id: serviceID) {
            DisclosureGroup {
                VStack(alignment: .leading, spacing: 8) {
                    TextField("Models (comma separated)", text: $modelsText)
                        .onSubmit { saveModels(service) }
                    TextField("App bundle ids", text: $bundlesText)
                        .onSubmit { saveSources(service) }
                    TextField("Site hosts", text: $hostsText)
                        .onSubmit { saveSources(service) }
                    if !service.isBuiltIn {
                        Button("Remove subscription", role: .destructive) {
                            appState.removeService(service.id)
                        }
                    }
                }
                .padding(.vertical, 4)
            } label: {
                Toggle(isOn: enabledBinding(service)) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(service.displayName)
                        Text(sourceCaption(service))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }
                }
            }
            .onAppear { load(service) }
        }
    }

    private func sourceCaption(_ service: Service) -> String {
        let apps = service.bundleIDs.isEmpty ? [] : ["apps"]
        let sites = service.urlHosts.prefix(3)
        let parts = apps + sites
        if parts.isEmpty { return service.vendor }
        return ([service.vendor] + parts).joined(separator: " · ")
    }

    private func load(_ service: Service) {
        modelsText = service.models.joined(separator: ", ")
        bundlesText = service.bundleIDs.joined(separator: ", ")
        hostsText = service.urlHosts.joined(separator: ", ")
    }

    private func saveModels(_ service: Service) {
        appState.updateModels(csv(modelsText), for: service.id)
    }

    private func saveSources(_ service: Service) {
        appState.updateSources(bundleIDs: csv(bundlesText), urlHosts: csv(hostsText), for: service.id)
    }

    private func csv(_ text: String) -> [String] {
        text.split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    private func enabledBinding(_ service: Service) -> Binding<Bool> {
        Binding(
            get: { appState.service(id: service.id)?.enabled ?? service.enabled },
            set: { appState.setEnabled($0, for: service.id) }
        )
    }
}

private struct AddCustomServiceRow: View {
    @EnvironmentObject private var appState: AppState
    @State private var name = ""
    @State private var vendor = ""
    @State private var bundle = ""
    @State private var host = ""

    var body: some View {
        HStack {
            TextField("New subscription", text: $name)
            TextField("bundle.id", text: $bundle)
                .frame(width: 120)
            TextField("host.com", text: $host)
                .frame(width: 100)
            Button("Add") {
                let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !trimmed.isEmpty else { return }
                appState.addCustom(
                    name: trimmed,
                    vendor: vendor,
                    bundleIDs: bundle.isEmpty ? [] : [bundle.trimmingCharacters(in: .whitespaces)],
                    urlHosts: host.isEmpty ? [] : [host.trimmingCharacters(in: .whitespaces)]
                )
                name = ""
                vendor = ""
                bundle = ""
                host = ""
            }
        }
    }
}
