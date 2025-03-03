//
//  WebViewProtocol.swift
//  TrackerBlockingMVP
//
//  Created by FC on 1/3/25.
//

import Foundation
import WebKit

public protocol WebViewProtocol {
    var url: URL? { get }
    func removeAllContentRuleLists()
    func addContentRuleList(_ ruleList: WKContentRuleList)
}

extension WKWebView: WebViewProtocol {
    public func removeAllContentRuleLists() {
        configuration.userContentController.removeAllContentRuleLists()
    }
    
    public func addContentRuleList(_ ruleList: WKContentRuleList) {
        configuration.userContentController.add(ruleList)
    }
}
