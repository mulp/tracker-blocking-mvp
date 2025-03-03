//
//  TrackerDataFetcherProtocol.swift
//  TrackerBlockingMVP
//
//  Created by FC on 26/2/25.
//

import Foundation

protocol TrackerDataFetcherProtocol {
    func fetchTrackerData(completion: @escaping (Result<TrackerDataModel, Error>) -> Void)
}

