//
//  NetworkError.swift
//  NetworkLayerSwiftUIDemoApp
//
//  Created by Medikonda Anil kumar on 02/10/26.
//

import Foundation

enum NetworkError: Error {
    case invalidURL
    case noConnection
    case unauthorized
    case server(statusCode: Int)
    case decoding
    case cancelled
    case unknown
}
