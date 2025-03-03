//
//  String.swift
//  TrackerBlockingMVP
//
//  Created by FC on 26/2/25.
//

import Foundation

extension String {
    func cleanETag() -> String {
        replacingOccurrences(of: "W/\"", with: "") // Remove weak indicator and opening quote
            .replacingOccurrences(of: "\"", with: "")   // Remove closing quote
    }

    func removeWeakIndicator() -> String {
        replacingOccurrences(of: "W/", with: "")
    }
}
