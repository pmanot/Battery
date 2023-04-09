import Foundation

// An enumeration representing the possible battery states.
public enum BatteryState: String, Codable {
    case chargedAndPlugged = "Charged & Plugged" // The battery is fully charged and the device is plugged in.
    case charging = "Charging" // The battery is currently charging.
    case discharging = "Discharging" // The battery is currently discharging.
    case unknown = "Unknown" // The battery state is unknown.
}
