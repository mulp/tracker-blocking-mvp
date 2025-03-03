//
//  DefaultContentRuleListStore.swift
//  TrackerBlockingMVP
//
//  Created by FC on 1/3/25.
//

import WebKit

class DefaultContentRuleListStore: ContentRuleListStoreProtocol {
    func lookUpContentRuleList(forIdentifier identifier: String, completionHandler: @escaping (WKContentRuleList?, Error?) -> Void) {
        WKContentRuleListStore.default().lookUpContentRuleList(forIdentifier: identifier, completionHandler: completionHandler)
    }
    
    func compileContentRuleList(forIdentifier identifier: String, encodedContentRuleList: String, completionHandler: @escaping (WKContentRuleList?, Error?) -> Void) {
        WKContentRuleListStore.default().compileContentRuleList(forIdentifier: identifier, encodedContentRuleList: encodedContentRuleList, completionHandler: completionHandler)
    }
    
    func removeContentRuleList(forIdentifier identifier: String, completionHandler: @escaping (Error?) -> Void) {
        WKContentRuleListStore.default().removeContentRuleList(forIdentifier: identifier, completionHandler: completionHandler)
    }
}
