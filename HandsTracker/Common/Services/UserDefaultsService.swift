//
//  UserDefaultsService.swift
//  HandsTracker
//
//  Created by Nguyễn Mai Quân on 23/6/26.
//

import Foundation

final class UserDefaultsService {
    static let shared = UserDefaultsService()
    private init() {}

    private let defaults = UserDefaults.standard

    private enum Keys {
        static let termsAccepted = "hands_tracker_terms_accepted"
    }

    var hasAcceptedTerms: Bool {
        get { defaults.bool(forKey: Keys.termsAccepted) }
        set { defaults.set(newValue, forKey: Keys.termsAccepted) }
    }
}
