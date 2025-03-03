//
//  MockWebView.swift
//  TrackerBlockingMVP
//
//  Created by FC on 1/3/25.
//

import Foundation
import WebKit
@testable import TrackerBlockingMVP

class MockWebView: WebViewProtocol {
    var mockURL: URL?
    var url: URL? { return mockURL }
    
    // Track method calls
    private(set) var removeAllContentRuleListsCallCount = 0
    private(set) var addContentRuleListCallCount = 0
    
    // Store the last added rule list for verification
    private(set) var lastAddedRuleList: WKContentRuleList?
    
    // Completion handlers for test synchronization
    var removeAllContentRuleListsCompletion: (() -> Void)?
    var addContentRuleListCompletion: ((WKContentRuleList) -> Void)?
    
    func removeAllContentRuleLists() {
        removeAllContentRuleListsCallCount += 1
        removeAllContentRuleListsCompletion?()
    }
    
    func addContentRuleList(_ ruleList: WKContentRuleList) {
        addContentRuleListCallCount += 1
        lastAddedRuleList = ruleList
        addContentRuleListCompletion?(ruleList)
    }
}

