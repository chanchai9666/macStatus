import Foundation
import IOKit

public final class ThermalMonitor: @unchecked Sendable {
    // IOHID System Client constants
    private static let kHIDPageAppleVendor: UInt32 = 0xff00
    private static let kHIDUsageAppleVendorTemperatureSensor: UInt32 = 0x5
    private static let kIOHIDEventTypeTemperature: UInt32 = 15

    private typealias IOHIDEventSystemClientCreateFunc = @convention(c) (CFAllocator?) -> UnsafeMutableRawPointer?
    private typealias IOHIDEventSystemClientSetMatchingFunc = @convention(c) (UnsafeMutableRawPointer, CFDictionary) -> Void
    private typealias IOHIDEventSystemClientCopyServicesFunc = @convention(c) (UnsafeMutableRawPointer) -> CFArray?
    private typealias IOHIDServiceClientCopyEventFunc = @convention(c) (UnsafeMutableRawPointer, UInt32, UInt32, UInt64) -> CFTypeRef?
    private typealias IOHIDEventGetFloatValueFunc = @convention(c) (CFTypeRef, UInt32) -> Double

    private var iokitHandle: UnsafeMutableRawPointer?
    private var client: UnsafeMutableRawPointer?
    private var copyServicesFunc: IOHIDEventSystemClientCopyServicesFunc?
    private var copyEventFunc: IOHIDServiceClientCopyEventFunc?
    private var getFloatValueFunc: IOHIDEventGetFloatValueFunc?
    private var cachedServices: [UnsafeMutableRawPointer] = []
    private var lastServicesRefresh: TimeInterval = 0

    public init() {
        setupHIDClient()
    }

    deinit {
        if let client = self.client {
            Unmanaged<CFTypeRef>.fromOpaque(client).release()
        }
        if let handle = self.iokitHandle {
            dlclose(handle)
        }
    }

    private func setupHIDClient() {
        guard let handle = dlopen("/System/Library/Frameworks/IOKit.framework/IOKit", RTLD_NOW) else { return }
        self.iokitHandle = handle

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
                    "PrimaryUsagePage": Self.kHIDPageAppleVendor,
                    "PrimaryUsage": Self.kHIDUsageAppleVendorTemperatureSensor
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
        let osThermalState = ProcessInfo.processInfo.thermalState
        let state: ThermalPressureState
        let fallbackBaseTemp: Double

        switch osThermalState {
        case .nominal:
            state = .nominal
            fallbackBaseTemp = 42.0
        case .fair:
            state = .fair
            fallbackBaseTemp = 58.0
        case .serious:
            state = .serious
            fallbackBaseTemp = 75.0
        case .critical:
            state = .critical
            fallbackBaseTemp = 92.0
        @unknown default:
            state = .unknown
            fallbackBaseTemp = 42.0
        }

        let nowUptime = ProcessInfo.processInfo.systemUptime
        if cachedServices.isEmpty || (nowUptime - lastServicesRefresh > 60.0) {
            refreshServices()
        }

        var detectedTemps: [Double] = []
        if let copyEvent = self.copyEventFunc, let getFloat = self.getFloatValueFunc {
            for service in cachedServices {
                if let event = copyEvent(service, Self.kIOHIDEventTypeTemperature, 0, 0) {
                    let temp = getFloat(event, (Self.kIOHIDEventTypeTemperature << 16))
                    if temp > 15.0 && temp < 120.0 {
                        detectedTemps.append(temp)
                    }
                }
            }
        }

        let finalCelsius: Double = detectedTemps.max() ?? fallbackBaseTemp

        return ThermalStats(
            celsius: finalCelsius,
            thermalState: state,
            fanRPM: nil
        )
    }
}
