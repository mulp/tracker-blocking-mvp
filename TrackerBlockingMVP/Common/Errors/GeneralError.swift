//
//  GeneralError.swift
//  TrackerBlockingMVP
//
//  Created by FC on 25/2/25.
//


public enum GeneralError: Swift.Error, Equatable {
    case invalidURL
    case connectivity
    case invalidData
    case mappingError
    case bodySerializationError
    case unexpectedValue
    case cannotAccessDB
    case databaseError
    case containerInactive
    case resourceNotFound(String?)
    case accessNotAllowed(String?)
    case badRequest(String?)
    case unknown(String?)
    case movedPermanently
    case generalError
    case invalidRequest(String?)
    case preconditionFailed(String?)
    case removedPermanently(String?)
    case ruleListCompilationError
    
    var localizedDescription: String? {
        switch self {
            case .resourceNotFound(let string), .accessNotAllowed(let string), .badRequest(let string), .unknown(let string), .invalidRequest(let string), .preconditionFailed(let string):
                return string;
            default:
                return "General error description is not available!"
        }
    }
}
