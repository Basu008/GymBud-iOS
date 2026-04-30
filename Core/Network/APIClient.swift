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
        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            throw APIError.requestFailed(statusCode: httpResponse.statusCode, data: data)
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
}

nonisolated extension APIClient: APIClientProtocol {}

nonisolated enum APIError: Error, Sendable {
    case invalidResponse
    case requestFailed(statusCode: Int, data: Data)
}
