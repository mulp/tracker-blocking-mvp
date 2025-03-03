//
//  RuleCacheTests.swift
//  TrackerBlockingMVP
//
//  Created by FC on 28/2/25.
//

import XCTest
@testable import TrackerBlockingMVP

final class RuleCacheTests: XCTestCase {
    
    func test_init_createsDirectoryIfNeeded() {
        // Given, When
        let (_, mockFileManager, _) = makeSUT()
        
        // Then
        XCTAssertTrue(mockFileManager.createDirectoryCalled)
        XCTAssertEqual(mockFileManager.createDirectoryURL?.lastPathComponent, "TrackerRulesCache")
    }
    
    func test_storeCachedRules_writesFilesToCorrectLocations() throws {
        // Given
        let (sut, mockFileManager, documentsDirectory) = makeSUT()
        let rulesJSON = """
        [{"trigger": {"url-filter": "example.com"}, "action": {"type": "block"}}]
        """
        let etag = "\"123abc\""
        
        // When
        try sut.storeCachedRules(rulesJSON: rulesJSON, etag: etag)
        
        // Then
        let expectedRulesPath = documentsDirectory.appendingPathComponent("trackerRules.json").path
        let expectedMetadataPath = documentsDirectory.appendingPathComponent("trackerRules.metadata.json").path
        
        XCTAssertEqual(mockFileManager.writtenStrings[expectedRulesPath], rulesJSON)
        XCTAssertNotNil(mockFileManager.writtenData[expectedMetadataPath])
        
        // Verify metadata content
        if let metadataData = mockFileManager.writtenData[expectedMetadataPath],
           let metadata = try? JSONSerialization.jsonObject(with: metadataData) as? [String: Any] {
            XCTAssertEqual(metadata["etag"] as? String, etag)
            XCTAssertNotNil(metadata["timestamp"])
        } else {
            XCTFail("Failed to parse metadata")
        }
    }
    
    func test_getCachedRules_returnsNilWhenFilesDoNotExist() {
        // Given
        let (sut, mockFileManager, _) = makeSUT()
        mockFileManager.fileExistsReturnValue = false
        
        // When
        let result = sut.getCachedRules()
        
        // Then
        XCTAssertNil(result)
    }
    
    func test_getCachedRules_returnsNilWhenMetadataIsInvalid() {
        // Given
        let (sut, mockFileManager, _) = makeSUT()
        mockFileManager.fileExistsReturnValue = true
        mockFileManager.dataToReturn = "invalid json".data(using: .utf8)
        
        // When
        let result = sut.getCachedRules()
        
        // Then
        XCTAssertNil(result)
    }
    
    func test_getCachedRules_returnsNilWhenCacheIsExpired() throws {
        // Given
        let (sut, mockFileManager, _) = makeSUT()
        mockFileManager.fileExistsReturnValue = true
        
        // Create metadata with timestamp from 2 hours ago (beyond our 1 hour test limit)
        let expiredTimestamp = Date().timeIntervalSince1970 - 7200
        let metadata: [String: Any] = [
            "timestamp": expiredTimestamp,
            "etag": "\"123abc\""
        ]
        mockFileManager.dataToReturn = try JSONSerialization.data(withJSONObject: metadata)
        
        // When
        let result = sut.getCachedRules()
        
        // Then
        XCTAssertNil(result)
    }
    
    func test_getCachedRules_returnsValidCachedRules() throws {
        // Given
        let (sut, mockFileManager, _) = makeSUT()
        mockFileManager.fileExistsReturnValue = true
        
        // Create valid metadata (within the 1 hour test limit)
        let validTimestamp = Date().timeIntervalSince1970 - 1800 // 30 minutes ago
        let etag = "\"123abc\""
        let metadata: [String: Any] = [
            "timestamp": validTimestamp,
            "etag": etag
        ]
        mockFileManager.dataToReturn = try JSONSerialization.data(withJSONObject: metadata)
        
        // Set up the content to be returned for the rules file
        let rulesJSON = "[{\"rule\":\"test\"}]"
        mockFileManager.stringToReturn = rulesJSON
        
        // When
        let result = sut.getCachedRules()
        
        // Then
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.rulesJSON, rulesJSON)
        XCTAssertEqual(result?.etag, etag)
    }
    
    func test_getMostRecentRules_returnsNilWhenCachedRulesNotAvailable() {
        // Given
        let (sut, mockFileManager, _) = makeSUT()
        mockFileManager.fileExistsReturnValue = false
        
        // When
        let result = sut.getMostRecentRules()
        
        // Then
        XCTAssertNil(result)
    }
    
    func test_getMostRecentRules_returnsValidSnapshot() throws {
        // Given
        let (sut, mockFileManager, _) = makeSUT()
        mockFileManager.fileExistsReturnValue = true
        
        // Set up metadata with a valid timestamp
        let timestamp = Date().timeIntervalSince1970 - 1800 // 30 minutes ago
        let etag = "\"123abc\""
        let metadata: [String: Any] = [
            "timestamp": timestamp,
            "etag": etag
        ]
        mockFileManager.dataToReturn = try JSONSerialization.data(withJSONObject: metadata)
        
        // Set up the content to be returned for the rules file
        let rulesJSON = "[{\"rule\":\"test\"}]"
        mockFileManager.stringToReturn = rulesJSON
        
        // When
        let result = sut.getMostRecentRules()
        
        // Then
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.rulesJSON, rulesJSON)
        XCTAssertEqual(result?.etag, etag)
        XCTAssertEqual(Double(result?.timestamp.timeIntervalSince1970 ?? 0), timestamp, accuracy: 0.001)
    }
    
    func test_clearCache_removesAllCacheFiles() {
        // Given
        let (sut, mockFileManager, documentsDirectory) = makeSUT()
        let expectedRulesPath = documentsDirectory.appendingPathComponent("trackerRules.json")
        let expectedMetadataPath = documentsDirectory.appendingPathComponent("trackerRules.metadata.json")
        
        // When
        sut.clearCache()
        
        // Then
        XCTAssertTrue(mockFileManager.removedItems.contains(expectedRulesPath))
        XCTAssertTrue(mockFileManager.removedItems.contains(expectedMetadataPath))
    }
    
    // MARK: - Helper Methods
    
    private func makeSUT(maxCacheDuration: TimeInterval = 3600) -> (sut: RuleCacheProtocol, fileOperations: MockFileOperations, cacheDirectory: URL) {
        let testDocsDirectory = URL(fileURLWithPath: "/test/documents")
        let mockFileOps = MockFileOperations(mockDocumentsDirectory: testDocsDirectory)
        let sut = RuleCache(fileOperations: mockFileOps, maxCacheDuration: maxCacheDuration)
        
        // The cache directory is one level down from the docs directory
        let cacheDirectory = testDocsDirectory.appendingPathComponent("TrackerRulesCache")
        trackForMemoryLeaks(sut)
        return (sut, mockFileOps, cacheDirectory)
    }
}
