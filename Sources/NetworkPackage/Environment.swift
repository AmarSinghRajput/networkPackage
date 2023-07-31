//
//  NetworkEnvironment.swift
//  
//
//  Created by Amar Kumar Singh on 31/07/23.
//

import Foundation

public enum NetworkEnvironment {
    case development
    case staging
    case production
}

public var selectedEnvironmentProvider: (() -> NetworkEnvironment)?

public var selectedEnvironment: NetworkEnvironment {
    return selectedEnvironmentProvider?() ?? .development
}
