//
//  AllowlistManagerTests.swift
//  TrackerBlockingMVP
//
//  Created by FC on 28/2/25.
//

import XCTest
@testable import TrackerBlockingMVP

final class AllowlistManagerTests: XCTestCase {
    
    // MARK: - Basic Operations Tests
    
    func test_init_createsEmptyAllowlistByDefault() {
        let (sut, _) = makeSUT()
        
        XCTAssertTrue(sut.getAllowlist().isEmpty, "Allowlist should be empty by default")
    }
    
    func test_addToAllowlist_storesDomain() {
        // Given
        let domain = "example.com"
        let (sut, mockUserDefaults) = makeSUT()
        
        // When
        sut.addToAllowlist(domain: domain)
        
        // Then
        XCTAssertTrue(sut.isAllowlisted(domain: domain), "Domain should be in allowlist after adding")
        XCTAssertEqual(sut.getAllowlist().count, 1, "Allowlist should contain exactly one domain")
        XCTAssertTrue(mockUserDefaults.dataStoredForKey(allowlistKey), "Data should be stored in UserDefaults")
    }
    
    func test_addToAllowlist_doesNotDuplicateDomains() {
        // Given
        let domain = "example.com"
        let (sut, _) = makeSUT()
        
        // When
        sut.addToAllowlist(domain: domain)
        sut.addToAllowlist(domain: domain)
        
        // Then
        XCTAssertEqual(sut.getAllowlist().count, 1, "Allowlist should still contain exactly one domain")
    }
    
    func test_removeFromAllowlist_removesDomain() {
        // Given
        let domain = "example.com"
        let (sut, mockUserDefaults) = makeSUT()
        sut.addToAllowlist(domain: domain)
        XCTAssertTrue(sut.isAllowlisted(domain: domain), "Setup: Domain should be in allowlist")
        
        // When
        sut.removeFromAllowlist(domain: domain)
        
        // Then
        XCTAssertFalse(sut.isAllowlisted(domain: domain), "Domain should not be in allowlist after removal")
        XCTAssertTrue(sut.getAllowlist().isEmpty, "Allowlist should be empty after removing only domain")
        XCTAssertTrue(mockUserDefaults.dataStoredForKey(allowlistKey), "Updated allowlist should be stored")
    }
    
    func test_removeFromAllowlist_handlesNonexistentDomain() {
        // Given
        let domain = "example.com"
        let (sut, _) = makeSUT()
        XCTAssertFalse(sut.isAllowlisted(domain: domain), "Setup: Domain should not be in allowlist")
        
        // When
        sut.removeFromAllowlist(domain: domain)
        
        // Then
        XCTAssertFalse(sut.isAllowlisted(domain: domain), "Domain should still not be in allowlist")
        XCTAssertTrue(sut.getAllowlist().isEmpty, "Allowlist should remain empty")
    }
    
    func test_isAllowlisted_returnsTrueForAllowlistedDomain() {
        // Given
        let domain = "example.com"
        let (sut, _) = makeSUT()
        sut.addToAllowlist(domain: domain)
        
        // When
        let result = sut.isAllowlisted(domain: domain)
        
        // Then
        XCTAssertTrue(result, "Domain should be identified as allowlisted")
    }
    
    func test_isAllowlisted_returnsFalseForNonAllowlistedDomain() {
        // Given
        let domain = "example.com"
        let (sut, _) = makeSUT()
        
        // When
        let result = sut.isAllowlisted(domain: domain)
        
        // Then
        XCTAssertFalse(result, "Domain should not be identified as allowlisted")
    }
    
    // MARK: - Toggle Tests
    
    func test_toggleAllowlist_addsDomainWhenNotAllowlisted() {
        // Given
        let domain = "example.com"
        let (sut, _) = makeSUT()
        XCTAssertFalse(sut.isAllowlisted(domain: domain), "Setup: Domain should not be allowlisted")
        
        // When
        let result = sut.toggleAllowlist(domain: domain)
        
        // Then
        XCTAssertTrue(result, "Toggle should return true when adding to allowlist")
        XCTAssertTrue(sut.isAllowlisted(domain: domain), "Domain should be allowlisted after toggle")
    }
    
    func test_toggleAllowlist_removesDomainWhenAllowlisted() {
        // Given
        let domain = "example.com"
        let (sut, _) = makeSUT()
        sut.addToAllowlist(domain: domain)
        XCTAssertTrue(sut.isAllowlisted(domain: domain), "Setup: Domain should be allowlisted")
        
        // When
        let result = sut.toggleAllowlist(domain: domain)
        
        // Then
        XCTAssertFalse(result, "Toggle should return false when removing from allowlist")
        XCTAssertFalse(sut.isAllowlisted(domain: domain), "Domain should not be allowlisted after toggle")
    }
    
    // MARK: - Persistence Tests
    
    func test_getAllowlist_retrievesPersistedAllowlist() {
        // Given
        let mockAllowlist: Set<String> = ["example.com", "test.org"]
        let mockUserDefaults = UserDefaultsMock()
        
        // Store a pre-existing allowlist
        if let encodedData = try? JSONEncoder().encode(mockAllowlist) {
            mockUserDefaults.storage[allowlistKey] = encodedData
        }
        
        let (sut, _) = makeSUT(userDefaults: mockUserDefaults)
        
        // When
        let retrievedAllowlist = sut.getAllowlist()
        
        // Then
        XCTAssertEqual(retrievedAllowlist, mockAllowlist, "Should retrieve the correct allowlist from UserDefaults")
    }
    
    func test_saveAllowlist_persistsAllowlist() {
        // Given
        let domains = ["example.com", "test.org"]
        let mockUserDefaults = UserDefaultsMock()
        let (sut, _) = makeSUT(userDefaults: mockUserDefaults)
        
        // When
        for domain in domains {
            sut.addToAllowlist(domain: domain)
        }
        
        // Then
        XCTAssertTrue(mockUserDefaults.dataStoredForKey(allowlistKey), "Data should be stored in UserDefaults")
        
        if let storedData = mockUserDefaults.storage[allowlistKey] as? Data,
           let decodedAllowlist = try? JSONDecoder().decode(Set<String>.self, from: storedData) {
            XCTAssertEqual(decodedAllowlist, Set(domains), "Saved allowlist should match added domains")
        } else {
            XCTFail("Failed to decode saved allowlist data")
        }
    }
    
    // MARK: - Helper Methods
    
    private let allowlistKey = "website_allowlist"
    
    private func makeSUT(userDefaults: UserDefaultsMock = UserDefaultsMock()) -> (sut: AllowlistManagerProtocol, userDefaults: UserDefaultsMock) {
        let sut = AllowlistManager(with: userDefaults)
        trackForMemoryLeaks(sut)
        return (sut, userDefaults)
    }
}

// MARK: - Mocks

class UserDefaultsMock: UserDefaults {
    var storage: [String: Any] = [:]
    
    override func set(_ value: Any?, forKey defaultName: String) {
        storage[defaultName] = value
    }
    
    override func data(forKey defaultName: String) -> Data? {
        return storage[defaultName] as? Data
    }
    
    func dataStoredForKey(_ key: String) -> Bool {
        return storage[key] != nil
    }
}
