# macOS M-Series Hardware Status Monitor Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a native, lightweight macOS Menu Bar hardware status monitor for Apple Silicon M-Series with Circular Activity Rings (CPU, RAM, SSD) + live Network Throughput & SoC Temperature, opening a detailed Apple-styled telemetry popover upon click.

**Architecture:** A native Swift 6 / AppKit / SwiftUI application compiled via Swift Package Manager (SPM). Telemetry gathers metrics via low-overhead Darwin/Mach kernel APIs (`host_processor_info`, `vm_statistics64`, `statfs`, `getifaddrs`, `libproc`, and `IOHIDEventSystemClient` for SoC thermals). An `NSStatusItem` hosts a SwiftUI `CircularRingsView` on the menu bar, which anchors an `NSPopover` containing `PopoverDetailView` with adaptive timer intervals (2s idle, 1s popover open).

**Tech Stack:** Swift 6.3+, AppKit (`NSStatusItem`, `NSPopover`), SwiftUI, Darwin/Mach APIs, IOKit/IOHIDEventSystem, SPM.

**Spec:** `docs/superpowers/specs/2026-10-29-mac-status-monitor-design.md`

## Global Constraints

- Platform: macOS 13.0+ (Ventura, Sonoma, Sequoia+), Apple Silicon arm64 target.
- Memory & CPU budgets: Idle CPU `< 0.5%`, memory `< 30 MB`.
- Distribution: Local native non-sandboxed utility, requiring no root/daemon permissions.
- Menu Bar item UI: Option 2 Circular Activity Rings (CPU blue, RAM green, SSD orange) + `⇅ Net` + `Temp °C`.
- Code layout: Modular Swift Package under `Sources/MacStatusApp` and `Tests/MacStatusAppTests`.

## Review Focus

1. Zero division in core delta math: When sampling CPU or Network deltas on the first tick or during clock reset, avoid `NaN` or crashes.
2. Inactive / Sleep wake cycle: When MacBook sleeps and wakes, network and CPU ticks must not report artificial spikes (e.g., millions of MB/s delta).
3. Fallback for SoC temperature: If IOHIDEventSystem temperature sensor fails or returns nil on a specific M-chip, fall back cleanly without crashing to `ProcessInfo.thermalState`.
4. Popover dismiss on outside click: Popover must close smoothly when clicking anywhere on the desktop or other menu items without memory leaks.
5. High process list performance: Reading top processes via `libproc` must be executed only when the popover is actively displayed and never in the background menu bar loop.

---

### Task 1: Project Scaffolding & SPM Package Setup

**Files:**
- Create: `Package.swift`
- Create: `Sources/MacStatusApp/main.swift`
- Test: `Tests/MacStatusAppTests/PackageTests.swift`

**Interfaces:**
- Produces: Executable target `MacStatusApp` and test target `MacStatusAppTests`.

- [ ] **Step 1: Write the failing test**

In `Tests/MacStatusAppTests/PackageTests.swift`:
```swift
import Testing

@Suite("Package Initialization Tests")
struct PackageTests {
    @Test func testPackageTargetBuilds() {
        #expect(true)
    }
}
```

- [ ] **Step 2: Run test to verify it fails (missing Package.swift)**

Run: `swift test`  
Expected: FAIL with missing Package.swift or manifest error.

- [ ] **Step 3: Create `Package.swift` and initial entry point**

Create `Package.swift`:
```swift
// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "MacStatusApp",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "MacStatusApp", targets: ["MacStatusApp"])
    ],
    targets: [
        .executableTarget(
            name: "MacStatusApp",
            path: "Sources/MacStatusApp"
        ),
        .testTarget(
            name: "MacStatusAppTests",
            dependencies: ["MacStatusApp"],
            path: "Tests/MacStatusAppTests"
        )
    ]
)
```
Create `Sources/MacStatusApp/main.swift`:
```swift
import AppKit

let app = NSApplication.shared
app.setActivationPolicy(.accessory)
print("MacStatusApp initialized")
```

- [ ] **Step 4: Run test to verify it passes**

Run: `swift test`  
Expected: PASS with 1 test executed.

- [ ] **Step 5: Commit**

```bash
git add Package.swift Sources/ Tests/
git commit -m "chore: setup Swift package and initial project scaffolding"
```

---

### Task 2: Telemetry Data Models & Math Utilities

**Files:**
- Create: `Sources/MacStatusApp/Telemetry/Models.swift`
- Create: `Sources/MacStatusApp/Telemetry/Formatters.swift`
- Test: `Tests/MacStatusAppTests/TelemetryModelTests.swift`

