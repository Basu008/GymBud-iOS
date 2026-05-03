//
//  APIClient.swift
//  GymBud
//
//  Created by Codex on 01/05/26.
//

import Foundation

nonisolated protocol APIClientProtocol: Sendable {
    nonisolated func request(_ endpoint: any APIEndpoint) async throws -> Data
    nonisolated func request<DecodedResponse: Decodable & Sendable>(
        _ endpoint: any APIEndpoint,
        responseType: DecodedResponse.Type
    ) async throws -> DecodedResponse
}

nonisolated final class APIClient: Sendable {
    private let session: URLSession

    nonisolated init(session: URLSession = .shared) {
        self.session = session
    }

    nonisolated func request(_ endpoint: any APIEndpoint) async throws -> Data {
        let request = APIRequestBuilder.makeRequest(for: endpoint)
        let data: Data
        let response: URLResponse

        do {
            (data, response) = try await session.data(for: request)
        } catch {
            Self.logNetworkFailure(for: endpoint, request: request, error: error)
            throw error
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            Self.logInvalidResponse(for: endpoint, request: request, response: response)
            throw APIError.invalidResponse
        }

        Self.logResponse(for: endpoint, request: request, response: httpResponse, data: data)

        guard (200...299).contains(httpResponse.statusCode) else {
            throw APIError.requestFailed(
                statusCode: httpResponse.statusCode,
                data: data,
                messages: Self.errorMessages(from: data)
            )
        }

        return data
    }

    nonisolated func request<DecodedResponse: Decodable & Sendable>(
        _ endpoint: any APIEndpoint,
        responseType: DecodedResponse.Type
    ) async throws -> DecodedResponse {
        let data = try await request(endpoint)
        let decoder = JSONDecoder()
        return try decoder.decode(responseType, from: data)
    }

    private static func errorMessages(from data: Data) -> [String] {
        guard let response = try? JSONDecoder().decode(APIErrorResponse.self, from: data) else {
            return []
        }

        return response.messages
    }

    private static func logNetworkFailure(for endpoint: any APIEndpoint, request: URLRequest, error: Error) {
        #if DEBUG
        guard shouldLog(endpoint) else { return }
        print("""
        [GymBud API] \(request.httpMethod ?? "HTTP") \(request.url?.absoluteString ?? "<missing-url>")
        Network error: \(error.localizedDescription)
        """)
        #endif
    }

    private static func logInvalidResponse(for endpoint: any APIEndpoint, request: URLRequest, response: URLResponse) {
        #if DEBUG
        guard shouldLog(endpoint) else { return }
        print("""
        [GymBud API] \(request.httpMethod ?? "HTTP") \(request.url?.absoluteString ?? "<missing-url>")
        Invalid response: \(response)
        """)
        #endif
    }

    private static func logResponse(for endpoint: any APIEndpoint, request: URLRequest, response: HTTPURLResponse, data: Data) {
        #if DEBUG
        guard shouldLog(endpoint) else { return }
        let responseBody = String(data: data, encoding: .utf8) ?? "<\(data.count) bytes, non-UTF8 response>"
        print("""
        [GymBud API] \(request.httpMethod ?? "HTTP") \(request.url?.absoluteString ?? "<missing-url>")
        Status: \(response.statusCode)
        Response: \(responseBody)
        """)
        #endif
    }

    private static func shouldLog(_ endpoint: any APIEndpoint) -> Bool {
        #if DEBUG
        endpoint is UserEndpoint || endpoint is RoutineEndpoint || endpoint is ExerciseReferenceEndpoint || endpoint is WorkoutEndpoint
        #else
        false
        #endif
    }
}

nonisolated extension APIClient: APIClientProtocol {}

nonisolated enum APIError: Error, Sendable {
    case invalidResponse
    case requestFailed(statusCode: Int, data: Data, messages: [String])
}
