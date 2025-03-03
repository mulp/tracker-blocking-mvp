//
//  TrackerBlockerAdapter.swift
//  TrackerBlockingMVP
//
//  Created by FC on 26/2/25.
//

import Foundation
import WebKit
import Combine
import os.log

public typealias WebViewCompletionHandler = (Error?) -> Void

public class TrackerBlockerAdapter: ContentBlockerProtocol {
    private let logger = Logger(subsystem: "com.fc.TrackerBlockingMVP", category: "TrackerBlocking")
    private let allowListManager: AllowlistManagerProtocol
    private let contentRuleListStore: ContentRuleListStoreProtocol

    init(with allowListManager: AllowlistManagerProtocol,
         contentRuleListStore: ContentRuleListStoreProtocol = DefaultContentRuleListStore()) {
        self.allowListManager = allowListManager
        self.contentRuleListStore = contentRuleListStore
    }
    
    public func compileAndApplyContentRuleList(rulesJSON: String,
                                               etag: String?,
                                               webView: WebViewProtocol,
                                               completion: WebViewCompletionHandler? = nil) {
        
        logger.info("Attempting to apply content rules")
        
        // Check if the current domain is allowlisted
        if let url = webView.url, let host = url.host, allowListManager.isAllowlisted(domain: host) {
            logger.info("Domain is allowlisted: \(host). Removing rules.")
            webView.removeAllContentRuleLists()
            completion?(nil)
            return
        }
        
        // Generate deterministic identifier based on content
        let ruleListIdentifier = generateRuleListIdentifier(rulesJSON: rulesJSON, etag: etag)
        
        // First check if these rules are already compiled
        contentRuleListStore
            .lookUpContentRuleList(forIdentifier: ruleListIdentifier) { [weak self] existingRuleList, lookupError in
                guard let self = self else { return }
                
                if let existingRuleList = existingRuleList {
                    // Rules already exist, just apply them
                    self.applyRuleList(existingRuleList, to: webView, identifier: ruleListIdentifier, completion: completion)
                    return
                }
                
                // Compile new rules if none exist
                self.compileRuleList(rulesJSON: rulesJSON, identifier: ruleListIdentifier, webView: webView, completion: completion)
            }
    }
    
    
    func removeContentRuleList(with identifier: String, completion: WebViewCompletionHandler? = nil) {
        contentRuleListStore.removeContentRuleList(forIdentifier: identifier) { error in
            completion?(error)
        }
    }
    
    // Helper method to generate consistent rule list identifiers
    private func generateRuleListIdentifier(rulesJSON: String, etag: String?) -> String {
        if let etag = etag?.replacingOccurrences(of: "W/", with: "").replacingOccurrences(of: "\"", with: "") {
            return "TrackerRules_\(etag)"
        }
        
        // No ETag available, fall back to content hash
        var hashInt = 0
        for char in rulesJSON.unicodeScalars {
            hashInt = (hashInt &* 31) &+ Int(char.value)
        }
        
        return "TrackerRules_hash_\(abs(hashInt))"
    }
    
    private func applyRuleList(_ ruleList: WKContentRuleList,
                               to webView: WebViewProtocol,
                               identifier: String, completion: WebViewCompletionHandler?) {
        webView.removeAllContentRuleLists()
        webView.addContentRuleList(ruleList)
        logger.info("Applied existing content rule list: \(identifier)")
        completion?(nil)
    }
    
    private func compileRuleList(rulesJSON: String,
                                 identifier: String,
                                 webView: WebViewProtocol, completion: WebViewCompletionHandler?) {
        contentRuleListStore
            .compileContentRuleList(forIdentifier: identifier, encodedContentRuleList: rulesJSON) { [weak self] ruleList, error in
            
                if let error = error {
                    self?.logger.error("Error compiling content rule list: \(error.localizedDescription)")
                    completion?(error)
                    return
                }
                
                guard let ruleList = ruleList else {
                    self?.logger.error("Compiled content rule list is nil.")
                    completion?(GeneralError.ruleListCompilationError)
                    return
                }
                
                self?.applyRuleList(ruleList, to: webView, identifier: identifier, completion: completion)
        }
    }

}
