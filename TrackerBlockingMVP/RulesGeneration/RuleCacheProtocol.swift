//
//  RuleCacheProtocol.swift
//  TrackerBlockingMVP
//
//  Created by FC on 28/2/25.
//

import Foundation

protocol RuleCacheProtocol {
    func storeCachedRules(rulesJSON: String, etag: String?) throws
    func getCachedRules() -> CachedRules?
    func getMostRecentRules() -> RuleSnapshot?
    func clearCache()
}
