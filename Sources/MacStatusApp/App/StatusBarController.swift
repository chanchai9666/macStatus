import AppKit
import SwiftUI
import Combine

@MainActor
public final class StatusBarController: NSObject {
    private let statusItem: NSStatusItem
    private let popover: NSPopover
    private let telemetryService: SystemTelemetryService
    private var timer: Timer?
    private var hostingView: NSHostingView<DynamicMenuBarView>?

    public init(telemetryService: SystemTelemetryService = SystemTelemetryService()) {
        self.telemetryService = telemetryService
        self.statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        self.popover = NSPopover()

        super.init()

        setupPopover()
        setupStatusItem()
        startTimer(interval: 2.0, includeProcesses: false)
    }

    private func setupPopover() {
        popover.behavior = .transient
        popover.animates = true
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
        let hosting = NSHostingView(rootView: menuBarView)
        hosting.translatesAutoresizingMaskIntoConstraints = false

        button.addSubview(hosting)
        self.hostingView = hosting

        NSLayoutConstraint.activate([
            hosting.leadingAnchor.constraint(equalTo: button.leadingAnchor),
            hosting.trailingAnchor.constraint(equalTo: button.trailingAnchor),
            hosting.topAnchor.constraint(equalTo: button.topAnchor),
            hosting.bottomAnchor.constraint(equalTo: button.bottomAnchor)
        ])

        // Force initial layout
        hosting.layout()
        button.frame = hosting.frame
    }

    @objc private func statusItemClicked() {
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
        popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        startTimer(interval: 1.0, includeProcesses: true)
    }

    public func closePopover() {
        popover.performClose(nil)
        startTimer(interval: 2.0, includeProcesses: false)
    }

    private func startTimer(interval: TimeInterval, includeProcesses: Bool) {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                let isPopoverActive = self.popover.isShown
                self.telemetryService.updateSnapshot(includeProcesses: isPopoverActive || includeProcesses)
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
