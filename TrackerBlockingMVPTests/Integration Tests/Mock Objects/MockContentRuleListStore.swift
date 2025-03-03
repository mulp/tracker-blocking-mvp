//
//  MockContentRuleListStore.swift
//  TrackerBlockingMVP
//
//  Created by FC on 1/3/25.
//

import WebKit
@testable import TrackerBlockingMVP

class MockContentRuleListStore: ContentRuleListStoreProtocol {
    var mockRuleList: MockContentRuleList?
    var lookupCalled = false
    var compileCalled = false
    var removeCalled = false
    
    var lookupCompletion: ((String) -> (WKContentRuleList?, Error?))?
    var compileCompletion: ((String, String) -> (WKContentRuleList?, Error?))?
    var removeCompletion: ((String) -> Error?)?
    
    func lookUpContentRuleList(forIdentifier identifier: String, completionHandler: @escaping (WKContentRuleList?, Error?) -> Void) {
        lookupCalled = true
        if let completion = lookupCompletion {
            let (ruleList, error) = completion(identifier)
            completionHandler(ruleList, error)
        } else {
            completionHandler(nil, nil)
        }
    }
    
    func compileContentRuleList(forIdentifier identifier: String, encodedContentRuleList: String, completionHandler: @escaping (WKContentRuleList?, Error?) -> Void) {
        compileCalled = true
        if let completion = compileCompletion {
            let (ruleList, error) = completion(identifier, encodedContentRuleList)
            completionHandler(ruleList, error)
        } else {
            completionHandler(nil, nil)
        }
    }
    
    func removeContentRuleList(forIdentifier identifier: String, completionHandler: @escaping (Error?) -> Void) {
        removeCalled = true
        if let completion = removeCompletion {
            let error = completion(identifier)
            completionHandler(error)
        } else {
            completionHandler(nil)
        }
    }
}

class MockContentRuleList: WKContentRuleList {}
