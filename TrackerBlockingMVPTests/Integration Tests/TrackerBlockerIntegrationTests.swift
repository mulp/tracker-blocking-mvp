//
//  TrackerBlockerIntegrationTests.swift
//  TrackerBlockingMVP
//
//  Created by FC on 1/3/25.
//

import XCTest
import WebKit
import Combine
@testable import TrackerBlockingMVP

class TrackerBlockerIntegrationTests: XCTestCase {
    
    // MARK: - Integration Tests
    
    func testFullFlowWithNonAllowlistedDomain() {
        // Given
        let testURL = URL(string: "https://example.com")!
        let testRulesJSON = "[{\"trigger\":{\"url-filter\":\".*\",\"resource-type\":[\"script\"]},\"action\":{\"type\":\"block\"}}]"
        let testEtag = "\"12345\""
        let expectedIdentifier = "TrackerRules_12345"
        
        let (sut, mocks) = makeSUT(url: testURL)
        mocks.contentRuleListStore.mockRuleList = MockContentRuleList()
        
        // Expectations
        let lookupExpectation = expectation(description: "Lookup content rule list")
        let compileExpectation = expectation(description: "Compile content rule list")
        let addRuleListExpectation = expectation(description: "Add rule list to webview")
        
        // When
        mocks.contentRuleListStore.lookupCompletion = { identifier in
            XCTAssertEqual(identifier, expectedIdentifier)
            lookupExpectation.fulfill()
            return (nil, nil) // Return nil to force compilation path
        }
        
        mocks.contentRuleListStore.compileCompletion = { identifier, json in
            XCTAssertEqual(identifier, expectedIdentifier)
            XCTAssertEqual(json, testRulesJSON)
            compileExpectation.fulfill()
            return (mocks.contentRuleListStore.mockRuleList, nil)
        }
        
        mocks.webView.addContentRuleListCompletion = { ruleList in
            XCTAssertTrue(ruleList === mocks.contentRuleListStore.mockRuleList)
            addRuleListExpectation.fulfill()
        }
        
        // Execute
        let completionExpectation = expectation(description: "Completion handler called")
        sut.compileAndApplyContentRuleList(rulesJSON: testRulesJSON, etag: testEtag, webView: mocks.webView) { error in
            XCTAssertNil(error)
            completionExpectation.fulfill()
        }
        
        // Then
        wait(for: [lookupExpectation, compileExpectation, addRuleListExpectation, completionExpectation], timeout: 2.0)
        XCTAssertEqual(mocks.webView.removeAllContentRuleListsCallCount, 1)
        XCTAssertEqual(mocks.webView.addContentRuleListCallCount, 1)
    }
    
    func testFullFlowWithAllowlistedDomain() {
        // Given
        let testURL = URL(string: "https://allowlisted-example.com")!
        let testHost = "allowlisted-example.com"
        let testRulesJSON = "[{\"trigger\":{\"url-filter\":\".*\"},\"action\":{\"type\":\"block\"}}]"
        
        let (sut, mocks) = makeSUT(url: testURL, allowlistedDomains: [testHost])
        
        // Execute
        let completionExpectation = expectation(description: "Completion handler called")
        sut.compileAndApplyContentRuleList(rulesJSON: testRulesJSON, etag: nil, webView: mocks.webView) { error in
            XCTAssertNil(error)
            completionExpectation.fulfill()
        }
        
        // Then
        wait(for: [completionExpectation], timeout: 1.0)
        XCTAssertEqual(mocks.webView.removeAllContentRuleListsCallCount, 1)
        XCTAssertEqual(mocks.webView.addContentRuleListCallCount, 0)
        XCTAssertEqual(mocks.allowListManager.isAllowlistedCallCount, 1)
        XCTAssertFalse(mocks.contentRuleListStore.lookupCalled)
        XCTAssertFalse(mocks.contentRuleListStore.compileCalled)
    }
    
