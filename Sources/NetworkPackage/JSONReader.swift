//
//  JSONReader.swift
//  
//
//  Created by Amar Kumar Singh on 31/07/23.
//

import Foundation

class JSONReader {
    static func fetchMockAPIResponse<T: Decodable>(fileName: String, responseType: T.Type) -> T? {
        if let url = Bundle.main.url(forResource: fileName, withExtension: "json") {
            // Read data from JSON file
            do {
                let data = try Data(contentsOf: url)
                // Decode JSON data into Swift data structure
                do {
                    let decoder = JSONDecoder()
                    let model = try decoder.decode(responseType, from: data)
                    return model
                } catch {
                    print(error.localizedDescription)
                }
            } catch {
                print(error.localizedDescription)
            }
        }
        return nil
    }
}
