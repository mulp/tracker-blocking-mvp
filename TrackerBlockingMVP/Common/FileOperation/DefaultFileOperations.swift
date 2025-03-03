//
//  DefaultFileOperations.swift
//  TrackerBlockingMVP
//
//  Created by FC on 28/2/25.
//


import Foundation

class DefaultFileOperations: FileOperations {
    private let fileManager: FileManager
    
    init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
    }
    
    func writeString(_ string: String, to url: URL, atomically: Bool, encoding: String.Encoding) throws {
        try string.write(to: url, atomically: atomically, encoding: encoding)
    }
    
    func writeData(_ data: Data, to url: URL) throws {
        try data.write(to: url)
    }
    
    func readData(from url: URL) throws -> Data {
        return try Data(contentsOf: url)
    }
    
    func readString(from url: URL) throws -> String {
        return try String(contentsOf: url)
    }
    
    func fileExists(atPath path: String) -> Bool {
        return fileManager.fileExists(atPath: path)
    }
    
    func removeItem(at url: URL) throws {
        try fileManager.removeItem(at: url)
    }
    
    func createDirectory(at url: URL, withIntermediateDirectories: Bool) throws {
        try fileManager.createDirectory(at: url, withIntermediateDirectories: withIntermediateDirectories)
    }
    
    func documentsDirectory() -> URL {
        guard let directory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            fatalError("Could not access documents directory")
        }
        return directory
    }
}
