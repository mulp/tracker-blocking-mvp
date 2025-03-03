//
//  BrowserViewModelTests.swift
//  TrackerBlockingMVP
//
//  Created by FC on 26/2/25.
//


import XCTest
import Combine
@testable import TrackerBlockingMVP

class BrowserViewModelTests: XCTestCase {
    private var sut: BrowserViewModel!
    private var mockDataFetcher: MockTrackerDataFetcher!
    private var mockRuleGenerator: MockTrackerRulesGenerator!
    private var cancellables: Set<AnyCancellable>!
    
    override func setUp() {
        super.setUp()
        mockDataFetcher = MockTrackerDataFetcher()
        mockRuleGenerator = MockTrackerRulesGenerator()
        sut = BrowserViewModel(with: mockRuleGenerator, dataFetcher: mockDataFetcher)
        cancellables = []
    }
    
    override func tearDown() {
        sut = nil
        mockDataFetcher = nil
        mockRuleGenerator = nil
        cancellables = nil
        super.tearDown()
    }
    
    func test_fetchTrackerData_successfulFetch() {
        // Arrange
        let expectedModel = TrackerDataModel(etagIdentifier: "test-etag", data: Data())
        mockDataFetcher.stubbedFetchTrackerDataCompletionResult = .success(expectedModel)
        
        // Act & Assert
        let expectation = self.expectation(description: "Fetch Tracker Data")
        
        sut.fetchTrackerData()
            .sink { completion in
                switch completion {
                case .finished:
                    break
                case .failure(let error):
                    XCTFail("Should not receive error: \(error)")
                }
                expectation.fulfill()
            } receiveValue: { trackerData in
                XCTAssertEqual(trackerData.etagIdentifier, "test-etag")
            }
            .store(in: &cancellables)
        
        waitForExpectations(timeout: 1.0)
    }
    
    func test_generateRules_successfulGeneration() {
        // Arrange
        let testData = anyData()
        let allowlist: Set<String> = ["example.com"]
        let expectedRules = "test rules"
        mockRuleGenerator.stubbedGenerateRulesResult = expectedRules
        
        // Act & Assert
        let expectation = self.expectation(description: "Generate Rules")
        
        sut.generateRules(from: testData, allowlist: allowlist)
            .sink { completion in
                switch completion {
                case .finished:
                    break
                case .failure(let error):
                    XCTFail("Should not receive error: \(error)")
                }
                expectation.fulfill()
            } receiveValue: { rules in
                XCTAssertEqual(rules, expectedRules)
            }
            .store(in: &cancellables)
        
        waitForExpectations(timeout: 1.0)
    }
    
    func test_generateRules_failureScenario() {
        // Arrange
        let testData = anyData()
        let allowlist: Set<String> = ["example.com"]
        mockRuleGenerator.stubbedGenerateRulesError = RuleGenerationError.decodingFailed
        
        // Act & Assert
        let expectation = self.expectation(description: "Generate Rules Failure")
        
        sut.generateRules(from: testData, allowlist: allowlist)
            .sink { completion in
                switch completion {
                case .finished:
                    XCTFail("Should receive an error")
                case .failure(let error):
                    XCTAssertTrue(error is RuleGenerationError)
                }
                expectation.fulfill()
            } receiveValue: { _ in
                XCTFail("Should not receive value")
            }
            .store(in: &cancellables)
        
        waitForExpectations(timeout: 1.0)
    }
}

// Mock Classes for Testing
class MockTrackerDataFetcher: TrackerDataFetcherProtocol {
    var stubbedFetchTrackerDataCompletionResult: Result<TrackerDataModel, Error>?
    
    func fetchTrackerData(completion: @escaping (Result<TrackerDataModel, Error>) -> Void) {
        if let result = stubbedFetchTrackerDataCompletionResult {
            completion(result)
        }
    }
}

class MockTrackerRulesGenerator: TrackerRulesGeneratorProtocol {
    var stubbedGenerateRulesResult: String?
    var stubbedGenerateRulesError: Error?
    
    func generateRules(from data: Data, allowlist: Set<String>) throws -> String {
        if let error = stubbedGenerateRulesError {
            throw error
        }
        return stubbedGenerateRulesResult ?? ""
    }
}
