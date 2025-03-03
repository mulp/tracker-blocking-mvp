//
//  ETagDecorator.swift
//  TrackerBlockingMVP
//
//  Created by FC on 21/2/25.
//

import Foundation

let API_HEADER_FIELD_NONE_MATCH: String = "If-None-Match"
let API_HEADER_FIELD_ETAG: String = "Etag"

public enum ETagResult {
    case newData(Data, HTTPURLResponse)
    case notModified(HTTPURLResponse)
    case failure(HTTPClientError)
}

final class ETagDecorator: HTTPClient {
    private let decoratee: HTTPClient
    private let etagStorage: ETagStorageProtocol

    init(decoratee: HTTPClient, etagStorage: ETagStorageProtocol) {
        self.decoratee = decoratee
        self.etagStorage = etagStorage
    }

    func get(request: URLRequest, completion: @escaping (HTTPClientResult) -> Void) {
        guard let url = request.url else {
            completion(.failure(.invalidURL))
            return
        }
        var etagRequest = request
        etagRequest.httpMethod = "GET"
        etagRequest.cachePolicy = .reloadIgnoringLocalCacheData
        
        // Retrieve stored ETag for the given URL
        if let storedETag = etagStorage.retrieveETag(for: url.absoluteString) {
            etagRequest.addValue(storedETag, forHTTPHeaderField: API_HEADER_FIELD_NONE_MATCH)
        }

        decoratee.get(request: etagRequest) { [weak self] result in
            guard let self = self else { return }

            switch result {
                case .success(let data, let response):
                    if let etag = response.allHeaderFields[API_HEADER_FIELD_ETAG] as? String {
                        self.etagStorage.store(etag: etag.removeWeakIndicator(), for: url.absoluteString)
                    }
                    // Just pass through the result - the client will handle nil data
                    completion(.success(data, response))
                case .failure(let error):
                    completion(.failure(error))
            }
        }
    }    
}
