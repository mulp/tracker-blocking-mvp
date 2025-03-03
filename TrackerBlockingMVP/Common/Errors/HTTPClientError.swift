//
//  HTTPClientError.swift
//  TrackerBlockingMVP
//
//  Created by FC on 21/2/25.
//

public enum HTTPClientError: Error, Equatable {
    case connectivity
    case invalidResponse
    case statusCode(Int)
    case storageError
    case invalidURL
}
