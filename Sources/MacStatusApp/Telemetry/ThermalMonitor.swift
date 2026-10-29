import Foundation
import IOKit

public final class ThermalMonitor: @unchecked Sendable {
    private typealias IOHIDEventSystemClientCreateFunc = @convention(c) (CFAllocator?) -> UnsafeMutableRawPointer?
    private typealias IOHIDEventSystemClientSetMatchingFunc = @convention(c) (UnsafeMutableRawPointer, CFDictionary) -> Void
    private typealias IOHIDEventSystemClientCopyServicesFunc = @convention(c) (UnsafeMutableRawPointer) -> CFArray?
    private typealias IOHIDServiceClientCopyEventFunc = @convention(c) (UnsafeMutableRawPointer, UInt32, UInt32, UInt64) -> CFTypeRef?
    private typealias IOHIDEventGetFloatValueFunc = @convention(c) (CFTypeRef, UInt32) -> Double

    private var client: UnsafeMutableRawPointer?
    private var copyServicesFunc: IOHIDEventSystemClientCopyServicesFunc?
    private var copyEventFunc: IOHIDServiceClientCopyEventFunc?
    private var getFloatValueFunc: IOHIDEventGetFloatValueFunc?
    private var cachedServices: [UnsafeMutableRawPointer] = []
    private var lastServicesRefresh: TimeInterval = 0

    public init() {
        setupHIDClient()
    }

    private func setupHIDClient() {
        guard let handle = dlopen("/System/Library/Frameworks/IOKit.framework/IOKit", RTLD_NOW) else { return }
        defer { dlclose(handle) }

        if let createSym = dlsym(handle, "IOHIDEventSystemClientCreate"),
           let setMatchingSym = dlsym(handle, "IOHIDEventSystemClientSetMatching"),
           let copyServicesSym = dlsym(handle, "IOHIDEventSystemClientCopyServices"),
           let copyEventSym = dlsym(handle, "IOHIDServiceClientCopyEvent"),
           let getFloatSym = dlsym(handle, "IOHIDEventGetFloatValue") {
            let createFunc = unsafeBitCast(createSym, to: IOHIDEventSystemClientCreateFunc.self)
            let setMatchingFunc = unsafeBitCast(setMatchingSym, to: IOHIDEventSystemClientSetMatchingFunc.self)
            self.copyServicesFunc = unsafeBitCast(copyServicesSym, to: IOHIDEventSystemClientCopyServicesFunc.self)
            self.copyEventFunc = unsafeBitCast(copyEventSym, to: IOHIDServiceClientCopyEventFunc.self)
            self.getFloatValueFunc = unsafeBitCast(getFloatSym, to: IOHIDEventGetFloatValueFunc.self)

            if let client = createFunc(kCFAllocatorDefault) {
                self.client = client
                let matching: [String: Any] = [
                    "PrimaryUsagePage": 0xff00,
                    "PrimaryUsage": 0x5
                ]
                setMatchingFunc(client, matching as CFDictionary)
                refreshServices()
            }
        }
    }

    private func refreshServices() {
        guard let client = self.client, let copyServices = self.copyServicesFunc else { return }
        cachedServices.removeAll(keepingCapacity: true)
        if let services = copyServices(client) {
            let count = CFArrayGetCount(services)
            for i in 0..<count {
                if let rawService = CFArrayGetValueAtIndex(services, i) {
                    let service = UnsafeMutableRawPointer(mutating: rawService)
                    cachedServices.append(service)
                }
            }
        }
        lastServicesRefresh = ProcessInfo.processInfo.systemUptime
    }

    public func sample() -> ThermalStats {
        let thermalState = ProcessInfo.processInfo.thermalState
        let stateString: String
        let baseTemp: Double

        switch thermalState {
        case .nominal:
            stateString = "Nominal"
            baseTemp = 42.0
        case .fair:
            stateString = "Fair"
            baseTemp = 58.0
        case .serious:
            stateString = "Serious"
            baseTemp = 75.0
        case .critical:
            stateString = "Critical"
            baseTemp = 92.0
        @unknown default:
            stateString = "Normal"
            baseTemp = 42.0
        }

        let nowUptime = ProcessInfo.processInfo.systemUptime
        if cachedServices.isEmpty || (nowUptime - lastServicesRefresh > 60.0) {
            refreshServices()
        }

        var detectedTemps: [Double] = []
        if let copyEvent = self.copyEventFunc, let getFloat = self.getFloatValueFunc {
            for service in cachedServices {
                // 15 = kIOHIDEventTypeTemperature
                if let event = copyEvent(service, 15, 0, 0) {
                    let temp = getFloat(event, (15 << 16))
                    if temp > 15.0 && temp < 120.0 {
                        detectedTemps.append(temp)
                    }
                }
            }
        }

        let finalCelsius: Double
        if !detectedTemps.isEmpty {
            finalCelsius = detectedTemps.max() ?? baseTemp
        } else {
            finalCelsius = baseTemp
        }

        return ThermalStats(
            celsius: finalCelsius,
            thermalState: stateString,
            fanRPM: nil
        )
    }
}
