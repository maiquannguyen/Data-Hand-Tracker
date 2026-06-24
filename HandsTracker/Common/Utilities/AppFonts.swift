//
//  AppFonts.swift
//  HandsTracker
//
//  Created by Nguyễn Mai Quân on 23/6/26.
//

import UIKit

enum AppFonts {
    static func title(_ size: CGFloat = 28) -> UIFont {
        return UIFont.systemFont(ofSize: size, weight: .bold)
    }
    static func headline(_ size: CGFloat = 20) -> UIFont {
        return UIFont.systemFont(ofSize: size, weight: .semibold)
    }
    static func body(_ size: CGFloat = 16) -> UIFont {
        return UIFont.systemFont(ofSize: size, weight: .regular)
    }
    static func caption(_ size: CGFloat = 12) -> UIFont {
        return UIFont.systemFont(ofSize: size, weight: .medium)
    }
    static func mono(_ size: CGFloat = 48) -> UIFont {
        return UIFont.monospacedDigitSystemFont(ofSize: size, weight: .bold)
    }
}
