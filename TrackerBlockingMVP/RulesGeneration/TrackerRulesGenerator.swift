//
//  TrackerRulesGenerator.swift
//  TrackerBlockingMVP
//
//  Created by FC on 24/2/25.
//

import Foundation
import TrackerRadarKit
import os

enum RuleGenerationError: Error {
    case decodingFailed
    case fallbackNotAvailable
}

protocol TrackerRulesGeneratorProtocol {
    func generateRules(from data: Data, allowlist: Set<String>) throws -> String
}

final class TrackerRulesGenerator: TrackerRulesGeneratorProtocol {
    private let storage: TrackerDataStorageProtocol
    private let logger = Logger(subsystem: "com.fc.TrackerBlockingMVP", category: "TrackerRules")
    
    init(storage: TrackerDataStorageProtocol = TrackerDataStorage()) {
        self.storage = storage
    }
    
    func generateRules(from data: Data, allowlist: Set<String>) throws -> String {
        do {
            logger.info("Attempting to decode tracker data.")
            let trackerDataSet = try JSONDecoder().decode(TrackerData.self, from: data)
            let rules = convertToRuleList(trackerDataSet, allowlist: allowlist)
            logger.info("Successfully generated rules from primary dataset.")
            return rules
        } catch {
            logger.error("Failed to decode TrackerData from primary dataset. Error: \(error.localizedDescription)")
            
            // Attempt to load the last known valid dataset
            if let storedData = try? storage.load() {
                do {
                    logger.info("Loading fallback dataset from storage.")
                    let trackerDataSet = try JSONDecoder().decode(TrackerData.self, from: storedData)
                    let rules = convertToRuleList(trackerDataSet, allowlist: allowlist)
                    logger.info("Successfully generated rules from fallback dataset.")
                    return rules
                } catch {
                    logger.error("Failed to decode fallback TrackerData. Error: \(error.localizedDescription)")
                    throw RuleGenerationError.decodingFailed
                }
            } else {
                logger.critical("No valid tracker data available. Rule generation failed.")
                throw RuleGenerationError.fallbackNotAvailable
            }
        }
    }
    
    private func convertToRuleList(_ trackerDataSet: TrackerData, allowlist: Set<String>) -> String {
        logger.info("Converting tracker data to content blocking rules using ContentBlockerRulesBuilder.")
        
        let rulesBuilder = ContentBlockerRulesBuilder(trackerData: trackerDataSet)
        
        // Pass the allowlist to exclude entities from blocking
        let rules = rulesBuilder.buildRules(withExceptions: Array(allowlist))
        
        do {
            let jsonData = try JSONEncoder().encode(rules)
            logger.info("Successfully converted rules using ContentBlockerRulesBuilder.")
            return String(data: jsonData, encoding: .utf8) ?? "[]"
        } catch {
            logger.error("Failed to serialize rules from ContentBlockerRulesBuilder. Error: \(error.localizedDescription)")
            return "[]" // Return an empty list if serialization fails
        }
    }
}