**Interfaces:**
- Produces: `CPUStats`, `RAMStats`, `DiskStats`, `NetworkStats`, `ThermalStats`, `TopProcessItem`, `SystemSnapshot`, and byte/speed formatters (`Formatters.formatSpeed`, `Formatters.formatBytes`).

- [ ] **Step 1: Write the failing tests**

In `Tests/MacStatusAppTests/TelemetryModelTests.swift`:
```swift
import Testing
@testable import MacStatusApp

@Suite("Telemetry Models and Formatters Tests")
struct TelemetryModelTests {
    @Test func testByteFormatting() {
        #expect(Formatters.formatBytes(1024) == "1.0 KB")
        #expect(Formatters.formatBytes(1048576 * 154) == "154.0 GB")
    }

    @Test func testSpeedFormatting() {
        #expect(Formatters.formatSpeed(1500) == "1.5 KB/s")
        #expect(Formatters.formatSpeed(1572864) == "1.5 MB/s")
    }

    @Test func testClampPercentages() {
        #expect(Formatters.clampPercentage(-5.0) == 0.0)
        #expect(Formatters.clampPercentage(105.0) == 100.0)
        #expect(Formatters.clampPercentage(42.5) == 42.5)
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `swift test --filter TelemetryModelTests`  
Expected: FAIL (Cannot find `Formatters` in scope).

- [ ] **Step 3: Implement Models and Formatters**

In `Sources/MacStatusApp/Telemetry/Models.swift`:
Define `CPUStats`, `RAMStats`, `DiskStats`, `NetworkStats`, `ThermalStats`, `TopProcessItem`, `SystemSnapshot`.
In `Sources/MacStatusApp/Telemetry/Formatters.swift`:
Implement `formatBytes(_ bytes: Int64) -> String`, `formatSpeed(_ bytesPerSec: Double) -> String`, `clampPercentage(_ value: Double) -> Double`.

- [ ] **Step 4: Run test to verify it passes**

Run: `swift test --filter TelemetryModelTests`  
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add Sources/MacStatusApp/Telemetry Tests/MacStatusAppTests/TelemetryModelTests.swift
git commit -m "feat: add telemetry data models and formatting utilities"
```

---

### Task 3: Darwin & Mach Hardware Telemetry Providers

**Files:**
- Create: `Sources/MacStatusApp/Telemetry/CPUMonitor.swift`
- Create: `Sources/MacStatusApp/Telemetry/MemoryMonitor.swift`
- Create: `Sources/MacStatusApp/Telemetry/DiskMonitor.swift`
- Create: `Sources/MacStatusApp/Telemetry/NetworkMonitor.swift`
- Create: `Sources/MacStatusApp/Telemetry/ThermalMonitor.swift`
- Create: `Sources/MacStatusApp/Telemetry/ProcessMonitor.swift`
- Test: `Tests/MacStatusAppTests/TelemetryProviderTests.swift`

**Interfaces:**
- Produces: `SystemTelemetryService` combining `CPUMonitor`, `MemoryMonitor`, `DiskMonitor`, `NetworkMonitor`, `ThermalMonitor`, `ProcessMonitor`.
- Consumes: Models from Task 2.

- [ ] **Step 1: Write the failing tests**

