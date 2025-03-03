//
//  RuleCache.swift
//  TrackerBlockingMVP
//
//  Created by FC on 27/2/25.
//

import Foundation


public typealias CachedRules = (rulesJSON: String, etag: String?)

class RuleCache: RuleCacheProtocol {
    private let fileOperations: FileOperations
    private let cacheDirectory: URL
    private let maxCacheDuration: TimeInterval
    
    init(fileOperations: FileOperations = DefaultFileOperations(), maxCacheDuration: TimeInterval = 86400 * 7) {
        self.fileOperations = fileOperations
        
        // Get documents directory
        let documentsDirectory = fileOperations.documentsDirectory()
        self.cacheDirectory = documentsDirectory.appendingPathComponent("TrackerRulesCache")
        self.maxCacheDuration = maxCacheDuration
        
        // Ensure cache directory exists
        try? fileOperations.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
    }
    
    func storeCachedRules(rulesJSON: String, etag: String?) throws {
        // Create files for rules and metadata
        let rulesFile = cacheDirectory.appendingPathComponent("trackerRules.json")
        let metadataFile = cacheDirectory.appendingPathComponent("trackerRules.metadata.json")
        
        // Store rules JSON
        try fileOperations.writeString(rulesJSON, to: rulesFile, atomically: true, encoding: String.Encoding.utf8)
        
        // Store metadata
        let metadata: [String: Any] = [
            "timestamp": Date().timeIntervalSince1970,
            "etag": etag ?? ""
        ]
        let metadataData = try JSONSerialization.data(withJSONObject: metadata)
        try fileOperations.writeData(metadataData, to: metadataFile)
    }
    
    func getCachedRules() -> CachedRules? {
        let rulesFile = cacheDirectory.appendingPathComponent("trackerRules.json")
        let metadataFile = cacheDirectory.appendingPathComponent("trackerRules.metadata.json")
        
        guard
            fileOperations.fileExists(atPath: rulesFile.path),
            fileOperations.fileExists(atPath: metadataFile.path)
        else {
            return nil
        }
        
        do {
            // Read metadata
            let metadataData = try fileOperations.readData(from: metadataFile)
            guard let metadata = try JSONSerialization.jsonObject(with: metadataData) as? [String: Any],
                  let timestamp = metadata["timestamp"] as? TimeInterval else {
                return nil
            }
            
            // Check cache validity
            let currentTimestamp = Date().timeIntervalSince1970
            guard currentTimestamp - timestamp < maxCacheDuration else {
                return nil
            }
            
            // Read rules
            let rulesJSON = try fileOperations.readString(from: rulesFile)
            let etag = metadata["etag"] as? String
            
            return (rulesJSON, etag)
        } catch {
            print("Error reading cached rules: \(error)")
            return nil
        }
    }
    
    func getMostRecentRules() -> RuleSnapshot? {
        guard let (rulesJSON, etag) = getCachedRules() else {
            return nil
        }
        
        // Read the timestamp from metadata again
        let metadataFile = cacheDirectory.appendingPathComponent("trackerRules.metadata.json")
        do {
            let metadataData = try fileOperations.readData(from: metadataFile)
            guard let metadata = try JSONSerialization.jsonObject(with: metadataData) as? [String: Any],
                  let timestamp = metadata["timestamp"] as? TimeInterval else {
                return nil
            }
            
            return RuleSnapshot(
                rulesJSON: rulesJSON,
                etag: etag,
                timestamp: Date(timeIntervalSince1970: timestamp)
            )
        } catch {
            print("Error reading metadata for recent rules: \(error)")
            return nil
        }
    }

    func clearCache() {
        let rulesFile = cacheDirectory.appendingPathComponent("trackerRules.json")
        let metadataFile = cacheDirectory.appendingPathComponent("trackerRules.metadata.json")
        
        try? fileOperations.removeItem(at: rulesFile)
        try? fileOperations.removeItem(at: metadataFile)
    }
}
