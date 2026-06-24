//
//  TermsViewModel.swift
//  HandsTracker
//
//  Created by Nguyễn Mai Quân on 23/6/26.
//

import Foundation
import Combine

final class TermsViewModel {

    // TODO: // change to false in the future
    @Published private(set) var isAcceptEnabled: Bool = true
    @Published private(set) var didAccept: Bool = false

    private let userDefaults: UserDefaultsService

    init(userDefaults: UserDefaultsService = .shared) {
        self.userDefaults = userDefaults
    }

    func userScrolledToBottom() {
        isAcceptEnabled = true
    }

    func acceptTerms() {
        userDefaults.hasAcceptedTerms = true
        didAccept = true
    }
}
