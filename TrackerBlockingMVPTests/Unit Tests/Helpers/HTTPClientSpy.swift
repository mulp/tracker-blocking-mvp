//
//  HTTPClientSpy.swift
//  TrackerBlockingMVP
//
//  Created by FC on 22/2/25.
//

import Foundation
import TrackerBlockingMVP

class HTTPClientSpy: HTTPClient {
    private var messages = [(request: URLRequest, completion: (HTTPClientResult) -> Void)]()
    
    var requests: [URLRequest] {
        messages.map { $0.request }
    }
    
    var capturedRequestHeaders: [String: String] = [:]

    func get(request: URLRequest, completion: @escaping (HTTPClientResult) -> Void) {
        messages.append((request, completion))
    }
    
    func complete(with error: HTTPClientError, at index: Int = 0) {
        messages[index].completion(.failure(error))
    }

    func complete(withStatusCode code: Int, data: Data, headers: [String: String]? = nil, at index: Int = 0) {
        guard let url = requests[index].url else { return }
        let response = HTTPURLResponse(
            url: url,
            statusCode: code,
            httpVersion: nil,
            headerFields: headers
        )!
        messages[index].completion(.success(data, response))
    }

    func complete(withResponseCode response: HTTPURLResponse, data: Data?, at index: Int = 0) {
        messages[index].completion(.success(data, response))
    }
}
