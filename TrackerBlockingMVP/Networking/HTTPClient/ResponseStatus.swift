//
//  ResponseStatus.swift
//  TrackerBlockingMVP
//
//  Created by FC on 21/2/25.
//


import Foundation

public enum ResponseStatus: Int {
    case ok = 200
    case forbbiden = 403
    case notFound = 404
    case unauthorized = 401
    case badRequest = 400
    case preconditionFailed = 412
    case gone = 410
    case movedPermanently = 301
    case serverError = 500
    case unknown = 0
}

extension HTTPURLResponse {
    public var isOK: Bool {
        (200...299).contains(self.statusCode)
    }

    public var status: ResponseStatus {
        ResponseStatus(rawValue: statusCode) ?? .unknown
    }
}
