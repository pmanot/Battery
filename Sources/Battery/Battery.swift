// Credits to raphaelhanneken for most of the macOS specific code.
// https://github.com/raphaelhanneken/apple-juice

import Foundation
import Combine
#if os(macOS)
import Cocoa
import AppKit
import IOKit.ps
#elseif os(iOS)
import UIKit
#endif

// A class representing a battery object that can observe changes in the device's battery status.
public final class Battery: ObservableObject {

    #if os(macOS)
    // A reference to the IOService object for the battery.
    private var service: io_object_t = Battery.connectionClosed
    // A publisher for battery status change notifications.
    private var publisher = NotificationCenter.default.publisher(for: Battery.batteryStatusDidChangeNotification)
    
    #elseif os(iOS)
    // Publishers for battery level and state change notifications.
    private var batteryLevelChangePublisher = NotificationCenter.default.publisher(for: UIDevice.batteryLevelDidChangeNotification)
    private var batteryStateChangePublisher = NotificationCenter.default.publisher(for: UIDevice.batteryStateDidChangeNotification)
    
    #endif
    // A publisher for changes in the low power mode state.
    private var lowPowerModePublisher = NotificationCenter.default.publisher(for: NSNotification.Name.NSProcessInfoPowerStateDidChange)
    
    // A computed property that returns the current power source based on the current battery state.
    var powerSource: PowerSource {
        switch state {
            case .charging, .chargedAndPlugged:
                return PowerSource.powerAdapter
            case .discharging:
                return PowerSource.battery
            case .unknown:
                return PowerSource.unknown
        }
    }
    
    // Published properties that can be observed for changes.
    @Published public var percentage: Int = 0
    @Published public var state: BatteryState = .unknown
    @Published public var isLowPowerModeEnabled: Bool = false
    
    // The initializer for the Battery class on iOS devices.
    #if os(iOS)
    public init() {
        // Enable battery monitoring.
        UIDevice.current.isBatteryMonitoringEnabled = true
        
        // Set initial property values.
        self.percentage = Int(UIDevice.current.batteryLevel * 100)
        self.state = Battery.getBatteryState()
        self.isLowPowerModeEnabled = ProcessInfo.processInfo.isLowPowerModeEnabled
        
        // Observe battery state change notifications and update the state property accordingly.
        batteryStateChangePublisher
            .map { _ in Battery.getBatteryState() }
            .eraseToAnyPublisher()
            .assign(to: &$state)
        
        // Observe battery level change notifications and update the percentage property accordingly.
        batteryLevelChangePublisher
            .map { _ in Int(UIDevice.current.batteryLevel * 100) }
            .assign(to: &$percentage)
        
        // Observe low power mode change notifications and update the isLowPowerModeEnabled property accordingly.
        lowPowerModePublisher
            .map { _ in ProcessInfo.processInfo.isLowPowerModeEnabled }
            .assign(to: &$isLowPowerModeEnabled)
        
    }
    #endif
    
    // The initializer for the Battery class on macOS devices.
    #if os(macOS)
    public init() {
        do {
            // Open a connection to the battery's IOService object.
            try openServiceConnection()
            // Add the battery status change notification to the run loop.
            CFRunLoopAddSource(CFRunLoopGetCurrent(),
                               IOPSNotificationCreateRunLoopSource(Battery.powerSourceCallback, nil).takeRetainedValue(),
                               CFRunLoopMode.defaultMode)
            
            // Set initial property values.
            self.percentage = Battery.getPowerSourceProperty(forKey: .percentage) as? Int ?? 0
            self.state = self.getState()
            
            // Observe low power mode change notifications and update the isLowPowerModeEnabled property accordingly.
            lowPowerModePublisher
                .receive(on: RunLoop.main)
                .map { _ in ProcessInfo.processInfo.isLowPowerModeEnabled }
                .assign(to: &$isLowPowerModeEnabled)
            
            // Observe battery status change notifications and update the percentage property accordingly.
            publisher
                .compactMap { _ in Battery.getPowerSourceProperty(forKey: .percentage) as? Int }
                .assign(to: &$percentage)
            
            // Observe battery status change notifications and update the state property accordingly.
            publisher
                .compactMap { [weak self] _ in self?.getState() }
                .assign(to: &$state)
        } catch {
            fatalError("Error opening connection, cannot fetch battery details")
        }
    }
#endif
    
