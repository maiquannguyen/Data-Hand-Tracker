//
//  AuthTokenManager.swift
//  HandsTracker
//
//  Created by Nguyễn Mai Quân on 23/6/26.
//

import Foundation
import Combine

final class AuthTokenManager {

    static let shared = AuthTokenManager()
    private init() {}

    // MARK: - Published
    @Published private(set) var token: String?
    @Published private(set) var userID: String?

    private let defaults = UserDefaults.standard

    // MARK: - Token Management

    var isAuthenticated: Bool { token != nil }

    var bearerHeader: String? {
        guard let token else { return nil }
        return "Bearer \(token)"
    }

    func saveToken(_ token: String, userID: String) {
        self.token = token
        self.userID = userID
        defaults.set(token, forKey: Constants.Auth.tokenKey)
        defaults.set(userID, forKey: Constants.Auth.userIDKey)
    }

    func loadStoredToken() {
        token = defaults.string(forKey: Constants.Auth.tokenKey)
        userID = defaults.string(forKey: Constants.Auth.userIDKey)
    }

    func clearToken() {
        token = nil
        userID = nil
        defaults.removeObject(forKey: Constants.Auth.tokenKey)
        defaults.removeObject(forKey: Constants.Auth.userIDKey)
    }
}
