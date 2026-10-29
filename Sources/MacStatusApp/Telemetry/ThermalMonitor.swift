import Foundation
import IOKit

public final class ThermalMonitor: @unchecked Sendable {
    private typealias IOHIDEventSystemClientCreateFunc = @convention(c) (CFAllocator?) -> UnsafeMutableRawPointer?
    private typealias IOHIDEventSystemClientSetMatchingFunc = @convention(c) (UnsafeMutableRawPointer, CFDictionary) -> Void
    private typealias IOHIDEventSystemClientCopyEventFunc = @convention(c) (UnsafeMutableRawPointer, UInt32, UInt32, UInt64) -> CFTypeRef?
    private typealias IOHIDEventGetFloatValueFunc = @convention(c) (CFTypeRef, UInt32) -> Double

    private var client: UnsafeMutableRawPointer?
    private var copyEventFunc: IOHIDEventSystemClientCopyEventFunc?
    private var getFloatValueFunc: IOHIDEventGetFloatValueFunc?

    public init() {
        setupHIDClient()
    }

    private func setupHIDClient() {
        guard let handle = dlopen("/System/Library/Frameworks/IOKit.framework/IOKit", RTLD_NOW) else { return }
        defer { dlclose(handle) }

        if let createSym = dlsym(handle, "IOHIDEventSystemClientCreate"),
           let setMatchingSym = dlsym(handle, "IOHIDEventSystemClientSetMatching"),
           let copyEventSym = dlsym(handle, "IOHIDEventSystemClientCopyEvent"),
           let getFloatSym = dlsym(handle, "IOHIDEventGetFloatValue") {
            let createFunc = unsafeBitCast(createSym, to: IOHIDEventSystemClientCreateFunc.self)
            let setMatchingFunc = unsafeBitCast(setMatchingSym, to: IOHIDEventSystemClientSetMatchingFunc.self)
            self.copyEventFunc = unsafeBitCast(copyEventSym, to: IOHIDEventSystemClientCopyEventFunc.self)
            self.getFloatValueFunc = unsafeBitCast(getFloatSym, to: IOHIDEventGetFloatValueFunc.self)

            if let client = createFunc(kCFAllocatorDefault) {
                self.client = client
                let matching: [String: Any] = [
                    "PrimaryUsagePage": 0xff00,
                    "PrimaryUsage": 0x5
                ]
                setMatchingFunc(client, matching as CFDictionary)
            }
        }
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

        var detectedTemp: Double?
        if let client = self.client,
           let copyEvent = self.copyEventFunc,
           let getFloat = self.getFloatValueFunc {
            // 15 = kIOHIDEventTypeTemperature
            if let event = copyEvent(client, 15, 0, 0) {
                // (15 << 16) | 1 = IOHIDEventFieldBase(15)
                let temp = getFloat(event, (15 << 16))
                if temp > 10.0 && temp < 120.0 {
                    detectedTemp = temp
                }
            }
        }

        let finalCelsius = detectedTemp ?? baseTemp
        return ThermalStats(
            celsius: finalCelsius,
            thermalState: stateString,
            fanRPM: nil
        )
    }
}