    // A deinitializer for the Battery class on macOS devices.
#if os(macOS)
    deinit {
        let successBool = self.closeServiceConnection()
        print("deallocated \(successBool ? "succesfully" : "unsuccesfully")")
    }
#endif
    
    // A static method that returns the current power source.
#if os(macOS)
    static public func getPowerSource() -> PowerSource {
        guard let isPlugged = Battery.getPowerSourceProperty(forKey: .isPlugged) as? Bool else {
            return .unknown
        }
        
        return isPlugged ? .powerAdapter : .battery
    }
    
    // A method that returns the current battery state.
    public func getState() -> BatteryState {
        guard let isCharging = self.getRegistryProperty(forKey: .isCharging) as? Bool,
              let isPlugged = self.getRegistryProperty(forKey: .isPlugged) as? Bool,
              let fullyCharged = self.getRegistryProperty(forKey: .fullyCharged) as? Bool
        else {
            return .unknown
        }
        
        if fullyCharged && isPlugged {
            return .chargedAndPlugged
        }
        
        if isCharging {
            return .charging
        }
        
        return .discharging
    }
#endif
    
    // A static method that returns the current power source on iOS devices.
#if os(iOS)
    static func getPowerSource() -> PowerSource {
        let processInfo = ProcessInfo.processInfo
        
        if let powerSource = processInfo.environment["AC_POWER"] {
            print(powerSource)
            return .powerAdapter
        }
        
        return .battery
    }
    
    // A static method that returns the current battery state on iOS devices.
    static func getBatteryState() -> BatteryState {
        switch UIDevice.current.batteryState {
            case .charging:
                return BatteryState.charging
            case .full:
                return BatteryState.chargedAndPlugged
            case .unplugged:
                return BatteryState.discharging
            case .unknown:
                return BatteryState.unknown
            @unknown default:
                return BatteryState.unknown
        }
    }
#endif
    
#if os(macOS)
    // A private constant that represents the closed state value for the IOService object.
    private static let connectionClosed: UInt32 = 0
    
    // A notification name for battery status change notifications.
    public static let batteryStatusDidChangeNotification = Notification.Name(rawValue: "batteryStatusChanged")
    
    // A callback function for battery status change notifications.
    private static let powerSourceCallback: IOPowerSourceCallbackType = { _ in
        NotificationCenter.default.post(name: Battery.batteryStatusDidChangeNotification, object: nil)
    }
    
    // A method that opens a connection to the battery's IOService object.
    private func openServiceConnection() throws {
        service = IOServiceGetMatchingService(kIOMainPortDefault,
                                              IOServiceNameMatching(BatteryRegistryPropertyKey.service.rawValue))
        
        if service == Battery.connectionClosed {
            throw BatteryError.serviceNotFound("Opening (\(BatteryRegistryPropertyKey.service.rawValue)) service failed")
        }
    }

    // A method that closes the connection to the battery's IOService object.
    private func closeServiceConnection() -> Bool {
        if kIOReturnSuccess == IOObjectRelease(service) {
            service = Battery.connectionClosed
        }
        return (service == Battery.connectionClosed)
    }

    // A method that retrieves a registry entry for a given property key.
    private func getRegistryProperty(forKey key: BatteryRegistryPropertyKey) -> Any? {
        IORegistryEntryCreateCFProperty(service, key.rawValue as CFString?, nil, 0).takeRetainedValue()
    }

    // A static method that retrieves a power source entry for a given property key.
    static private func getPowerSourceProperty(forKey key: BatteryRegistryPropertyKey) -> Any? {
        let psInfo = IOPSCopyPowerSourcesInfo().takeRetainedValue()
        let psList = IOPSCopyPowerSourcesList(psInfo).takeRetainedValue() as? [CFDictionary]
        guard let powerSources = psList, !powerSources.isEmpty else {
            return nil
        }
        let powerSource = powerSources[0] as NSDictionary
        return powerSource[key.rawValue]
    }
    #endif
}
