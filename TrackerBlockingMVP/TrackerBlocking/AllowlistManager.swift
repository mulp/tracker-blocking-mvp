//
//  AllowlistManager.swift
//  TrackerBlockingMVP
//
//  Created by FC on 26/2/25.
//


import Foundation

protocol AllowlistManagerProtocol {
    func isAllowlisted(domain: String) -> Bool
    func addToAllowlist(domain: String)
    func removeFromAllowlist(domain: String)
    func toggleAllowlist(domain: String) -> Bool
    func getAllowlist() -> Set<String>
}

class AllowlistManager: AllowlistManagerProtocol {
    private let userDefaults: UserDefaults
    private let allowlistKey = "website_allowlist"
    
    public init(with userDefaults: UserDefaults = UserDefaults.standard) {
        self.userDefaults = userDefaults
    }
    
    // Check if a domain is in the allowlist
    func isAllowlisted(domain: String) -> Bool {
        let allowlist = getAllowlist()
        return allowlist.contains(domain)
    }
    
    // Add a domain to the allowlist
    func addToAllowlist(domain: String) {
        var allowlist = getAllowlist()
        allowlist.insert(domain)
        saveAllowlist(allowlist)
    }
    
    // Remove a domain from the allowlist
    func removeFromAllowlist(domain: String) {
        var allowlist = getAllowlist()
        allowlist.remove(domain)
        saveAllowlist(allowlist)
    }
    
    // Toggle a domain's allowlist status
    func toggleAllowlist(domain: String) -> Bool {
        let isCurrentlyAllowed = isAllowlisted(domain: domain)
        
        if isCurrentlyAllowed {
            removeFromAllowlist(domain: domain)
        } else {
            addToAllowlist(domain: domain)
        }
        
        return !isCurrentlyAllowed
    }
    
    // Get the full allowlist
    func getAllowlist() -> Set<String> {
        if let data = userDefaults.data(forKey: allowlistKey),
           let allowlist = try? JSONDecoder().decode(Set<String>.self, from: data) {
            return allowlist
        }
        return []
    }
    
    // Save the allowlist to UserDefaults
    private func saveAllowlist(_ allowlist: Set<String>) {
        if let data = try? JSONEncoder().encode(allowlist) {
            userDefaults.set(data, forKey: allowlistKey)
        }
    }
}
