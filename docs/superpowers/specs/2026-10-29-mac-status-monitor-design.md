# macOS M-Series Hardware Status Monitor — Design Specification

**Date:** 2026-10-29  
**Status:** Approved  
**Target Platform:** macOS (Apple Silicon M-Series: M1/M2/M3/M4/etc.)  
**Technology Stack:** Swift 6, AppKit (`NSStatusItem`, `NSPopover`), SwiftUI, Darwin / Mach APIs, IOKit / IOHIDEventSystem  
**Distribution / Sandbox Model:** Local Native Application (Non-Sandboxed / Developer ID compatible)  

---

## 1. Intent & Why

Users of MacBook Apple Silicon (M-Series) lack a native, lightweight, and clutter-free hardware status monitor in the macOS Menu Bar. Existing third-party apps are often heavy, subscription-based, or cluttered with unnecessary widgets. The user wants a clean, beautifully designed hardware monitor residing directly in the macOS menu bar that gives an immediate overview of system health at a glance (CPU, RAM, SSD, Network, Temperature) and opens an elegant detailed popover when clicked.

---

## 2. Goals, Non-Goals, and Anti-Goals

### Goals
- **Menu Bar Display:** Render a compact, native status item containing Circular Activity Rings for CPU, RAM, and SSD, alongside real-time Network Throughput (`⇅ 1.2M`) and SoC Temperature (`42°C`).
- **Interactive Detailed Popover:** Clicking the status item smoothly opens an Apple-style popover displaying deep telemetry:
  - **CPU:** Total %, E-Cores vs P-Cores breakdown, and Top 3 CPU-consuming processes.
  - **Unified Memory (RAM):** Used / Total GB, App Memory, Wired, Compressed, Memory Pressure, and Top 3 Memory-consuming processes.
  - **Storage (SSD):** Free / Used / Total space, and live Read/Write I/O throughput.
  - **Network:** Real-time Download and Upload speeds, active network interface, and local IP.
  - **Thermal & SoC:** Apple Silicon SoC temperature (exact °C via IOHIDEventSystem), Thermal Pressure State (`nominal`, `fair`, `serious`), and fan speed (if equipped).
  - **Quick Actions:** One-click shortcut to launch macOS `Activity Monitor.app` and an option to quit or configure.
- **Performance & Efficiency:** CPU consumption under normal conditions must remain `< 0.5%` and memory usage `< 30 MB`. Must pause/throttle telemetry when the popover is closed, keeping only lightweight metric updates for the menu bar.
- **Local Native Utility:** Runs directly as a native macOS application compiled with Swift Package Manager (SPM).

### Non-Goals
- Mac App Store sandbox compliance (requires full hardware access for °C thermal sensors and system process tables).
- Hardware tuning or overclocking / fan-speed manual override (monitoring only).
- Cloud sync or external telemetry tracking.
- Full process manager (kill process, renice, etc. — users can jump to Activity Monitor for management).

### Anti-Goals
- **No Heavy Electron / Webview Wrapper:** Must be 100% native Swift/SwiftUI/AppKit.
- **No Menu Bar Clutter:** Avoid taking up unnecessary horizontal width on MacBooks with a screen notch.

---

## 3. Constraints & Compatibility

- **OS Compatibility:** macOS 13.0+ (Ventura, Sonoma, Sequoia and newer).
- **Architecture:** `arm64` (Apple Silicon M1, M2, M3, M4 and variations: Pro, Max, Ultra).
- **Permissions:** Standard user permissions (non-sandboxed). Telemetry using Darwin/Mach kernel interfaces (`mach_host`, `vm_statistics64`, `sysctl`, `getifaddrs`, `statfs`), `libproc` for system processes, and IOHIDEventSystemClient user-space access for temperature sensing.

---

## 4. User-Decided Specifications

