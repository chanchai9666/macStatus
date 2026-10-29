import AppKit

@MainActor
func main() {
    let app = NSApplication.shared
    app.setActivationPolicy(.accessory)

    let controller = StatusBarController()
    _ = controller // Retain controller

    app.run()
}

main()
