//
//  BrowserViewModel.swift
//  TrackerBlockingMVP
//
//  Created by FC on 25/2/25.
//

import Foundation
import Combine

public typealias DDGOPublisher<T> = AnyPublisher<T, Error>
public typealias DDGOPublisherNever<T> = PassthroughSubject<T, Error>

protocol BrowserViewModelProtocol {
    func fetchTrackerData() -> DDGOPublisher<TrackerDataModel>
    func generateRules(from data: Data, allowlist: Set<String>) -> DDGOPublisher<String>
}

public class BrowserViewModel: BrowserViewModelProtocol {
    private let dataFetcher: TrackerDataFetcherProtocol
    private let ruleGenerator: TrackerRulesGeneratorProtocol
    private let ruleCache: RuleCacheProtocol

    init(with ruleGenerator: TrackerRulesGeneratorProtocol,
         dataFetcher: TrackerDataFetcherProtocol,
         ruleCache: RuleCacheProtocol = RuleCache()) {
        self.ruleGenerator = ruleGenerator
        self.dataFetcher = dataFetcher
        self.ruleCache = ruleCache
    }
    
    func fetchTrackerData() -> DDGOPublisher<TrackerDataModel> {
        Deferred {
            Future { [weak self] completion in
                self?.dataFetcher.fetchTrackerData(completion: completion)
            }
        }
        .eraseToAnyPublisher()
    }
    
    func generateRules(from data: Data, allowlist: Set<String>) -> DDGOPublisher<String> {
        Deferred {
            Future { [weak self] promise in
                guard let self = self else {
                    promise(.failure(GeneralError.generalError))
                    return
                }
                do {
                    let rules = try self.ruleGenerator.generateRules(from: data, allowlist: allowlist)
                    promise(.success(rules))
                } catch {
                    promise(.failure(error))
                }
            }
        }
        .eraseToAnyPublisher()
    }
}
