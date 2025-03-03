//
//  TrackerDataFetcherTests.swift
//  TrackerBlockingMVP
//
//  Created by FC on 26/2/25.
//

import XCTest
@testable import TrackerBlockingMVP

class TrackerDataFetcherTests: XCTestCase {
    
    func test_fetchTrackerData_returnsDataAndETagOnSuccess() {
        let (sut, httpClient, _) = makeSUT()
        let expectedData = anyData()
        let expectedETag = "etag123"
        
        var receivedResult: Result<TrackerDataModel, Error>?
        let exp = expectation(description: "Wait for completion")
        
        sut.fetchTrackerData { result in
            receivedResult = result
            exp.fulfill()
        }
        
        // Complete with success, including an ETag
        httpClient.complete(withStatusCode: 200, data: expectedData, headers: ["Etag": expectedETag])
        
        wait(for: [exp], timeout: 1.0)
        
        // Validate the result includes both data and ETag
        switch receivedResult {
            case .success(let model):
                XCTAssertEqual(model.data, expectedData)
                XCTAssertEqual(model.etagIdentifier, expectedETag)
            case .failure, .none:
                XCTFail("Expected success with data and ETag")
        }
    }
    
    func test_fetchTrackerData_usesCachedDataWhenResponseIs304() {
        let (sut, httpClient, storage) = makeSUT()
        let cachedData = anyData()
        let response = HTTPURLResponse(url: anyURL(), statusCode: 304, httpVersion: nil, headerFields: nil)!
        
        // Set up storage with cached data
        try? storage.save(cachedData)
        
        var receivedResult: Result<TrackerDataModel, Error>?
        let exp = expectation(description: "Wait for completion")
        
        sut.fetchTrackerData { result in
            receivedResult = result
            exp.fulfill()
        }
        
        // Complete with 304 Not Modified
        httpClient.complete(withResponseCode: response, data: nil)
        
        wait(for: [exp], timeout: 1.0)
        
        // Validate fetcher returned the cached data
        switch receivedResult {
            case .success(let model):
                XCTAssertEqual(model.data, cachedData)
                // ETag might be nil or whatever was in the response
            case .failure, .none:
                XCTFail("Expected success with cached data")
        }
    }
    
    func test_fetchTrackerData_returnsErrorWhenNoDataAvailableAnd304Response() {
        let (sut, httpClient, storage) = makeSUT()
        let response = HTTPURLResponse(url: anyURL(), statusCode: 304, httpVersion: nil, headerFields: nil)!
        
        // Ensure storage has no data
        
        var receivedResult: Result<TrackerDataModel, Error>?
        let exp = expectation(description: "Wait for completion")
        
        sut.fetchTrackerData { result in
            receivedResult = result
            exp.fulfill()
        }
        
        // Complete with 304 Not Modified
        httpClient.complete(withResponseCode: response, data: nil)
        
        wait(for: [exp], timeout: 1.0)
        
        // Validate error returned when no cached data available
        switch receivedResult {
            case .failure(let error):
                XCTAssertEqual(error as? HTTPClientError, .invalidResponse)
            case .success, .none:
                XCTFail("Expected failure when no data available")
        }
    }
    
    func test_fetchTrackerData_storesNewDataOnSuccess() {
        let (sut, httpClient, storage) = makeSUT()
        let newData = anyData()
        
        let exp = expectation(description: "Wait for completion")
        
        sut.fetchTrackerData { result in
            exp.fulfill()
        }
        
        // Complete with success and new data
        httpClient.complete(withStatusCode: 200, data: newData)
        
        wait(for: [exp], timeout: 1.0)
        
        // Verify data was stored
        XCTAssertEqual(try? storage.load(), newData)
    }
    
    // Helper methods
    
    private func makeSUT() -> (TrackerDataFetcher, HTTPClientSpy, TrackerDataStorageSpy) {
        let httpClient = HTTPClientSpy()
        let storage = TrackerDataStorageSpy()
        let sut = TrackerDataFetcher(httpClient: httpClient, trackerDataURL: anyURL(), storage: storage)
        
        trackForMemoryLeaks(httpClient)
        trackForMemoryLeaks(storage)
        trackForMemoryLeaks(sut)
        
        return (sut, httpClient, storage)
    }
}

// Additional spy implementations

class TrackerDataStorageSpy: TrackerDataStorageProtocol {
    private var storedData: Data?
    
    func save(_ data: Data) throws {
        storedData = data
    }
    
    func load() throws -> Data? {
        return storedData
    }
}
