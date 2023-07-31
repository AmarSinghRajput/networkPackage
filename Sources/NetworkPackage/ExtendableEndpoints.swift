//
//  ExtendableEndpoints.swift
//  
//
//  Created by Amar Kumar Singh on 31/07/23.
//

import Foundation

public enum APIEndPoint {
    case sample
    //endpoints
    var endpoint: String {
        switch self {
        case .sample:
            return  "sample"
            
        }
    }
    //mock endpoints
    var mock_endpoint: String {
        switch self {
        case .sample:
            return "mockSample"
        }
    }
}


