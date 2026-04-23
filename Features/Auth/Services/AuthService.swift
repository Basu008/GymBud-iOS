//
//  AuthService.swift
//  GymBud
//
//  Created by Basu Singh on 23/04/26.
//

import Foundation

protocol AuthServiceProtocol{
    func startSignupFlow()
    func startSignInFlow()
}

final class AuthService: AuthServiceProtocol {
    func startSignupFlow() {
        // Hook navigation or analytics later
    }

    func startSignInFlow() {
        // Hook navigation or analytics later
    }
}