In `Tests/MacStatusAppTests/TelemetryProviderTests.swift`:
```swift
import Testing
@testable import MacStatusApp

@Suite("Hardware Telemetry Providers Tests")
struct TelemetryProviderTests {
    @Test func testMemoryMonitorReturnsValidStats() {
        let mem = MemoryMonitor()
        let stats = mem.sample()
        #expect(stats.totalBytes > 0)
        #expect(stats.usedBytes > 0)
        #expect(stats.usagePercentage >= 0.0 && stats.usagePercentage <= 100.0)
    }

    @Test func testDiskMonitorReturnsRootVolume() {
        let disk = DiskMonitor()
        let stats = disk.sample()
        #expect(stats.totalBytes > 0)
        #expect(stats.freeBytes > 0)
        #expect(stats.usedPercentage >= 0.0 && stats.usedPercentage <= 100.0)
    }

    @Test func testThermalMonitorReturnsReasonableTemperature() {
        let thermal = ThermalMonitor()
        let stats = thermal.sample()
        #expect(stats.celsius >= 15.0 && stats.celsius <= 115.0)
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `swift test --filter TelemetryProviderTests`  
Expected: FAIL (Cannot find `MemoryMonitor`, `DiskMonitor`, etc.).

- [ ] **Step 3: Implement Telemetry Providers**

- `CPUMonitor`: Uses `host_processor_info(mach_host_self(), PROCESSOR_CPU_LOAD_INFO, ...)` with previous tick caching to calculate delta percentage, plus core type detection.
- `MemoryMonitor`: Uses `host_statistics64(mach_host_self(), HOST_VM_INFO64, ...)` to parse active, inactive, wired, compressed pages.
- `DiskMonitor`: Uses `statfs("/")` to compute free/used/total bytes and track I/O deltas.
- `NetworkMonitor`: Uses `getifaddrs` to iterate interfaces and accumulate `ifa_data.ifi_ibytes` / `ifi_obytes`.
- `ThermalMonitor`: Calls `IOHIDEventSystemClientCreate` or reads `ProcessInfo.processInfo.thermalState` fallback to extract temperature in Celsius.
- `ProcessMonitor`: Uses `libproc` (`proc_listallpids`, `proc_pidinfo`) to identify Top 3 CPU and Top 3 Memory processes.

- [ ] **Step 4: Run test to verify it passes**

Run: `swift test --filter TelemetryProviderTests`  
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add Sources/MacStatusApp/Telemetry Tests/MacStatusAppTests/TelemetryProviderTests.swift
git commit -m "feat: implement native Darwin, Mach, and IOHID telemetry providers"
```

---

### Task 4: Menu Bar UI — SwiftUI Circular Activity Rings View

**Files:**
- Create: `Sources/MacStatusApp/UI/CircularRingsView.swift`
- Create: `Sources/MacStatusApp/UI/RingGauge.swift`
- Test: `Tests/MacStatusAppTests/UIModelTests.swift`

**Interfaces:**
- Produces: `CircularRingsView` (SwiftUI view with 3 mini ring gauges for CPU, RAM, SSD, and text indicators for Net throughput & Temperature).
- Consumes: `SystemSnapshot` from Task 2.

- [ ] **Step 1: Write unit test for Ring Gauge Angle and Arc Calculations**

In `Tests/MacStatusAppTests/UIModelTests.swift`:
```swift
import Testing
@testable import MacStatusApp

@Suite("UI Gauge Geometry Tests")
struct UIModelTests {
    @Test func testRingAngleMath() {
        #expect(RingMath.trimFraction(percentage: 0.0) == 0.0)
        #expect(RingMath.trimFraction(percentage: 50.0) == 0.5)
        #expect(RingMath.trimFraction(percentage: 100.0) == 1.0)
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `swift test --filter UIModelTests`  
Expected: FAIL (`RingMath` not found).

- [ ] **Step 3: Implement `RingGauge` and `CircularRingsView`**

In `Sources/MacStatusApp/UI/RingGauge.swift`:
- `RingMath` helper to clamp fractions between 0.0 and 1.0.
- `RingGauge`: Reusable SwiftUI circular progress ring with custom background stroke and animated foreground arc with rounded line caps.
In `Sources/MacStatusApp/UI/CircularRingsView.swift`:
- Render the 3 circular activity rings:
  - CPU: Blue `#0A84FF`
  - RAM: Green `#30D158`
  - SSD: Orange `#FF9F0A`
- Render Network badge: `⇅ 1.2M` with monospace font.
- Render SoC Temperature badge: `42°` with thermometer icon or colored temperature degree.

- [ ] **Step 4: Run test to verify it passes**

Run: `swift test --filter UIModelTests`  
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add Sources/MacStatusApp/UI/ Tests/MacStatusAppTests/UIModelTests.swift
git commit -m "feat: add SwiftUI Circular Activity Rings menu bar view"
```

---

### Task 5: Interactive Detailed Popover View

**Files:**
- Create: `Sources/MacStatusApp/UI/PopoverDetailView.swift`
- Create: `Sources/MacStatusApp/UI/Components/MetricCard.swift`
- Create: `Sources/MacStatusApp/UI/Components/ProcessListView.swift`

**Interfaces:**
- Produces: `PopoverDetailView` (rich Apple-style translucent popover with full breakdowns of CPU, Unified Memory, SSD, Network, SoC Thermals, and launch button for Activity Monitor).
- Consumes: `SystemSnapshot` and `SystemTelemetryService`.

- [ ] **Step 1: Write unit test verifying snapshot formatting in Popover components**

In `Tests/MacStatusAppTests/PopoverViewTests.swift`:
```swift
import Testing
@testable import MacStatusApp

