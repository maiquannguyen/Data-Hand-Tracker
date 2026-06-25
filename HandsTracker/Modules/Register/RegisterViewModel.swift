//
//  RegisterViewModel.swift
//  HandsTracker
//
//  Created by Nguyễn Mai Quân on 23/6/26.
//

import Foundation
import Combine

final class RegisterViewModel {

    // MARK: - Input
    @Published var fullName: String = ""
    @Published var email: String = ""
    @Published var password: String = ""
    @Published var confirmPassword: String = ""
    @Published var hasAcceptedTerms: Bool = false

    // MARK: - Output
    @Published private(set) var isLoading: Bool = false
    @Published private(set) var errorMessage: String?
    @Published private(set) var registerSuccess: Bool = false
    @Published private(set) var isRegisterEnabled: Bool = false

    // MARK: - Services
    private let authService: FirebaseAuthServiceProtocol
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Init
    init(authService: FirebaseAuthServiceProtocol = FirebaseAuthService.shared) {
        self.authService = authService
        bindValidation()
    }

    // MARK: - Validation
    private func bindValidation() {
        Publishers.CombineLatest4($fullName, $email, $password, $confirmPassword)
            .combineLatest($hasAcceptedTerms)
            .map { fields, termsAccepted -> Bool in
                let (name, email, password, confirm) = fields
                return !name.trimmingCharacters(in: .whitespaces).isEmpty &&
                    email.contains("@") &&
                    password.count >= 6 &&
                    password == confirm &&
                    termsAccepted
            }
            .assign(to: &$isRegisterEnabled)
    }

    // MARK: - Register
    func register() {
        guard isRegisterEnabled else { return }

        guard password == confirmPassword else {
            errorMessage = AuthError.passwordMismatch.localizedDescription
            return
        }

        isLoading = true
        errorMessage = nil

        authService.register(email: email, password: password, displayName: fullName)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                self?.isLoading = false
                if case .failure(let error) = completion {
                    self?.errorMessage = error.localizedDescription
                }
            } receiveValue: { [weak self] _ in
                self?.registerSuccess = true
            }
            .store(in: &cancellables)
    }

    func clearError() {
        errorMessage = nil
    }
}
