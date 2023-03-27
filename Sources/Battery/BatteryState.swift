//
//  BatteryState.swift
//  
//
//  Created by Purav Manot on 27/03/23.
//

import Foundation

public enum BatteryState: String, Codable {
    case chargedAndPlugged = "Charged & Plugged"
    case charging = "Charging"
    case discharging = "Discharging"
    case unknown = "Unknown"
}
