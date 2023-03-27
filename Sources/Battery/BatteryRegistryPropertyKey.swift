//
//  BatteryRegistryPropertyKey.swift
//  
//
//  Created by Purav Manot on 27/03/23.
//

import Foundation

#if os(macOS)
enum BatteryRegistryPropertyKey: String {
    case service = "AppleSmartBattery"
    case isPlugged = "ExternalConnected"
    case isCharging = "IsCharging"
    case currentCharge = "CurrentCapacity"
    case maxCapacity = "MaxCapacity"
    case fullyCharged = "FullyCharged"
    case cycleCount = "CycleCount"
    case temperature = "Temperature"
    case voltage = "Voltage"
    case amperage = "Amperage"
    case timeRemaining = "TimeRemaining"
    case health = "BatteryHealth"
    case percentage = "Current Capacity"
}
#endif
