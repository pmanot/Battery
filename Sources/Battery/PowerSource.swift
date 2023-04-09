import Foundation

// An enumeration representing the current power source of the device.
public enum PowerSource: String, Codable {
    case unknown = "Unknown" // The power source is currently unknown.
    case powerAdapter = "Power Adapter" // The device is currently connected to a power adapter.
    case battery = "Battery" // The device is currently running on battery power.

    // A computed property that returns the localized description of the power source.
    var localizedDescription: String {
        return NSLocalizedString(self.rawValue, comment: "")
    }
}
