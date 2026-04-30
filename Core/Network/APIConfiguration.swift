//
//  APIConfiguration.swift
//  GymBud
//
//  Created by Codex on 01/05/26.
//

import Foundation

nonisolated enum APIConfiguration {
    private static let rootURL = URL(string: "https://gymbud-lwdp.onrender.com")!
    private static let apiPathComponents = ["v1", "api"]

    nonisolated static var baseURL: URL {
        apiPathComponents.reduce(rootURL) { url, pathComponent in
            url.appendingPathComponent(pathComponent)
        }
    }

    nonisolated static func url(for path: String) -> URL {
        path
            .split(separator: "/")
            .map(String.init)
            .reduce(baseURL) { url, pathComponent in
                url.appendingPathComponent(pathComponent)
            }
    }
}

nonisolated enum HTTPMethod: String, Sendable {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case patch = "PATCH"
    case delete = "DELETE"
}

nonisolated protocol APIEndpoint: Sendable {
    nonisolated var path: String { get }
    nonisolated var method: HTTPMethod { get }
    nonisolated var headers: [String: String] { get }
    nonisolated var queryItems: [URLQueryItem] { get }
    nonisolated var body: Data? { get }
}

extension APIEndpoint {
    nonisolated var headers: [String: String] { [:] }
    nonisolated var queryItems: [URLQueryItem] { [] }
    nonisolated var body: Data? { nil }
}

nonisolated enum APIRequestBuilder {
    nonisolated static func makeRequest(for endpoint: any APIEndpoint) -> URLRequest {
        var components = URLComponents(
            url: APIConfiguration.url(for: endpoint.path),
            resolvingAgainstBaseURL: false
        )
        components?.queryItems = endpoint.queryItems.isEmpty ? nil : endpoint.queryItems

        var request = URLRequest(url: components?.url ?? APIConfiguration.url(for: endpoint.path))
        request.httpMethod = endpoint.method.rawValue
        request.httpBody = endpoint.body

        endpoint.headers.forEach { key, value in
            request.setValue(value, forHTTPHeaderField: key)
        }

        return request
    }
}
