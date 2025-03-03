//
//  ETagDecoratorTests.swift
//  TrackerBlockingMVPTests
//
//  Created by FC on 21/2/25.
//

import XCTest
@testable import TrackerBlockingMVP

final class ETagDecoratorTests: XCTestCase {
    
    func test_getRequestsPassThroughWhenNoETagStored() {
        let url = anyURL()
        let expectedData = anyData()
        let (sut, httpClient, _) = makeSUT()
        
        let expectation = expectation(description: "Wait for completion")
        sut.get(request: URLRequest(url: url)) { result in
            switch result {
            case .success(let data, _):
                XCTAssertEqual(data, expectedData)
            case .failure:
                XCTFail("Expected success, got failure instead")
            }
            expectation.fulfill()
        }
        httpClient.complete(withStatusCode: 200, data: expectedData)
        
        waitForExpectations(timeout: 1.0)
    }
    
    func test_getRequestsAddETagHeaderIfAvailable() {
        let url = anyURL()
        let etag = "12345"
        let (sut, httpClient, etagStorage) = makeSUT()
        httpClient.capturedRequestHeaders = [API_HEADER_FIELD_NONE_MATCH: etag]
        etagStorage.store(etag: etag, for: url.absoluteString)
        
        sut.get(request: URLRequest(url: url)) { _ in }
        
        XCTAssertEqual(httpClient.capturedRequestHeaders[API_HEADER_FIELD_NONE_MATCH], etag)
    }
    
    func test_getStoredETagWhenResponseContainsIt() {
        let url = anyURL()
        let responseHeaders = ["Etag": "67890"]
        let responseData = anyData()
        let (sut, httpClient, etagStorage) = makeSUT()

        let expectation = expectation(description: "Wait for completion")
        sut.get(request: URLRequest(url: url)) { _ in expectation.fulfill() }
        
        httpClient.complete(withStatusCode: 200, data: responseData, headers: responseHeaders)

        waitForExpectations(timeout: 1.0)
        
        XCTAssertEqual(etagStorage.retrieveETag(for: url.absoluteString), "67890")
    }
    
    func test_getReturnsEmptyDataOnNotModifiedResponse() {
        let url = anyURL()
        let response = HTTPURLResponse(url: url, statusCode: 304, httpVersion: nil, headerFields: nil)!
        let (sut, httpClient, _) = makeSUT()

        let expectation = expectation(description: "Wait for completion")
        sut.get(request: URLRequest(url: url)) { result in
            switch result {
            case .success(let data, let receivedResponse):
                XCTAssertNil(data, "Expected no data for 304 response")
                XCTAssertEqual(receivedResponse.statusCode, response.statusCode)
                XCTAssertEqual(receivedResponse.url, response.url)
            case .failure:
                XCTFail("Expected success with empty data, got failure instead")
            }
            expectation.fulfill()
        }

        httpClient.complete(withResponseCode: response, data: nil)
        
        waitForExpectations(timeout: 1.0)
    }
    
    func test_getStoreEtagIfIsPresentInTheHTTPHeader() {
        let url = anyURL()
        let etag = "12345"
        let response = HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: [API_HEADER_FIELD_ETAG: etag])!
        let (sut, httpClient, etagStorage) = makeSUT()

        let expectation = expectation(description: "Wait for completion")
        sut.get(request: URLRequest(url: url)) { [etagStorage] result in
            switch result {
            case .success(let data, let receivedResponse):
                XCTAssertNotNil(data, "Expected a valid data for 200 response")
                XCTAssertEqual(receivedResponse.statusCode, response.statusCode)
                XCTAssertEqual(receivedResponse.url, response.url)
                XCTAssertEqual(etagStorage.retrieveETag(for: url.absoluteString), etag)
            case .failure:
                XCTFail("Expected success with empty data, got failure instead")
            }
            expectation.fulfill()
        }

        httpClient.complete(withResponseCode: response, data: anyData())
        
        waitForExpectations(timeout: 1.0)
    }
    
    func test_getProcessesWeakETagCorrectly() {
        let url = anyURL()
        let weakEtag = "W/\"2d947c0d1f9115326143c11efe31decd\""
        let response = HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: [API_HEADER_FIELD_ETAG: weakEtag])!
        let (sut, httpClient, etagStorage) = makeSUT()

        let expectation = expectation(description: "Wait for completion")
        sut.get(request: URLRequest(url: url)) { _ in expectation.fulfill() }
        
        httpClient.complete(withResponseCode: response, data: anyData())

        waitForExpectations(timeout: 1.0)
        
        // Verify the ETag was stored without the W/ prefix and quotes
        // Note: This assumes that your ETagStorage implementation is correctly handling the weak indicator removal
        let storedETag = etagStorage.retrieveETag(for: url.absoluteString)
        XCTAssertNotNil(storedETag)
        XCTAssertFalse(storedETag?.contains("W/") ?? false)
    }

    func test_getFails_whenHTTPClientFails() {
        let (sut, httpClient, _) = makeSUT()
        let expectedError = HTTPClientError.connectivity

        let exp = expectation(description: "Wait for completion")
        sut.get(request: URLRequest(url: anyURL())) { result in
            switch result {
            case .failure(let receivedError):
                XCTAssertEqual(receivedError, expectedError)
            default:
                XCTFail("Expected failure, got \(result) instead")
            }
            exp.fulfill()
        }

        httpClient.complete(with: expectedError)
        wait(for: [exp], timeout: 1.0)
    }

    func test_get_doesNotDeliverResultAfterSUTInstanceHasBeenDeallocated() {
        let httpClient = HTTPClientSpy()
        var sut: ETagDecorator? = ETagDecorator(decoratee: httpClient, etagStorage: ETagStorageSpy())
        
        var capturedResults = [HTTPClientResult]()
        sut?.get(request: URLRequest(url: anyURL())) { capturedResults.append($0) }

        sut = nil
        httpClient.complete(withStatusCode: 200, data:anyData())

        XCTAssertTrue(capturedResults.isEmpty)
    }

    private func makeSUT() -> (sut: ETagDecorator, httpClient: HTTPClientSpy, etagStorage: ETagStorageSpy) {
        let httpClientSpy = HTTPClientSpy()
        let etagStorageSpy = ETagStorageSpy()
        let client = ETagDecorator(decoratee: httpClientSpy, etagStorage: etagStorageSpy)
        trackForMemoryLeaks(client)
        trackForMemoryLeaks(httpClientSpy)
        trackForMemoryLeaks(etagStorageSpy)
        return (client, httpClientSpy, etagStorageSpy)
    }
}

// MARK: - Spy Classes (from Helpers)
class ETagStorageSpy: ETagStorageProtocol {
    private var storage: [String: String] = [:]
    
    func store(etag: String, for key: String) {
        storage[key] = etag
    }
    
    func retrieveETag(for key: String) -> String? {
        return storage[key]
    }
}
