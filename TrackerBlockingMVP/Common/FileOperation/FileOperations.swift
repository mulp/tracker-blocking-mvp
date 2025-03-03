//
//  FileOperations.swift
//  TrackerBlockingMVP
//
//  Created by FC on 28/2/25.
//

import Foundation

public protocol FileOperations {
    func writeString(_ string: String, to url: URL, atomically: Bool, encoding: String.Encoding) throws
    func writeData(_ data: Data, to url: URL) throws
    func readData(from url: URL) throws -> Data
    func readString(from url: URL) throws -> String
    func fileExists(atPath: String) -> Bool
    func removeItem(at url: URL) throws
    func createDirectory(at url: URL, withIntermediateDirectories: Bool) throws
    func documentsDirectory() -> URL
}
