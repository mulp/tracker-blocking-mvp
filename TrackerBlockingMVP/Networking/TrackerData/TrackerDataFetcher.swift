//
//  TrackerDataFetcher.swift
//  TrackerBlockingMVP
//
//  Created by FC on 21/2/25.
//

import Foundation
import Combine

final class TrackerDataFetcher: TrackerDataFetcherProtocol {
    private let httpClient: HTTPClient
    private(set) public var trackerDataURL: URL
    private let storage: TrackerDataStorageProtocol

    init(httpClient: HTTPClient, trackerDataURL: URL, storage: TrackerDataStorageProtocol) {
        self.httpClient = httpClient
        self.trackerDataURL = trackerDataURL
        self.storage = storage
    }
    
    func fetchTrackerData(completion: @escaping (Result<TrackerDataModel, Error>) -> Void) {
        attemptFetch(retryCount: 0, completion: completion)
    }
    
    private func attemptFetch(retryCount: Int, completion: @escaping (Result<TrackerDataModel, Error>) -> Void) {
        httpClient.get(request: URLRequest(url: trackerDataURL)) { [weak self] result in
            guard let self = self else { return }
            
            switch result {
                case .success(let data, let response):
                    let etag = response.allHeaderFields["Etag"] as? String
                    
                    if let newData = data {
                        do {
                            try self.storage.save(newData)
                            completion(.success(TrackerDataModel(etagIdentifier: etag, data: newData))) // Store and use the new data
                        } catch {
                            completion(.failure(HTTPClientError.storageError))
                        }
                    } else {
                        if let storedData = try? self.storage.load() {
                            completion(.success(TrackerDataModel(etagIdentifier: etag, data: storedData))) // Use the last known dataset
                        } else {
                            completion(.failure(HTTPClientError.invalidResponse)) // No valid data available
                        }
                    }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}

extension TrackerDataFetcher {
    public static func compose(with trackerDataURL: URL) -> TrackerDataFetcher {
        let httpClient = URLSessionHTTPClient()
        let decoratedClient = ETagDecorator(decoratee: httpClient, etagStorage: EtagStorage())
        return TrackerDataFetcher(httpClient: decoratedClient, trackerDataURL: trackerDataURL, storage: TrackerDataStorage())
    }
}
