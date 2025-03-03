//
//  TrackerDataStorage.swift
//  TrackerBlockingMVP
//
//  Created by FC on 21/2/25.
//

import Foundation

final class TrackerDataStorage: TrackerDataStorageProtocol {
    private let fileManager: FileManager
    private var storageURL: URL?
    let storageFilename: String = "tracker_data.json"
    
    init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
    }
    
    func save(_ data: Data) throws {
        guard
            let storageURL = getStorageURL(for: storageFilename)
        else {
            throw TrackerDataStorageError.documentsDirectoryNotFound
        }
        
        do {
            try data.write(to: storageURL, options: .atomic)
        } catch {
            throw TrackerDataStorageError.saveFailed(error)
        }
    }
    
    func load() throws -> Data? {
        guard
            let storageURL = getStorageURL(for: storageFilename)
        else {
            return nil
        }

        guard fileManager.fileExists(atPath: storageURL.path) else {
            return nil
        }
        
        do {
            return try Data(contentsOf: storageURL)
        } catch {
            throw TrackerDataStorageError.loadFailed(error)
        }
    }
    
    // MARK: - Helpers
    private func getStorageURL(for filename: String) -> URL? {
        guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return nil
        }
        return documentsDirectory.appendingPathComponent(filename)
    }
}

// MARK: - Error Handling
enum TrackerDataStorageError: Error {
    case saveFailed(Error)
    case loadFailed(Error)
    case documentsDirectoryNotFound
}
