//
//  TrackerRulesGeneratorTests.swift
//  TrackerBlockingMVPTests
//
//  Created by FC on 24/2/25.
//

import XCTest
@testable import TrackerBlockingMVP

final class TrackerRulesGeneratorTests: XCTestCase {
    let fullURLPattern = "^(https?)?(wss?)?://([a-z0-9-]+\\.)[TRACKER_DOMAIN](:?[0-9]+)?/.*"
    
    func test_generateRules_successfullyCreatesRules() throws {
        let (sut, _) = makeSUT()
        let trackerJSON = try loadMockJSON()
        let allowlist: Set<String> = ["tracker-4.com"] // Example allowlist entry

        let rules = try sut.generateRules(from: trackerJSON, allowlist: allowlist)
        let blockingStatus = extractBlockingStatus(from: rules)

        // ✅ Assert that some domains are correctly blocked
        XCTAssertEqual(blockingStatus["tracker-1\\.com"], true, "tracker-1.com should be blocked")
        XCTAssertEqual(blockingStatus["tracker-2\\.com"], true, "tracker-2.com should be blocked")
        XCTAssertEqual(blockingStatus["tracker-3\\.com"], true, "tracker-3.com should be blocked")

        // ❌ Assert that allowlisted domains are NOT blocked
        XCTAssertEqual(blockingStatus["tracker-4\\.com"], false, "tracker-4.com should NOT be blocked")
    }
    
    func test_generateRules_fallsBackToStoredDataWhenPrimaryDecodingFails() throws {
        let (sut, storage) = makeSUT()
        
        let fallbackJSON = try loadMockJSON()
        try? storage.save(fallbackJSON) // Store fallback data
        
        let allowlist: Set<String> = []
        
        let invalidJSON = Data() // Simulating a failure in decoding
        let rules = try sut.generateRules(from: invalidJSON, allowlist: allowlist)
        let blockingStatus = extractBlockingStatus(from: rules)

        // ✅ Assert that some domains are correctly blocked
        XCTAssertEqual(blockingStatus["tracker-1\\.com"], true, "tracker-1.com should be blocked")
        XCTAssertEqual(blockingStatus["tracker-2\\.com"], true, "tracker-2.com should be blocked")
        XCTAssertEqual(blockingStatus["tracker-3\\.com"], true, "tracker-3.com should be blocked")
    }
    
    func test_generateRules_throwsErrorWhenBothPrimaryAndFallbackFail() throws {
        let invalidJSON = Data()
        let sut = makeSUT().sut
        
        XCTAssertThrowsError(try sut.generateRules(from: invalidJSON, allowlist: [])) { error in
            XCTAssertEqual(error as? RuleGenerationError, RuleGenerationError.fallbackNotAvailable)
        }
    }
    
    func test_generateRules_correctlyHandlesEmptyDataset() throws {
        let emptyJSON = """
        {
            "entities": {},
            "trackers": {},
            "domains": {},
            "cname": {}
        }
        """.data(using: .utf8)!
        
        let storage = TrackerDataStorageMock()
        let sut = TrackerRulesGenerator(storage: storage)
        
        let rules = try sut.generateRules(from: emptyJSON, allowlist: [])
        
        XCTAssertEqual(rules, "[]", "Empty dataset should return an empty rule list")
    }
    
    // MARK: - Helpers

    private func makeSUT() -> (sut: TrackerRulesGeneratorProtocol, storage: TrackerDataStorageProtocol) {
        let storage = TrackerDataStorageMock()
        let sut = TrackerRulesGenerator(storage: storage)
        return (sut, storage)
    }
    
    private func loadMockJSON() throws -> Data {
        guard let url = Bundle(for: Self.self).url(forResource: "mockTrackerData", withExtension: "json") else {
            XCTFail("Missing mockTrackerData.json")
            throw NSError(domain: "MockDataError", code: 1, userInfo: nil)
        }
        return try Data(contentsOf: url)
    }
    
    private func extractBlockingStatus(from rulesString: String) -> [String: Bool] {
        guard let rulesData = rulesString.data(using: .utf8),
              let rulesArray = try? JSONSerialization.jsonObject(with: rulesData, options: []) as? [[String: Any]] else {
            XCTFail("Failed to parse generated rules JSON")
            return [:]
        }
        
        var blockingStatus: [String: Bool] = [:]

        for rule in rulesArray {
            guard let trigger = rule["trigger"] as? [String: Any],
                  let urlFilter = trigger["url-filter"] as? String,
                  let action = rule["action"] as? [String: Any],
                  let actionType = action["type"] as? String else {
                continue
            }
            
            // Extract domain from url-filter
            if let domainMatch = urlFilter.range(of: "([a-z0-9-]+\\\\.)*[a-z0-9-]+\\\\.com", options: .regularExpression) {
                let domain = String(urlFilter[domainMatch])
                
                if actionType == "ignore-previous-rules" {
                    blockingStatus[domain] = false
                } else if actionType == "block" {
                    let unlessDomain = (trigger["unless-domain"] as? [String]) ?? []
                    blockingStatus[domain] = !unlessDomain.contains("*\(domain)")
                }
            }
        }
        
        return blockingStatus
    }
    
    private func fullPathTrackerDomain(_ trackerDomain: String) -> String {
        fullURLPattern.replacingOccurrences(of: "[TRACKER_DOMAIN]", with: trackerDomain)
    }
}

// MARK: - Mock Storage Implementation

final class TrackerDataStorageMock: TrackerDataStorageProtocol {
    private var storedData: Data?

    func load() throws -> Data? {
        if let storedData = storedData {
            return storedData
        }
        throw RuleGenerationError.fallbackNotAvailable
    }
    
    func save(_ data: Data) throws {
        self.storedData = data
    }
}
