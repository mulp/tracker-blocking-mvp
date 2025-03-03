//
//  EtagStorage.swift
//  TrackerBlockingMVP
//
//  Created by FC on 21/2/25.
//

import Foundation

struct EtagStorage: ETagStorageProtocol {
    let cache: UserDefaults
    
    init(cache: UserDefaults = .standard) {
        self.cache = cache
    }
    
    func store(etag: String, for key: String) {
        cache.set(etag, forKey: key)
    }
    
    func retrieveETag(for key: String) -> String? {
        cache.object(forKey: key) as? String
    }
}
