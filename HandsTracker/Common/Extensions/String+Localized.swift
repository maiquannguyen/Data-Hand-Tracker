//
//  String+Localized.swift
//  HandsTracker
//
//  Created by Nguyễn Mai Quân on 23/6/26.
//

import Foundation

extension String {
    /// Returns the localized string for this key using Localizable.strings
    var localized: String {
        NSLocalizedString(self, bundle: .main, comment: "")
    }

    /// Returns the localized string formatted with the given arguments
    /// Usage: "error.server".localized(with: 404)
    func localized(with arguments: CVarArg...) -> String {
        String(format: localized, arguments: arguments)
    }
}
