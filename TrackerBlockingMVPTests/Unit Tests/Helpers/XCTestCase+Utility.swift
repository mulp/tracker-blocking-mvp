//
//  XCTestCase+Utility.swift
//  TrackerBlockingMVP
//
//  Created by FC on 21/2/25.
//

import XCTest

extension XCTestCase {
    public func anyURL() -> URL {
        return URL(string: "http://any-url.com")!
    }
    
    public func anyData() -> Data {
        return Data("any data".utf8)
    }
    
    public func anyNSError() -> NSError {
        return NSError(domain: "any error", code: 0)
    }
    
    public func anyHTTPURLResponse() -> HTTPURLResponse {
        return HTTPURLResponse(url: anyURL(), statusCode: 200, httpVersion: nil, headerFields: nil)!
    }
    
    public func nonHTTPURLResponse() -> URLResponse {
        return URLResponse(url: anyURL(), mimeType: nil, expectedContentLength: 0, textEncodingName: nil)
    }
    
    func makeItemJSON(_ items: [String: Any]) -> Data {
        let json = [items]
        return try! JSONSerialization.data(withJSONObject: json)
    }

    func makeItemsJSON(_ items: [String: Any]) -> Data? {
        if JSONSerialization.isValidJSONObject(items) {
            return try! JSONSerialization.data(withJSONObject: items)
        }
        return nil
    }

    func makeItemsArrayJSON(_ items: [[String: Any]]) -> Data? {
        do {
            return try JSONSerialization.data(withJSONObject: items)
        } catch {
            print(error)
            return nil
        }
    }

    func getData(name: String, withExtension: String = "json") -> Data {
        let bundle = Bundle(for: type(of: self))
        let fileUrl = bundle.url(forResource: name, withExtension: withExtension)
        let data = try! Data(contentsOf: fileUrl!)
        return data
    }

    func getDictionary(name: String, withExtension: String = "json") -> [String: Any]? {
        let d = getData(name: name, withExtension: withExtension)
        return try? JSONSerialization.jsonObject(with: d, options: .fragmentsAllowed) as? [String: Any]
    }

    public func anyHttpBody() -> [String: Any] {
        return ["a body key": "a body value"]
    }
}
