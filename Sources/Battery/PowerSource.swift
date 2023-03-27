//
//  PowerSource.swift
//  
//
//  Created by Purav Manot on 27/03/23.
//

import Foundation

public enum PowerSource: String, Codable {
    case unknown = "Unknown"
    case powerAdapter = "Power Adapter"
    case battery = "Battery"

    var localizedDescription: String {
        return NSLocalizedString(self.rawValue, comment: "")
    }
}
