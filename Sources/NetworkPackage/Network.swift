//
//  Network.swift
//
//
//  Created by Amar Kumar Singh on 31/07/23.
//

import Foundation

public class Network {
    
    // MARK: - Properties
    
    public static let shared = Network()
    private init() {}
    public var excludedEndpointsProvider: (() -> [any APIEndPointProtocol])?
    
    // MARK: - POST Method with JSON request body
    
    public func post<T: Decodable, E: Encodable>(endpoint: any APIEndPointProtocol, body: E, isMock: Bool = false, completion: @escaping (Result<T, APIError>) -> Void) {
        // Create the URL for the request
        guard let url = URL(string: "\(isMock ? endpoint.mock_endpoint : endpoint.endpoint)") else {
            completion(.failure(.invalidURL))
            return
        }
        
        // Create the URLRequest object with the POST method and the JSON content type
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Encode the request body as JSON data
        do {
            let encoder = JSONEncoder()
            let jsonData = try encoder.encode(body)
            request.httpBody = jsonData
        } catch {
            completion(.failure(.encodingFailed(error)))
            return
        }
        
        // Create a URLSessionDataTask to make the request
        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            // Handle any errors
            if let error = error {
                completion(.failure(.networkError(error)))
                return
            }
            
            // Ensure that we have a valid HTTP response
            guard let httpResponse = response as? HTTPURLResponse else {
                completion(.failure(.invalidResponse))
                return
            }
            
            // Ensure that we have valid response data
            guard let data = data else {
                completion(.failure(.noData))
                return
            }
            
            // Check the status code of the HTTP response
            switch httpResponse.statusCode {
            case 200..<300:
                // The request was successful, pass the response data to the completion handler
                let decoder = JSONDecoder()
                do {
                    let responseObject = try decoder.decode(T.self, from: data)
                    completion(.success(responseObject))
                } catch {
                    if selectedEnvironment == .production {
                        completion(.failure(.decodingFailed(error)))
                    }else {
                        //perform nested mock API or JSON reading on dev only
                        if let excludedEndpointsProvider = self.excludedEndpointsProvider {
                            let excludedEndpoints = excludedEndpointsProvider()
                            let containsExcludedEndpoint = excludedEndpoints.contains { excludedEndpoint in
                                return excludedEndpoint.endpoint == endpoint.endpoint
                            }
                            if containsExcludedEndpoint {
                                completion(.failure(.httpError(statusCode: httpResponse.statusCode)))
                            }else{
                                self.handleMockAPICase(endpoint: endpoint, body: body, isMock: isMock, completion: completion)
                                return
                            }
                        }
                    }
                }
            default:
                // There was an error with the API on production, return the error
                if selectedEnvironment == .production {
                    completion(.failure(.httpError(statusCode: httpResponse.statusCode)))
                }else {
                    // perform nested mock API or JSON reading on dev only
                    if let excludedEndpointsProvider = self.excludedEndpointsProvider {
                        let excludedEndpoints = excludedEndpointsProvider()
                        let containsExcludedEndpoint = excludedEndpoints.contains { excludedEndpoint in
                            return excludedEndpoint.endpoint == endpoint.endpoint
                        }
                        if containsExcludedEndpoint {
                            completion(.failure(.httpError(statusCode: httpResponse.statusCode)))
                        }else {
                            self.handleMockAPICase(endpoint: endpoint, body: body, isMock: isMock, completion: completion)
                            return
                        }
                    }
                }
            }
        }
        // Start the data task
        task.resume()
    }
}

extension Network {
    //  developed to handle a situation during development when API fails to respond
    //  if API fails call mock API
    // if mock fails read form JSON stored locally containing API mock responses
    
    func handleMockAPICase<T: Decodable, E: Encodable>(endpoint: any APIEndPointProtocol, body: E, isMock: Bool = false, completion: @escaping (Result<T, APIError>) -> Void) {
        //if isMock == true here it means Mock API has also failed and now we have to pick from JSON file
        if isMock{
            //reading from JSON here
            if let mockModel = JSONReader.fetchMockAPIResponse(fileName: endpoint.endpoint.description, responseType: T.self) {
                completion(.success(mockModel))
            }else {
                //reading from JSON failed
                completion(.failure(.noData))
            }
            //if isMock == false here it means API has failed and now we have to call MOCK API
        }else{
            //mock API called
            self.post(endpoint: endpoint, body: body, isMock: true, completion: completion)
        }
    }
}
