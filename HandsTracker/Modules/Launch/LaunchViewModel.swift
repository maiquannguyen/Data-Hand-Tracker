//
//  LaunchViewModel.swift
//  HandsTracker
//
//  Created by Nguyễn Mai Quân on 23/6/26.
//

import Foundation
import Combine

final class LaunchViewModel {

    enum Destination {
        case terms
        case login
        case home
    }

    @Published private(set) var destination: Destination?

    private let userDefaults: UserDefaultsService
    private let tokenManager: AuthTokenManager

    init(
        userDefaults: UserDefaultsService = .shared,
        tokenManager: AuthTokenManager = .shared
    ) {
        self.userDefaults = userDefaults
        self.tokenManager = tokenManager
    }

    func animationDidFinish() {
        if userDefaults.hasAcceptedTerms {
            // Terms accepted — check auth state
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
                guard let self else { return }
                self.destination = self.tokenManager.isAuthenticated ? .home : .login
            }
        } else {
            // First launch — show terms after 5s
            DispatchQueue.main.asyncAfter(deadline: .now() + 5) { [weak self] in
                self?.destination = .terms
            }
        }
    }
}
