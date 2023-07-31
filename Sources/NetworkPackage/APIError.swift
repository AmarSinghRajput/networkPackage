//
//  APIError.swift
//  
//
//  Created by Amar Kumar Singh on 31/07/23.
//

import Foundation

public enum APIError: Error {
    case invalidURL
    case noData
    case httpError(statusCode: Int)
    case invalidResponse
    case encodingFailed(Error)
    case decodingFailed(Error)
    case networkError(Error)
    case unknownError
}
