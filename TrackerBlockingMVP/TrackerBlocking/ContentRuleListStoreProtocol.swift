//
//  ContentRuleListStoreProtocol.swift
//  TrackerBlockingMVP
//
//  Created by FC on 1/3/25.
//

import WebKit

protocol ContentRuleListStoreProtocol {
    func lookUpContentRuleList(forIdentifier: String, completionHandler: @escaping (WKContentRuleList?, Error?) -> Void)
    func removeContentRuleList(forIdentifier: String, completionHandler: @escaping (Error?) -> Void)
    func compileContentRuleList(forIdentifier: String,
                                encodedContentRuleList: String,
                                completionHandler: @escaping (WKContentRuleList?, Error?) -> Void)
}
