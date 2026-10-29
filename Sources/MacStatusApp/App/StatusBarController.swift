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

    // Fixed width to ensure rock-solid stability and zero jittering
    private let barWidth: CGFloat = 225.0

    public init(telemetryService: SystemTelemetryService = SystemTelemetryService()) {
        self.telemetryService = telemetryService
        // Set fixed length to prevent jittering/jumping in menu bar
        self.statusItem = NSStatusBar.system.statusItem(withLength: barWidth)
        self.popover = NSPopover()

        super.init()

        setupPopover()
        setupStatusItem()
        startTimer(interval: 2.0, includeProcesses: false)
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
        startTimer(interval: 1.0, includeProcesses: true)
    }

    public func closePopover() {
        popover.performClose(nil)
        lastCloseTime = Date()
        startTimer(interval: 2.0, includeProcesses: false)
    }

    // MARK: - NSPopoverDelegate
    public func popoverDidClose(_ notification: Notification) {
        lastCloseTime = Date()
        startTimer(interval: 2.0, includeProcesses: false)
    }

    private func startTimer(interval: TimeInterval, includeProcesses: Bool) {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
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
