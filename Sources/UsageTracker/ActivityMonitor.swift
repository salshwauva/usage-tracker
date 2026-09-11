import AppKit
import Combine
import Foundation
import UsageTrackerCore

@MainActor
final class ActivityMonitor: ObservableObject {
    private weak var appState: AppState?
    private var timer: Timer?
    private var workspaceObserver: NSObjectProtocol?
    private var terminateObserver: NSObjectProtocol?

    func start(appState: AppState) {
        self.appState = appState
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 2, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.tick() }
        }
        if let timer {
            RunLoop.main.add(timer, forMode: .common)
        }

        workspaceObserver = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didActivateApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in self?.tick() }
        }

        terminateObserver = NotificationCenter.default.addObserver(
            forName: NSApplication.willTerminateNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in self?.appState?.flushForQuit() }
        }

        tick()
    }

    deinit {
        timer?.invalidate()
        if let workspaceObserver {
            NSWorkspace.shared.notificationCenter.removeObserver(workspaceObserver)
        }
        if let terminateObserver {
            NotificationCenter.default.removeObserver(terminateObserver)
        }
    }

    private func tick() {
        guard let appState else { return }
        let front = NSWorkspace.shared.frontmostApplication
        let bundleID = front?.bundleIdentifier ?? ""
        if bundleID == Bundle.main.bundleIdentifier {
            appState.ingest(sample: nil, idle: false, ownBundle: true)
            return
        }

        let idle = IdleProbe.seconds() >= appState.idleSeconds
        if idle {
            appState.ingest(sample: nil, idle: true)
            return
        }

        var url: URL?
        if BrowserIDs.isBrowser(bundleID) {
            url = BrowserURL.current(bundleID: bundleID)
        }
        let sample = SurfaceSample(bundleID: bundleID, url: url)
        appState.ingest(sample: sample, idle: false)
    }
}
