//
//  URLSessionHTTPClient.swift
//  TrackerBlockingMVP
//
//  Created by FC on 21/2/25.
//

import Foundation

public class URLSessionHTTPClient: HTTPClient {
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }
    
    public func get(request: URLRequest, completion: @escaping (HTTPClientResult) -> Void) {
        let task = session.dataTask(with: request) { data, response, error in
            guard error == nil else {
                completion(.failure(.connectivity))
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse, let data = data else {
                completion(.failure(.invalidResponse))
                return
            }
            
            // Special handling for 304 Not Modified
            if httpResponse.statusCode == 304 {
                // Return success with nil data to indicate not modified
                completion(.success(nil, httpResponse))
                return
            }

            guard (200...299).contains(httpResponse.statusCode) else {
                completion(.failure(.statusCode(httpResponse.statusCode)))
                return
            }

            completion(.success(data, httpResponse))
        }
        task.resume()
    }
}
