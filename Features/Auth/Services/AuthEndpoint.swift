//
//  AuthEndpoint.swift
//  GymBud
//
//  Created by Codex on 01/05/26.
//

import Foundation

nonisolated enum AuthEndpoint: Sendable {
    case signUp(SignUpRequest)
    case logIn(LogInRequest)
}

nonisolated extension AuthEndpoint: APIEndpoint {
    nonisolated var path: String {
        switch self {
        case .signUp:
            return "auth/signup"
        case .logIn:
            return "auth/login"
        }
    }

    nonisolated var method: HTTPMethod {
        switch self {
        case .signUp, .logIn:
            return .post
        }
    }

    nonisolated var headers: [String: String] {
        switch self {
        case .signUp, .logIn:
            return ["Content-Type": "application/json"]
        }
    }

    nonisolated var body: Data? {
        switch self {
        case .signUp(let request):
            return try? JSONEncoder().encode(request)
        case .logIn(let request):
            return try? JSONEncoder().encode(request)
        }
    }
}