- **Menu Bar Presentation Style:**
  - **Option 2 (Circular Activity Rings):**
    - 3 miniature circular ring gauges:
      - **CPU Gauge:** Blue accent (`#0A84FF`), showing total CPU load.
      - **RAM Gauge:** Green accent (`#30D158`), showing Unified Memory utilization.
      - **SSD Gauge:** Orange accent (`#FF9F0A`), showing storage fullness percentage.
    - **Network Badge:** Text indicating current aggregated traffic (e.g., `⇅ 1.2M`).
    - **Temperature Badge:** Text showing SoC package temperature (e.g., `42°C`).
- **Popover Window Behavior:**
  - Smooth animation on click, anchoring under the menu bar item.
  - Dark translucent glass styling (`NSVisualEffectView` with `.hudWindow` / `.popover` material).
  - Live instantaneous gauges and progress bars with live rolling updates when opened.
  - Auto-closes when clicking outside or clicking the menu bar item again.

---

## 5. Telemetry Architecture & Implementation Guidance (For the Builder)

### 5.1 CPU Metrics
- **Total Load & Core Breakdown:** Query `host_processor_info` (`PROCESSOR_CPU_LOAD_INFO`). Calculate delta between sample intervals.
- Differentiate between Efficiency cores and Performance cores using `hw.nperflevels` and core type counts on Apple Silicon.
- **Top Processes:** Query `proc_listallpids` / `proc_pidinfo` (`PROC_PIDTHREADINFO` / `PROC_PIDTASKINFO`) to calculate CPU percentages for top 3 processes.

### 5.2 Unified Memory (RAM) Metrics
- **Total & Used:** Call `host_statistics64(mach_host_self(), HOST_VM_INFO64, ...)` to obtain `vm_statistics64_data_t`.
- Calculate:
  - `active_count`, `inactive_count`, `wire_count`, `compressor_page_count`.
  - App memory = `(internal - purgeable) * pageSize`.
  - Memory Pressure = monitor via dispatch source `DISPATCH_SOURCE_TYPE_VM` or `vm_statistics64.pageins/pageouts`.
- **Top Processes:** Query `proc_pidinfo` (`PROC_PIDTASKINFO`) for resident size (RSS).

### 5.3 Storage (SSD) Metrics
- **Volume Usage:** Call `statfs` on `/` (Macintosh HD) to obtain `f_bavail`, `f_bfree`, and `f_blocks`.
- **Disk I/O Throughput:** Use IOKit storage statistics (`IOBlockStorageDriver`) or `getfsstat` delta to compute Read MB/s and Write MB/s.

### 5.4 Network Metrics
- **Interface Throughput:** Call `getifaddrs` to examine `ifa_data` (`struct if_data`) for network interfaces (`en0`, `en1`, etc.). Compute byte delta between timer ticks to derive current Upload (bytes sent/sec) and Download (bytes received/sec).
- **IP & Wi-Fi:** Extract active IPv4 address from `getifaddrs`.

### 5.5 SoC Temperature & Thermal State
- **Thermal State:** Read `ProcessInfo.processInfo.thermalState` (`nominal`, `fair`, `serious`, `critical`).
- **Temperature Sensing:** Access Apple Silicon thermal sensors via user-space `IOHIDEventSystemClient` (matching `PrimaryUsagePage = 0xff00` and `PrimaryUsage = 0x5` for thermal sensors) to get accurate Celsius temperatures.

### 5.6 Application Lifecycle & UI
- `LSUIElement = YES` so the app runs purely as a Menu Bar accessory without a Dock icon.
- `NSStatusItem` holds an `NSView` / `NSHostingView` rendering the SwiftUI `CircularRingsView`.
- Update frequency:
  - Menu Bar items: Every 2.0 seconds.
  - Popover (when open): Every 1.0 second.
  - When Popover is closed: Process inspection and deep disk/process checks are suspended to conserve battery.

---

## 6. What's Left to the Builder

- Exact layout spacing, typography weights (SF Pro and SF Mono), and color nuances for dark/light appearance.
- Fallback gracefully if specific hardware sensor keys vary across different M-series chip generations (M1 vs M2/M3/M4).
- SPM (Swift Package Manager) project directory organization (`Package.swift`, `Sources/`).
