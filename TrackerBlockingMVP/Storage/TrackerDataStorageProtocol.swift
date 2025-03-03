//
//  TrackerDataStorageProtocol.swift
//  TrackerBlockingMVP
//
//  Created by FC on 26/2/25.
//

import Foundation

protocol TrackerDataStorageProtocol {
    func save(_ data: Data) throws
    func load() throws -> Data?
}

