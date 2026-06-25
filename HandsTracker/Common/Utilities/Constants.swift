//
//  Constants.swift
//  HandsTracker
//
//  Created by Nguyễn Mai Quân on 23/6/26.
//

import Foundation

enum Constants {
    enum API {
        static let baseURL = "https://api.placeholder.com" // TODO: Replace with real base URL
        static let timeoutInterval: TimeInterval = 30
    }

    enum Storage {
        static let videosFolderName = "CapturedVideos"
    }

    enum Auth {
        static let tokenKey = "hands_tracker_auth_token"
        static let userIDKey = "hands_tracker_user_id"
    }
}
