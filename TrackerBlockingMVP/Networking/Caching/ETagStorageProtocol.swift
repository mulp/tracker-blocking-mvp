//
//  ETagStorageProtocol.swift
//  TrackerBlockingMVP
//
//  Created by FC on 26/2/25.
//

protocol ETagStorageProtocol {
    func store(etag: String, for key: String)
    func retrieveETag(for key: String) -> String?
}
