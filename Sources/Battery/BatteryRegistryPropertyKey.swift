// Credits to raphaelhanneken for most of the macOS specific code.
// https://github.com/raphaelhanneken/apple-juice

import Foundation

// A set of keys for accessing battery information in macOS devices.
#if os(macOS)
enum BatteryRegistryPropertyKey: String {
    case service = "AppleSmartBattery" // The name of the service for accessing battery information.
    case isPlugged = "ExternalConnected" // Whether the device is currently plugged in.
    case isCharging = "IsCharging" // Whether the device is currently charging.
    case currentCharge = "CurrentCapacity" // The current battery charge in mAh.
    case maxCapacity = "MaxCapacity" // The maximum battery charge in mAh.
    case fullyCharged = "FullyCharged" // Whether the battery is fully charged.
    case cycleCount = "CycleCount" // The number of charge cycles the battery has gone through.
    case temperature = "Temperature" // The current temperature of the battery in degrees Celsius.
    case voltage = "Voltage" // The current voltage of the battery in mV.
    case amperage = "Amperage" // The current amperage of the battery in mA.
    case timeRemaining = "TimeRemaining" // The estimated time remaining until the battery is fully charged or discharged.
    case health = "BatteryHealth" // The health of the battery as a string value.
    case percentage = "Current Capacity" // The current battery charge percentage.
}
#endif
