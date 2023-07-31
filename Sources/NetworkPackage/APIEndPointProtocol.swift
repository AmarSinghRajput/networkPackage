//
//  ExtendableEndpoints.swift
//  
//
//  Created by Amar Kumar Singh on 31/07/23.
//

import Foundation

public protocol APIEndPointProtocol: Equatable {
    var endpoint: String { get }
    var mock_endpoint: String { get }
}
