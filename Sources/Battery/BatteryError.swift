import Foundation

// An enumeration representing possible errors that can occur with the Battery class.
enum BatteryError: Error {
case connectionAlreadyOpen(String)
case serviceNotFound(String)
}
