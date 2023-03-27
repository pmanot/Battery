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
            self.state = Battery.state
            
            lowPowerModePublisher
                .receive(on: RunLoop.main)
                .map { _ in ProcessInfo.processInfo.isLowPowerModeEnabled }
                .assign(to: &$isLowPowerModeEnabled)
            
            publisher
                .compactMap { _ in Battery.getPowerSourceProperty(forKey: .percentage) as? Int }
                .assign(to: &$percentage)
            
            publisher
                .compactMap { [weak self] _ in self?.getBatteryState() }
                .assign(to: &$state)
            
            publisher
                .map { _ in Battery.getPowerSource() }
                .assign(to: &$powerSource)
        } catch {
            print("Error opening connection, cannot fetch battery details")
        }
    }
    #endif
    
    #if os(macOS)
    static var powerSource: PowerSource {
        guard let isPlugged = Battery.getPowerSourceProperty(forKey: .isPlugged) as? Bool else {
            return .unknown
        }

        return isPlugged ? .powerAdapter : .battery
    }

    static var state: BatteryState {
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
}