@Suite("Popover Component Tests")
struct PopoverViewTests {
    @Test func testProcessItemFormatting() {
        let item = TopProcessItem(name: "Google Chrome", pid: 1234, cpuPercent: 14.5, memoryBytes: 2147483648)
        #expect(item.formattedMemory == "2.0 GB")
        #expect(item.formattedCPU == "14.5%")
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `swift test --filter PopoverViewTests`  
Expected: FAIL (`TopProcessItem` properties not yet declared).

- [ ] **Step 3: Implement Popover Views**

- `MetricCard`: Reusable glass card container with title, metric badge, and progress indicator.
- `ProcessListView`: List showing top 3 processes with name and consumption values.
- `PopoverDetailView`:
  - Header: Machine chip identifier (Apple Silicon) and status indicator.
  - Section 1: CPU with E-Cores vs P-Cores progress bars and Top 3 CPU processes.
  - Section 2: Unified Memory with App / Wired / Compressed breakdown and Top 3 Memory processes.
  - Section 3: Macintosh HD storage progress bar and Disk I/O activity (Read/Write MB/s).
  - Section 4: Network 2-column card (Upload / Download speed, active IP).
  - Section 5: SoC Thermal state & Celsius temperature.
  - Bottom bar: "Open Activity Monitor" action button and "Quit" menu.

- [ ] **Step 4: Run test to verify it passes**

Run: `swift test --filter PopoverViewTests`  
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add Sources/MacStatusApp/UI/ Tests/MacStatusAppTests/PopoverViewTests.swift
git commit -m "feat: implement rich detailed Popover view"
```

---

### Task 6: AppKit Status Item Controller, Popover Lifecycle & App Integration

**Files:**
- Create: `Sources/MacStatusApp/App/StatusBarController.swift`
- Modify: `Sources/MacStatusApp/main.swift`

**Interfaces:**
- Produces: Complete running menu bar accessory application.
- Coordinates: `NSStatusItem`, `NSPopover`, and `SystemTelemetryService`.

- [ ] **Step 1: Implement `StatusBarController`**

In `Sources/MacStatusApp/App/StatusBarController.swift`:
- Initialize `NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)`.
- Wrap `CircularRingsView` inside an `NSHostingView` attached to the status item's button.
- Attach an `NSPopover` hosting `PopoverDetailView` with `.transient` behavior (auto-close when clicking outside).
- Configure adaptive timer:
  - 2-second timer when popover is closed (samples menu bar metrics only).
  - 1-second timer when popover is open (samples full telemetry including top processes).
- Connect button click to toggle popover presentation.

- [ ] **Step 2: Update `main.swift`**

In `Sources/MacStatusApp/main.swift`:
- Set `NSApplication.shared.setActivationPolicy(.accessory)` to hide from Dock.
- Instantiate `StatusBarController`.
- Call `NSApplication.shared.run()`.

- [ ] **Step 3: Build executable and run test suite**

Run: `swift test && swift build -c release`  
Expected: PASS all tests and compile binary `.build/release/MacStatusApp` with 0 warnings.

- [ ] **Step 4: Commit**

```bash
git add Sources/MacStatusApp/App Sources/MacStatusApp/main.swift
git commit -m "feat: connect status bar controller and app lifecycle"
```

---

### Task 7: App Bundle Packaging & End-to-End Verification

**Files:**
- Create: `scripts/build-app.sh`
- Create: `Resources/Info.plist`

**Interfaces:**
- Produces: Standalone `MacStatus.app` macOS application bundle ready to run or install in `/Applications`.

- [ ] **Step 1: Create `Resources/Info.plist`**

Set:
- `CFBundleIdentifier`: `com.chanchai.macStatus`
- `CFBundleName`: `MacStatus`
- `CFBundlePackageType`: `APPL`
- `LSUIElement`: `YES` (Ensures it is pure menu bar app with no Dock presence)

- [ ] **Step 2: Create `scripts/build-app.sh`**

Script to compile via `swift build -c release`, assemble `MacStatus.app/Contents/MacOS/MacStatusApp`, embed `Info.plist`, and code-sign with ad-hoc identity (`codesign -s - --force`).

- [ ] **Step 3: Run build script and verify app launch**

Run:
```bash
chmod +x scripts/build-app.sh
./scripts/build-app.sh
```
Verify:
1. `build/MacStatus.app` exists.
2. Executable runs cleanly and reports status.

- [ ] **Step 4: Commit**

```bash
git add scripts/ Resources/
git commit -m "chore: create app bundle packaging script and Info.plist"
```
