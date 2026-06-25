//
//  AuthTextField.swift
//  HandsTracker
//
//  Created by Nguyễn Mai Quân on 23/6/26.
//

import UIKit
import Combine

final class AuthTextField: UITextField {

    // MARK: - Return handler
    var returnHandler: (() -> Void)?

    // MARK: - Combine publisher
    var textPublisher: AnyPublisher<String, Never> {
        NotificationCenter.default
            .publisher(for: UITextField.textDidChangeNotification, object: self)
            .compactMap { ($0.object as? UITextField)?.text }
            .eraseToAnyPublisher()
    }

    // MARK: - Init
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }

    // MARK: - Setup
    private func setupUI() {
        backgroundColor = AppColors.cardBackground
        textColor = AppColors.textPrimary
        font = AppFonts.body(16)
        layer.cornerRadius = 14
        layer.borderWidth = 1
        layer.borderColor = AppColors.accent.cgColor
        leftView = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: 0))
        leftViewMode = .always
        rightView = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: 0))
        rightViewMode = .always
        delegate = self

        // Focused border
        addTarget(self, action: #selector(editingBegan), for: .editingDidBegin)
        addTarget(self, action: #selector(editingEnded), for: .editingDidEnd)
    }

    @objc private func editingBegan() {
        UIView.animate(withDuration: 0.2) {
            self.layer.borderColor = AppColors.primary.cgColor
            self.layer.borderWidth = 1.5
        }
    }

    @objc private func editingEnded() {
        UIView.animate(withDuration: 0.2) {
            self.layer.borderColor = AppColors.accent.cgColor
            self.layer.borderWidth = 1
        }
    }
}

// MARK: - UITextFieldDelegate
extension AuthTextField: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        returnHandler?() ?? { endEditing(true) }()
        return true
    }
}
