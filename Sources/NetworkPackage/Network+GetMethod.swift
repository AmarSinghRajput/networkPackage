//
//  File.swift
//  
//
//  Created by Amar Kumar Singh on 01/08/23.
//

import Foundation

extension Network {
    public func get<T: Decodable>(endpoint: any APIEndPointProtocol, isMock: Bool = false, completion: @escaping (Result<T, APIError>) -> Void) {
        // Create the URL for the request
        if isMock {
            guard (endpoint.mock_endpoint != nil) else {
                completion(.failure(.invalidURL))
                return
            }
        }
        guard let url = URL(string: "\(isMock ? endpoint.mock_endpoint! : endpoint.endpoint)") else {
            completion(.failure(.invalidURL))
            return
        }

        // Create the URLRequest object with the GET method
        var request = URLRequest(url: url)
        request.httpMethod = "GET"

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
                    if selectedEnvironment == .production || selectedEnvironment == .staging {
                        completion(.failure(.decodingFailed(error)))
                    } else {
                        // Perform nested mock API or JSON reading on dev only
                        if let excludedEndpointsProvider = self.excludedEndpointsProvider {
                            let excludedEndpoints = excludedEndpointsProvider()
                            let containsExcludedEndpoint = excludedEndpoints.contains { excludedEndpoint in
                                return excludedEndpoint.endpoint == endpoint.endpoint
                            }
                            if containsExcludedEndpoint {
                                completion(.failure(.httpError(statusCode: httpResponse.statusCode)))
                            } else {
                                self.handleMockGETAPI(endpoint: endpoint, isMock: isMock, completion: completion)
                                return
                            }
                        } else {
                            self.handleMockGETAPI(endpoint: endpoint, isMock: isMock, completion: completion)
                            return
                        }
                    }
                }
            default:
                // There was an error with the API on production, return the error
                if selectedEnvironment == .production || selectedEnvironment == .staging {
                    completion(.failure(.httpError(statusCode: httpResponse.statusCode)))
                } else {
                    // Perform nested mock API or JSON reading on dev only
                    if let excludedEndpointsProvider = self.excludedEndpointsProvider {
                        let excludedEndpoints = excludedEndpointsProvider()
                        let containsExcludedEndpoint = excludedEndpoints.contains { excludedEndpoint in
                            return excludedEndpoint.endpoint == endpoint.endpoint
                        }
                        if containsExcludedEndpoint {
                            completion(.failure(.httpError(statusCode: httpResponse.statusCode)))
                        } else {
                            self.handleMockGETAPI(endpoint: endpoint, isMock: isMock, completion: completion)
                            return
                        }
                    } else {
                        self.handleMockGETAPI(endpoint: endpoint, isMock: isMock, completion: completion)
                        return
                    }
                }
            }
        }
        // Start the data task
        task.resume()
    }
}

extension Network {
    func handleMockGETAPI<T: Decodable>(endpoint: any APIEndPointProtocol, isMock: Bool = false, completion: @escaping (Result<T, APIError>) -> Void) {
        if isMock {
            // If isMock == true, it means the Mock API has also failed, and now we have to pick data from a JSON file.
            guard let jsonName = endpoint.mock_json else {
                completion(.failure(.invalidURL))
                return
            }
            if let mockModel = JSONReader.fetchMockAPIResponse(fileName: jsonName, responseType: T.self) {
                completion(.success(mockModel))
            } else {
                // Reading from JSON failed.
                completion(.failure(.noData))
            }
        } else {
            // For non-mock requests, call the GET method for non-mock requests.
            self.get(endpoint: endpoint, isMock: false, completion: completion)
        }
    }
}
