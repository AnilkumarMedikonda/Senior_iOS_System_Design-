//
//  HTTPClient.swift
//  NetworkLayerSwiftUIDemoApp
//
//  Created by Medikonda Anil kumar on 02/10/26.
//

import Foundation

protocol HTTPClient {
    func send(_ request: URLRequest, completion: @escaping (Data?, URLResponse?, Error?) -> Void)
}

extension URLSession: HTTPClient {
    func send(_ request: URLRequest, completion: @escaping (Data?, URLResponse?, Error?) -> Void) {
        dataTask(with: request, completionHandler: completion).resume()
    }
}
