import Foundation
import Combine
#if os(macOS)
import Cocoa
import AppKit
import IOKit.ps
#elseif os(iOS)
import UIKit
#endif


public final class Battery: ObservableObject {
    #if os(macOS)
    private var service: io_object_t = Battery.connectionClosed
    private var publisher = NotificationCenter.default.publisher(for: Battery.batteryStatusDidChangeNotification)
    
    #elseif os(iOS)
    private var batteryLevelChangePublisher = NotificationCenter.default.publisher(for: UIDevice.batteryLevelDidChangeNotification)
    private var batteryStateChangePublisher = NotificationCenter.default.publisher(for: UIDevice.batteryStateDidChangeNotification)
    
    #endif
    private var lowPowerModePublisher = NotificationCenter.default.publisher(for: NSNotification.Name.NSProcessInfoPowerStateDidChange)
    
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
    
    @Published public var percentage: Int = 0
    @Published public var state: BatteryState = .unknown
    @Published public var isLowPowerModeEnabled: Bool = false
    
    //var health: String? {
   //     Battery.getPowerSourceProperty(forKey: .health) as? String
    //}
    
    #if os(iOS)
    public init() {
        UIDevice.current.isBatteryMonitoringEnabled = true
        
        self.percentage = Int(UIDevice.current.batteryLevel * 100)
        self.state = Battery.getBatteryState()
        self.isLowPowerModeEnabled = ProcessInfo.processInfo.isLowPowerModeEnabled
        self.isLowPowerModeEnabled = ProcessInfo.processInfo.isLowPowerModeEnabled
        
        batteryStateChangePublisher
            .map { _ in Battery.getBatteryState() }
            .eraseToAnyPublisher()
            .assign(to: &$state)
        
        batteryLevelChangePublisher
            .map { _ in Int(UIDevice.current.batteryLevel * 100) }
            .assign(to: &$percentage)
        
        lowPowerModePublisher
            .map { _ in ProcessInfo.processInfo.isLowPowerModeEnabled }
            .assign(to: &$isLowPowerModeEnabled)
        
    }
    #endif
    
    #if os(macOS)
    public init() {
        do {
            try openServiceConnection()
            CFRunLoopAddSource(CFRunLoopGetCurrent(),
                               IOPSNotificationCreateRunLoopSource(Battery.powerSourceCallback, nil).takeRetainedValue(),
                               CFRunLoopMode.defaultMode)
            
            self.percentage = Battery.getPowerSourceProperty(forKey: .percentage) as? Int ?? 0
            self.state = self.getState()
            
            lowPowerModePublisher
                .receive(on: RunLoop.main)
                .map { _ in ProcessInfo.processInfo.isLowPowerModeEnabled }
                .assign(to: &$isLowPowerModeEnabled)
            
            publisher
                .compactMap { _ in Battery.getPowerSourceProperty(forKey: .percentage) as? Int }
                .assign(to: &$percentage)
            
            publisher
                .compactMap { [weak self] _ in self?.getState() }
                .assign(to: &$state)
        } catch {
            print("Error opening connection, cannot fetch battery details")
        }
    }
    #endif
    
    deinit {
        let successBool = self.closeServiceConnection()
        print("deallocated \(successBool ? "succesfully" : "unsuccesfully")")
        
    }
    
    #if os(macOS)
    static public func getPowerSource() -> PowerSource {
        guard let isPlugged = Battery.getPowerSourceProperty(forKey: .isPlugged) as? Bool else {
            return .unknown
        }

        return isPlugged ? .powerAdapter : .battery
    }

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
    
    #if os(iOS)
    static func getPowerSource() -> PowerSource {
        let processInfo = ProcessInfo.processInfo

        if let powerSource = processInfo.environment["AC_POWER"] {
            print(powerSource)
            return .powerAdapter
        }
        
        return .battery
    }

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
    /// Closed state value for the service connection object.
    private static let connectionClosed: UInt32 = 0
    
    public static let batteryStatusDidChangeNotification = Notification.Name(rawValue: "batteryStatusChanged")
    
    private static let powerSourceCallback: IOPowerSourceCallbackType = { _ in
        NotificationCenter.default.post(name: Battery.batteryStatusDidChangeNotification, object: nil)
    }
    
    /// Open a connection to the battery's IOService object.
    ///
    /// - throws: A BatteryError if something went wrong.
    private func openServiceConnection() throws {
        service = IOServiceGetMatchingService(kIOMainPortDefault,
                                              IOServiceNameMatching(BatteryRegistryPropertyKey.service.rawValue))

        if service == Battery.connectionClosed {
            throw BatteryError.serviceNotFound("Opening (\(BatteryRegistryPropertyKey.service.rawValue)) service failed")
        }
    }

    /// Close the connection the to the battery's IOService object.
    ///
    /// - returns: True, when the IOService connection was successfully closed.
    private func closeServiceConnection() -> Bool {
        if kIOReturnSuccess == IOObjectRelease(service) {
            service = Battery.connectionClosed
        }
        return (service == Battery.connectionClosed)
    }

    /// Get a registry entry for the supplied property key.
    ///
    /// - parameter key: A BatteryRegistryPropertyKey to get the corresponding registry entry.
    /// - returns: The registry entry for the provided BatteryRegistryPropertyKey.
    private func getRegistryProperty(forKey key: BatteryRegistryPropertyKey) -> Any? {
        IORegistryEntryCreateCFProperty(service, key.rawValue as CFString?, nil, 0).takeRetainedValue()
    }

    /// Get a power source entry for the supplied property key.
    ///
    /// - parameter key: A BatteryRegistryPropertyKey to get the corresponding power source entry.
    /// - returns: The power sorce entry for the given property.
    static private func getPowerSourceProperty(forKey key: BatteryRegistryPropertyKey) -> Any? {
        let psInfo = IOPSCopyPowerSourcesInfo().takeRetainedValue()
        let psList = IOPSCopyPowerSourcesList(psInfo).takeRetainedValue() as? [CFDictionary]
        guard let powerSources = psList else {
            return nil
        }
        let powerSource = powerSources[0] as NSDictionary
        return powerSource[key.rawValue]
    }
    #endif
}

enum BatteryError: Error {
    case connectionAlreadyOpen(String)
    case serviceNotFound(String)
}
