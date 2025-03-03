//
//  MockAllowlistManager.swift
//  TrackerBlockingMVP
//
//  Created by FC on 1/3/25.
//

import Foundation
@testable import TrackerBlockingMVP

class MockAllowlistManager: AllowlistManagerProtocol {
    // Collection to store allowlisted domains
    var allowlistedDomains: [String] = []
    
    // Tracking variables for test verification
    private(set) var isAllowlistedCallCount = 0
    private(set) var addToAllowlistCallCount = 0
    private(set) var removeFromAllowlistCallCount = 0
    private(set) var toggleAllowlistCallCount = 0
    private(set) var getAllowlistCallCount = 0
    
    // Required by protocol
    func isAllowlisted(domain: String) -> Bool {
        isAllowlistedCallCount += 1
        return allowlistedDomains.contains(domain)
    }
    
    // Additional methods
    func addToAllowlist(domain: String) {
        addToAllowlistCallCount += 1
        allowlistedDomains.append(domain)
    }
    
    func removeFromAllowlist(domain: String) {
        removeFromAllowlistCallCount += 1
        if let index = allowlistedDomains.firstIndex(of: domain) {
            allowlistedDomains.remove(at: index)
        }
    }
    
    func toggleAllowlist(domain: String) -> Bool {
        toggleAllowlistCallCount += 1
        let isCurrentlyAllowed = isAllowlisted(domain: domain)
        
        if isCurrentlyAllowed {
            removeFromAllowlist(domain: domain)
        } else {
            addToAllowlist(domain: domain)
        }
        
        return !isCurrentlyAllowed
    }
    
    func getAllowlist() -> Set<String> {
        getAllowlistCallCount += 1
        return Set(allowlistedDomains)
    }
}
