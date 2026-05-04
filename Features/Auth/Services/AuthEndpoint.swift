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
    case logOut(accessToken: String)
}

nonisolated extension AuthEndpoint: APIEndpoint {
    nonisolated var path: String {
        switch self {
        case .signUp:
            return "auth/signup"
        case .logIn:
            return "auth/login"
        case .logOut:
            return "auth/logout"
        }
    }

    nonisolated var method: HTTPMethod {
        switch self {
        case .signUp, .logIn, .logOut:
            return .post
        }
    }

    nonisolated var headers: [String: String] {
        switch self {
        case .signUp, .logIn:
            return ["Content-Type": "application/json"]
        case .logOut(let accessToken):
            return ["Authorization": "Bearer \(accessToken)"]
        }
    }

    nonisolated var body: Data? {
        switch self {
        case .signUp(let request):
            return try? JSONEncoder().encode(request)
        case .logIn(let request):
            return try? JSONEncoder().encode(request)
        case .logOut:
            return nil
        }
    }
}
