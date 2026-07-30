import Foundation
import Combine

@MainActor
public final class AppState: ObservableObject {
    @Published public private(set) var statuses: [ServiceID: ServiceStatus] = [:]
    @Published public var refreshIntervalMinutes: Int {
        didSet { scheduleTimer() }
    }

    private let keychain = KeychainStore()
    private let manualStore = ManualUsageStore.shared
    private let apiProviders: [ServiceID: UsageProvider]
    private var timer: Timer?

    public init(refreshIntervalMinutes: Int = 15) {
        self.refreshIntervalMinutes = refreshIntervalMinutes
        self.apiProviders = [
            ServiceID.anthropicAPI: AnthropicUsageProvider(),
            ServiceID.openAIAPI: OpenAIUsageProvider(),
            ServiceID.xaiAPI: XAIUsageProvider(),
        ]
        for id in ServiceID.allCases {
            statuses[id] = ServiceStatus(service: id, isConfigured: isConfigured(id))
        }
        loadManualSnapshots()
        scheduleTimer()
    }

    public func isConfigured(_ id: ServiceID) -> Bool {
        switch id.kind {
        case .apiBilling:
            return (keychain.key(for: id)?.isEmpty == false)
        case .subscriptionCap:
            return manualStore.snapshot(for: id) != nil
        }
    }

    public func setAPIKey(_ key: String, for id: ServiceID) {
        keychain.setKey(key, for: id)
        statuses[id]?.isConfigured = isConfigured(id)
    }

    public func apiKey(for id: ServiceID) -> String {
        keychain.key(for: id) ?? ""
    }

    public func setManualUsage(used: Double, limit: Double?, unit: String, for id: ServiceID) {
        manualStore.record(used: used, limit: limit, unit: unit, for: id)
        statuses[id]?.snapshot = manualStore.snapshot(for: id)
        statuses[id]?.isConfigured = true
        statuses[id]?.error = nil
    }

    public func setMonthlyBudget(_ budget: Double?, for id: ServiceID) {
        UserDefaults.standard.set(budget, forKey: "ledger.budget.\(id.rawValue)")
    }

    public func monthlyBudget(for id: ServiceID) -> Double? {
        let value = UserDefaults.standard.double(forKey: "ledger.budget.\(id.rawValue)")
        return value > 0 ? value : nil
    }

    private func loadManualSnapshots() {
        for id in ServiceID.allCases where id.kind == .subscriptionCap {
            statuses[id]?.snapshot = manualStore.snapshot(for: id)
        }
    }

    public func refreshAll() {
        for id in ServiceID.allCases where id.kind == .apiBilling {
            refresh(id)
        }
    }

    public func refresh(_ id: ServiceID) {
        guard id.kind == .apiBilling, let provider = apiProviders[id] else { return }
        let key = keychain.key(for: id) ?? ""
        Task { [weak self] in
            guard let self else { return }
            do {
                let budget = self.monthlyBudget(for: id)
                let providerWithBudget = self.budgetedProvider(provider, budget: budget)
                let snapshot = try await providerWithBudget.fetchUsage(apiKey: key)
                await MainActor.run {
                    self.statuses[id]?.snapshot = snapshot
                    self.statuses[id]?.error = nil
                }
            } catch {
                await MainActor.run {
                    self.statuses[id]?.error = error.localizedDescription
                }
            }
        }
    }

    private func budgetedProvider(_ provider: UsageProvider, budget: Double?) -> UsageProvider {
        switch provider.service {
        case .anthropicAPI: return AnthropicUsageProvider(monthlyBudgetUSD: budget)
        case .openAIAPI: return OpenAIUsageProvider(monthlyBudgetUSD: budget)
        default: return provider
        }
    }

    private func scheduleTimer() {
        timer?.invalidate()
        let interval = TimeInterval(max(refreshIntervalMinutes, 1) * 60)
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.refreshAll() }
        }
        refreshAll()
    }
}
