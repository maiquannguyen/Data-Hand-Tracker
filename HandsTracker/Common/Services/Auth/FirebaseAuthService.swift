//
//  FirebaseAuthService.swift
//  HandsTracker
//
//  Created by Nguyễn Mai Quân on 23/6/26.
//

import Foundation
import FirebaseAuth
import GoogleSignIn
import Combine
import Firebase

// MARK: - Auth Result Model

struct AuthResult {
    let userID: String
    let email: String?
    let displayName: String?
    let token: String
}

// MARK: - Protocol

protocol FirebaseAuthServiceProtocol {
    func login(email: String, password: String) -> AnyPublisher<AuthResult, Error>
    func register(email: String, password: String, displayName: String) -> AnyPublisher<AuthResult, Error>
    func signInWithGoogle(presentingViewController: UIViewController) -> AnyPublisher<AuthResult, Error>
    func sendPasswordReset(email: String) -> AnyPublisher<Void, Error>
    func signOut() throws
    func refreshToken() -> AnyPublisher<String, Error>
}

// MARK: - Implementation

final class FirebaseAuthService: FirebaseAuthServiceProtocol {

    static let shared = FirebaseAuthService()
    private init() {}

    // MARK: - Login

    func login(email: String, password: String) -> AnyPublisher<AuthResult, Error> {
        Future { promise in
            Auth.auth().signIn(withEmail: email, password: password) { result, error in
                if let error {
                    promise(.failure(error))
                    return
                }
                guard let user = result?.user else {
                    promise(.failure(AuthError.noUser))
                    return
                }
                user.getIDToken { token, error in
                    if let error {
                        promise(.failure(error))
                        return
                    }
                    guard let token else {
                        promise(.failure(AuthError.noToken))
                        return
                    }
                    let authResult = AuthResult(
                        userID: user.uid,
                        email: user.email,
                        displayName: user.displayName,
                        token: token
                    )
                    AuthTokenManager.shared.saveToken(token, userID: user.uid)
                    promise(.success(authResult))
                }
            }
        }
        .eraseToAnyPublisher()
    }

    // MARK: - Register

    func register(email: String, password: String, displayName: String) -> AnyPublisher<AuthResult, Error> {
        Future { promise in
            Auth.auth().createUser(withEmail: email, password: password) { result, error in
                if let error {
                    promise(.failure(error))
                    return
                }
                guard let user = result?.user else {
                    promise(.failure(AuthError.noUser))
                    return
                }

                // Set display name
                let changeRequest = user.createProfileChangeRequest()
                changeRequest.displayName = displayName
                changeRequest.commitChanges { _ in
                    user.getIDToken { token, error in
                        if let error {
                            promise(.failure(error))
                            return
                        }
                        guard let token else {
                            promise(.failure(AuthError.noToken))
                            return
                        }
                        let authResult = AuthResult(
                            userID: user.uid,
                            email: user.email,
                            displayName: displayName,
                            token: token
                        )
                        AuthTokenManager.shared.saveToken(token, userID: user.uid)
                        promise(.success(authResult))
                    }
                }
            }
        }
        .eraseToAnyPublisher()
    }

    // MARK: - Google Sign In

    func signInWithGoogle(presentingViewController: UIViewController) -> AnyPublisher<AuthResult, Error> {
        Future { promise in
            guard let clientID = FirebaseApp.app()?.options.clientID else {
                promise(.failure(AuthError.missingClientID))
                return
            }

            let config = GIDConfiguration(clientID: clientID)
            GIDSignIn.sharedInstance.configuration = config

            GIDSignIn.sharedInstance.signIn(withPresenting: presentingViewController) { result, error in
                if let error {
                    promise(.failure(error))
                    return
                }
                guard let user = result?.user,
                      let idToken = user.idToken?.tokenString else {
                    promise(.failure(AuthError.noToken))
                    return
                }

                let credential = GoogleAuthProvider.credential(
                    withIDToken: idToken,
                    accessToken: user.accessToken.tokenString
                )

                Auth.auth().signIn(with: credential) { authResult, error in
                    if let error {
                        promise(.failure(error))
                        return
                    }
                    guard let firebaseUser = authResult?.user else {
                        promise(.failure(AuthError.noUser))
                        return
                    }
                    firebaseUser.getIDToken { token, error in
                        if let error {
                            promise(.failure(error))
                            return
                        }
                        guard let token else {
                            promise(.failure(AuthError.noToken))
                            return
                        }
                        let authResult = AuthResult(
                            userID: firebaseUser.uid,
                            email: firebaseUser.email,
                            displayName: firebaseUser.displayName,
                            token: token
                        )
                        AuthTokenManager.shared.saveToken(token, userID: firebaseUser.uid)
                        promise(.success(authResult))
                    }
                }
            }
        }
        .eraseToAnyPublisher()
    }

    // MARK: - Password Reset

    func sendPasswordReset(email: String) -> AnyPublisher<Void, Error> {
        Future { promise in
            Auth.auth().sendPasswordReset(withEmail: email) { error in
                if let error {
                    promise(.failure(error))
                } else {
                    promise(.success(()))
                }
            }
        }
        .eraseToAnyPublisher()
    }

    // MARK: - Sign Out

    func signOut() throws {
        try Auth.auth().signOut()
        AuthTokenManager.shared.clearToken()
    }

    // MARK: - Refresh Token

    func refreshToken() -> AnyPublisher<String, Error> {
        Future { promise in
            guard let user = Auth.auth().currentUser else {
                promise(.failure(AuthError.noUser))
                return
            }
            user.getIDTokenResult(forcingRefresh: true) { (result, error) in
                if let error {
                    promise(.failure(error))
                    return
                }
                guard let result else {
                    promise(.failure(AuthError.noToken))
                    return
                }
                AuthTokenManager.shared.saveToken(result.token, userID: user.uid)
                promise(.success(result.token))
            }
        }
        .eraseToAnyPublisher()
    }
}

// MARK: - Auth Error

enum AuthError: LocalizedError {
    case noUser
    case noToken
    case missingClientID
    case passwordMismatch

    var errorDescription: String? {
        switch self {
        case .noUser:           return "No authenticated user found."
        case .noToken:          return "Failed to retrieve authentication token."
        case .missingClientID:  return "Google Sign-In client ID is missing."
        case .passwordMismatch: return "Passwords do not match."
        }
    }
}
