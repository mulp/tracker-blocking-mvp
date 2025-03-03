//
//  ContentBlockerProtocol.swift
//  TrackerBlockingMVP
//
//  Created by FC on 1/3/25.
//

import Foundation
import WebKit

protocol ContentBlockerProtocol {
    func compileAndApplyContentRuleList(rulesJSON: String, etag: String?, webView: WebViewProtocol, completion: WebViewCompletionHandler?)
    func removeContentRuleList(with identifier: String, completion: WebViewCompletionHandler?)
}

