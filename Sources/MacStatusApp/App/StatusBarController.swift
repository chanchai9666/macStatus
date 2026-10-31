import AppKit
import SwiftUI
import Combine

final class PassThroughHostingView<Content: View>: NSHostingView<Content> {
    override func hitTest(_ point: NSPoint) -> NSView? {
        nil
    }
}

@MainActor
public final class StatusBarController: NSObject, NSPopoverDelegate {
    private let statusItem: NSStatusItem
    private let popover: NSPopover
    private let telemetryService: SystemTelemetryService
    private var timer: Timer?
    private var hostingView: NSView?
    private var lastCloseTime = Date.distantPast
    private var isScreenSleeping = false

    // Fixed width to ensure rock-solid stability and zero jittering (Two-Row Stacked layout)
    private let barWidth: CGFloat = 160.0

    // Efficient interval: 2.0s idle (matching spec), 1.0s when popover is open
    private let idleInterval: TimeInterval = 2.0
    private let activeInterval: TimeInterval = 1.0

    public init(telemetryService: SystemTelemetryService = SystemTelemetryService()) {
        self.telemetryService = telemetryService
        self.statusItem = NSStatusBar.system.statusItem(withLength: barWidth)
        self.popover = NSPopover()

        super.init()

        setupPopover()
        setupStatusItem()
        setupSleepWakeObservers()
        startTimer(interval: idleInterval, includeProcesses: false)
    }

    private func setupPopover() {
        popover.behavior = .transient
        popover.animates = true
        popover.delegate = self
        popover.contentSize = NSSize(width: 300, height: 460)
        popover.contentViewController = NSHostingController(
            rootView: PopoverDetailView(telemetryService: telemetryService, onClose: { [weak self] in
                self?.closePopover()
            })
        )
    }

    private func setupStatusItem() {
        guard let button = statusItem.button else { return }

        button.target = self
        button.action = #selector(statusItemClicked)
        button.sendAction(on: [.leftMouseUp, .rightMouseUp])

        let menuBarView = DynamicMenuBarView(telemetryService: telemetryService)
        let hosting = PassThroughHostingView(rootView: menuBarView)
        hosting.translatesAutoresizingMaskIntoConstraints = false

        button.addSubview(hosting)
        self.hostingView = hosting

        NSLayoutConstraint.activate([
            hosting.leadingAnchor.constraint(equalTo: button.leadingAnchor),
            hosting.trailingAnchor.constraint(equalTo: button.trailingAnchor),
            hosting.topAnchor.constraint(equalTo: button.topAnchor),
            hosting.bottomAnchor.constraint(equalTo: button.bottomAnchor)
        ])
    }

    private func setupSleepWakeObservers() {
        let center = NSWorkspace.shared.notificationCenter

        center.addObserver(forName: NSWorkspace.screensDidSleepNotification, object: nil, queue: .main) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.pauseMonitoring()
            }
        }

        center.addObserver(forName: NSWorkspace.screensDidWakeNotification, object: nil, queue: .main) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.resumeMonitoring()
            }
        }

        center.addObserver(forName: NSWorkspace.sessionDidResignActiveNotification, object: nil, queue: .main) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.pauseMonitoring()
            }
        }

        center.addObserver(forName: NSWorkspace.sessionDidBecomeActiveNotification, object: nil, queue: .main) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.resumeMonitoring()
            }
        }
    }

    private func pauseMonitoring() {
        isScreenSleeping = true
        timer?.invalidate()
        timer = nil
    }

    private func resumeMonitoring() {
        isScreenSleeping = false
        startTimer(interval: idleInterval, includeProcesses: false)
    }

    @objc private func statusItemClicked() {
        if Date().timeIntervalSince(lastCloseTime) < 0.25 {
            return
        }
        togglePopover()
    }

    public func togglePopover() {
        if popover.isShown {
            closePopover()
        } else {
            showPopover()
        }
    }

    public func showPopover() {
        guard let button = statusItem.button else { return }
        telemetryService.updateSnapshot(includeProcesses: true)
        popover.contentSize = NSSize(width: 300, height: 460)
        popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        startTimer(interval: activeInterval, includeProcesses: true)
    }

    public func closePopover() {
        popover.performClose(nil)
        lastCloseTime = Date()
        startTimer(interval: idleInterval, includeProcesses: false)
    }

    // MARK: - NSPopoverDelegate
    public func popoverDidClose(_ notification: Notification) {
        lastCloseTime = Date()
        startTimer(interval: idleInterval, includeProcesses: false)
    }

    private func startTimer(interval: TimeInterval, includeProcesses: Bool) {
        guard !isScreenSleeping else { return }
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self = self, !self.isScreenSleeping else { return }
                let isPopoverActive = self.popover.isShown
                self.telemetryService.updateSnapshot(includeProcesses: isPopoverActive)
            }
        }
    }
}

public struct DynamicMenuBarView: View {
    @ObservedObject public var telemetryService: SystemTelemetryService

    public init(telemetryService: SystemTelemetryService) {
        self.telemetryService = telemetryService
    }

    public var body: some View {
        CircularRingsView(snapshot: telemetryService.currentSnapshot)
    }
}
