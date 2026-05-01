//
//  UserEndpoint.swift
//  GymBud
//
//  Created by Codex on 01/05/26.
//

import Foundation

nonisolated enum UserEndpoint: Sendable {
    case currentUser(accessToken: String)
    case updateProfile(UpdateProfileRequest, accessToken: String)
    case updateBodyMetric(BodyMetricRequest, accessToken: String)
    case uploadProfileImage(imageData: Data, accessToken: String)
}

nonisolated extension UserEndpoint: APIEndpoint {
    nonisolated var path: String {
        switch self {
        case .currentUser, .updateProfile:
            return "users/me"
        case .updateBodyMetric:
            return "users/me/body-metrics"
        case .uploadProfileImage:
            return "media/images"
        }
    }

    nonisolated var method: HTTPMethod {
        switch self {
        case .currentUser:
            return .get
        case .updateProfile:
            return .patch
        case .updateBodyMetric, .uploadProfileImage:
            return .post
        }
    }

    nonisolated var headers: [String: String] {
        switch self {
        case .currentUser(let accessToken):
            return ["Authorization": "Bearer \(accessToken)"]
        case .updateProfile(_, let accessToken), .updateBodyMetric(_, let accessToken):
            return [
                "Authorization": "Bearer \(accessToken)",
                "Content-Type": "application/json"
            ]
        case .uploadProfileImage(_, let accessToken):
            return [
                "Authorization": "Bearer \(accessToken)",
                "Content-Type": "multipart/form-data; boundary=\(Self.profileImageBoundary)"
            ]
        }
    }

    nonisolated var body: Data? {
        switch self {
        case .currentUser:
            return nil
        case .updateProfile(let request, _):
            return try? JSONEncoder().encode(request)
        case .updateBodyMetric(let request, _):
            return try? JSONEncoder().encode(request)
        case .uploadProfileImage(let imageData, _):
            return Self.makeProfileImageMultipartBody(imageData: imageData)
        }
    }

    private static let profileImageBoundary = "Boundary-\(UUID().uuidString)"

    private static func makeProfileImageMultipartBody(imageData: Data) -> Data {
        var body = Data()
        let boundaryPrefix = "--\(profileImageBoundary)\r\n"

        body.appendString(boundaryPrefix)
        body.appendString("Content-Disposition: form-data; name=\"entity_type\"\r\n\r\n")
        body.appendString("profile\r\n")

        body.appendString(boundaryPrefix)
        body.appendString("Content-Disposition: form-data; name=\"image\"; filename=\"profile.jpg\"\r\n")
        body.appendString("Content-Type: image/jpeg\r\n\r\n")
        body.append(imageData)
        body.appendString("\r\n")

        body.appendString("--\(profileImageBoundary)--\r\n")
        return body
    }
}

private extension Data {
    nonisolated mutating func appendString(_ string: String) {
        append(Data(string.utf8))
    }
}