    func testFullFlowWithExistingRuleList() {
        // Given
        let testURL = URL(string: "https://example.com")!
        let testRulesJSON = "[{\"trigger\":{\"url-filter\":\".*\"},\"action\":{\"type\":\"block\"}}]"
        let testEtag = "\"67890\""
        let expectedIdentifier = "TrackerRules_67890"
        
        let (sut, mocks) = makeSUT(url: testURL)
        mocks.contentRuleListStore.mockRuleList = MockContentRuleList()
        
        // Expectations
        let lookupExpectation = expectation(description: "Lookup content rule list")
        let addRuleListExpectation = expectation(description: "Add rule list to webview")
        
        // When
        mocks.contentRuleListStore.lookupCompletion = { identifier in
            XCTAssertEqual(identifier, expectedIdentifier)
            lookupExpectation.fulfill()
            return (mocks.contentRuleListStore.mockRuleList, nil) // Return existing rule list
        }
        
        mocks.webView.addContentRuleListCompletion = { ruleList in
            XCTAssertTrue(ruleList === mocks.contentRuleListStore.mockRuleList)
            addRuleListExpectation.fulfill()
        }
        
        // Execute
        let completionExpectation = expectation(description: "Completion handler called")
        sut.compileAndApplyContentRuleList(rulesJSON: testRulesJSON, etag: testEtag, webView: mocks.webView) { error in
            XCTAssertNil(error)
            completionExpectation.fulfill()
        }
        
        // Then
        wait(for: [lookupExpectation, addRuleListExpectation, completionExpectation], timeout: 1.0)
        XCTAssertEqual(mocks.webView.removeAllContentRuleListsCallCount, 1)
        XCTAssertEqual(mocks.webView.addContentRuleListCallCount, 1)
        XCTAssertTrue(mocks.contentRuleListStore.lookupCalled)
        XCTAssertFalse(mocks.contentRuleListStore.compileCalled)
    }
    
    func testFullFlowWithCompilationError() {
        // Given
        let testURL = URL(string: "https://example.com")!
        let testRulesJSON = "[INVALID JSON]"
        let testEtag = "\"12345\""
        
        let (sut, mocks) = makeSUT(url: testURL)
        let testError = NSError(domain: "WKErrorDomain", code: 1, userInfo: [NSLocalizedDescriptionKey: "Compilation failed"])
        
        // Expectations
        let lookupExpectation = expectation(description: "Lookup content rule list")
        let compileExpectation = expectation(description: "Compile content rule list")
        
        // When
        mocks.contentRuleListStore.lookupCompletion = { identifier in
            lookupExpectation.fulfill()
            return (nil, nil) // Return nil to force compilation path
        }
        
        mocks.contentRuleListStore.compileCompletion = { identifier, json in
            compileExpectation.fulfill()
            return (nil, testError)
        }
        
        // Execute
        let completionExpectation = expectation(description: "Completion handler called")
        sut.compileAndApplyContentRuleList(rulesJSON: testRulesJSON, etag: testEtag, webView: mocks.webView) { error in
            XCTAssertNotNil(error)
            XCTAssertEqual((error as NSError?)?.domain, "WKErrorDomain")
            completionExpectation.fulfill()
        }
        
        // Then
        wait(for: [lookupExpectation, compileExpectation, completionExpectation], timeout: 1.0)
        XCTAssertEqual(mocks.webView.addContentRuleListCallCount, 0)
    }
    
    func testRuleListRemoval() {
        // Given
        let identifier = "TrackerRules_12345"
        let (sut, mocks) = makeSUT()
        
        // Expectations
        let removalExpectation = expectation(description: "Remove rule list")
        mocks.contentRuleListStore.removeCompletion = { id in
            XCTAssertEqual(id, identifier)
            removalExpectation.fulfill()
            return nil
        }
        
        // Execute
        let completionExpectation = expectation(description: "Completion handler called")
        sut.removeContentRuleList(with: identifier) { error in
            XCTAssertNil(error)
            completionExpectation.fulfill()
        }
        
        // Then
        wait(for: [removalExpectation, completionExpectation], timeout: 1.0)
        XCTAssertTrue(mocks.contentRuleListStore.removeCalled)
    }
    
    // MARK: - Helper Methods
    private func makeSUT(url: URL? = nil, allowlistedDomains: [String] = [])
    -> (sut: TrackerBlockerAdapter,
        mocks: (webView: MockWebView, allowListManager: MockAllowlistManager, contentRuleListStore: MockContentRuleListStore)) {
        // Create mocks
        let mockWebView = MockWebView()
        mockWebView.mockURL = url
        
        let mockAllowListManager = MockAllowlistManager()
        mockAllowListManager.allowlistedDomains = allowlistedDomains
        
        let mockContentRuleListStore = MockContentRuleListStore()
        
        // Create SUT
        let sut = TrackerBlockerAdapter(
            with: mockAllowListManager,
            contentRuleListStore: mockContentRuleListStore
        )
        
        // Return SUT and mocks tuple
        return (sut, (mockWebView, mockAllowListManager, mockContentRuleListStore))
    }
}
