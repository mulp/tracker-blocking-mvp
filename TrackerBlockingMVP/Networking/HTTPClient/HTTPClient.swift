//
//  HTTPClient.swift
//  TrackerBlockingMVP
//
//  Created by FC on 21/2/25.
//

import Foundation

public enum HTTPClientResult {
    case success(Data?, HTTPURLResponse)
    case failure(HTTPClientError)
}

public protocol HTTPClient {
    func get(request: URLRequest, completion: @escaping (HTTPClientResult) -> Void)
}
