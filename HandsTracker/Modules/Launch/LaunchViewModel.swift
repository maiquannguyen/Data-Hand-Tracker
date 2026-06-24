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
        case home
    }

    @Published private(set) var destination: Destination?

    private let userDefaults: UserDefaultsService

    init(userDefaults: UserDefaultsService = .shared) {
        self.userDefaults = userDefaults
    }

    func animationDidFinish() {
        if userDefaults.hasAcceptedTerms {
            destination = .home
        } else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 5) { [weak self] in
                self?.destination = .terms
            }
        }
    }
}
