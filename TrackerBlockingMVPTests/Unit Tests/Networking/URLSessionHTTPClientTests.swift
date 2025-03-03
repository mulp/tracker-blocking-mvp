//
//  URLSessionHTTPClientTests.swift
//  TrackerBlockingMVP
//
//  Created by FC on 21/2/25.
//

import XCTest
@testable import TrackerBlockingMVP

class URLSessionHTTPClientTests: XCTestCase {
    
    override class func setUp() {
        super.setUp()
        URLProtocolStub.startInterceptingRequests()
    }
    
    override class func tearDown() {
        super.tearDown()
        URLProtocolStub.stopInterceptingRequests()
    }
    
    func test_getFromURL_performsGetRequestWithURL() {
        let sut = makeSUT()
        URLProtocolStub.stub(data: anyData(), response: anyHTTPURLResponse(), error: nil)
        
        let exp = expectation(description: "Wait for completion")
        var receivedResult: HTTPClientResult!
        
        sut.get(request: URLRequest(url: anyURL())) { result in
            receivedResult = result
            exp.fulfill()
        }
        
        wait(for: [exp], timeout: 1.0)
        let result = resultValuesFor(receivedResult, error: nil)
        
        XCTAssertEqual(result?.data, anyData())
        XCTAssertEqual(result?.response.url, anyURL())
        XCTAssertEqual(result?.response.statusCode, anyHTTPURLResponse().statusCode)
    }
    
    func test_getFromURL_handlesNotModifiedResponse() {
        let sut = makeSUT()
        let response = HTTPURLResponse(url: anyURL(), statusCode: 304, httpVersion: nil, headerFields: nil)!
        URLProtocolStub.stub(data: nil, response: response, error: nil)
        
        let exp = expectation(description: "Wait for completion")
        var receivedResult: HTTPClientResult!
        
        sut.get(request: URLRequest(url: anyURL())) { result in
            receivedResult = result
            exp.fulfill()
        }
        
        wait(for: [exp], timeout: 1.0)
        
        guard let receivedResult = receivedResult else {
            XCTFail("Expected to receive a result")
            return
        }

        switch receivedResult {
            case .success(let data, let receivedResponse):
                XCTAssertNil(data, "Expected nil data for 304 response")
                XCTAssertEqual(receivedResponse.statusCode, 304)
            case .failure:
                XCTFail("Expected success with nil data, got failure instead")
        }
    }
    
    func test_getFromURL_handlesErrorResponse() {
        let sut = makeSUT()
        let error = NSError(domain: "test", code: 0)
        URLProtocolStub.stub(data: nil, response: nil, error: error)
        
        let exp = expectation(description: "Wait for completion")
        var receivedResult: HTTPClientResult!
        
        sut.get(request: URLRequest(url: anyURL())) { result in
            receivedResult = result
            exp.fulfill()
        }
        
        wait(for: [exp], timeout: 1.0)
        
        guard let receivedResult = receivedResult else {
            XCTFail("Expected to receive a result")
            return
        }

        switch receivedResult {
            case .failure(let receivedError):
                XCTAssertEqual(receivedError, .connectivity)
            case .success:
                XCTFail("Expected error, got success instead")
        }
    }
    
    func test_getFromURL_handlesNonHTTPResponse() {
        let sut = makeSUT()
        let nonHTTPResponse = URLResponse(url: anyURL(), mimeType: nil, expectedContentLength: 0, textEncodingName: nil)
        URLProtocolStub.stub(data: anyData(), response: nonHTTPResponse, error: nil)
        
        let exp = expectation(description: "Wait for completion")
        var receivedResult: HTTPClientResult!
        
        sut.get(request: URLRequest(url: anyURL())) { result in
            receivedResult = result
            exp.fulfill()
        }
        
        wait(for: [exp], timeout: 1.0)
        
        switch receivedResult {
            case .failure(let receivedError):
                XCTAssertEqual(receivedError, .invalidResponse)
            default:
                XCTFail("Expected error, got success instead")
        }
    }
    
    private func makeSUT() -> HTTPClient {
        let client = URLSessionHTTPClient(session: .shared)
        trackForMemoryLeaks(client)
        return client
    }
    
    private func resultValuesFor(_ result: HTTPClientResult,
                                 error: Error?,
                                 file: StaticString = #file,
                                 line: UInt = #line) -> (data: Data, response: HTTPURLResponse)? {
        
        switch result {
            case let .success(data, response):
                return (data!, response) // Force unwrap data as we expect it for 200 responses
            default:
                XCTFail("Expected success, got \(result) instead", file: file, line: line)
                return nil
        }
    }
    
    private func resultErrorFor(_ result: HTTPClientResult,
                                error: Error?,
                                file: StaticString = #file,
                                line: UInt = #line) -> Error? {
        switch result {
            case let .failure(error):
                return error
            default:
                XCTFail("Expected failure, got \(result) instead", file: file, line: line)
                return nil
        }
    }
}
