//
//  MockFileManager.swift
//  TrackerBlockingMVP
//
//  Created by FC on 28/2/25.
//

import Foundation
import TrackerBlockingMVP

class MockFileOperations: FileOperations {
    var writtenStrings: [String: String] = [:]
    var writtenData: [String: Data] = [:]
    var dataToReturn: Data?
    var stringToReturn: String?
    var fileExistsReturnValue = true
    var removedItems: [URL] = []
    var createDirectoryCalled = false
    var createDirectoryURL: URL?
    var mockDocumentsDirectory: URL
    
    init(mockDocumentsDirectory: URL) {
        self.mockDocumentsDirectory = mockDocumentsDirectory
    }
    
    func writeString(_ string: String, to url: URL, atomically: Bool, encoding: String.Encoding) throws {
        writtenStrings[url.path] = string
    }
    
    func writeData(_ data: Data, to url: URL) throws {
        writtenData[url.path] = data
    }
    
    func readData(from url: URL) throws -> Data {
        if let data = dataToReturn {
            return data
        }
        throw NSError(domain: "MockError", code: 1)
    }
    
    func readString(from url: URL) throws -> String {
        if let string = stringToReturn {
            return string
        }
        throw NSError(domain: "MockError", code: 1)
    }
    
    func fileExists(atPath path: String) -> Bool {
        return fileExistsReturnValue
    }
    
    func removeItem(at url: URL) throws {
        removedItems.append(url)
    }
    
    func createDirectory(at url: URL, withIntermediateDirectories: Bool) throws {
        createDirectoryCalled = true
        createDirectoryURL = url
    }
    
    func documentsDirectory() -> URL {
        return mockDocumentsDirectory
    }
}
