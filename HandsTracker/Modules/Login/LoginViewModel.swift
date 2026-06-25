//
//  LoginViewModel.swift
//  HandsTracker
//
//  Created by Nguyễn Mai Quân on 23/6/26.
//

import Foundation
import Combine
import UIKit

final class LoginViewModel {

    // MARK: - Input
    @Published var email: String = ""
    @Published var password: String = ""

    // MARK: - Output
    @Published private(set) var isLoading: Bool = false
    @Published private(set) var errorMessage: String?
    @Published private(set) var loginSuccess: Bool = false
    @Published private(set) var isLoginEnabled: Bool = false

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
        Publishers.CombineLatest($email, $password)
            .map { email, password in
                !email.trimmingCharacters(in: .whitespaces).isEmpty &&
                !password.isEmpty &&
                email.contains("@")
            }
            .assign(to: &$isLoginEnabled)
    }

    // MARK: - Login with Email
    func loginWithEmail() {
        guard isLoginEnabled else { return }
        isLoading = true
        errorMessage = nil

        authService.login(email: email, password: password)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                self?.isLoading = false
                if case .failure(let error) = completion {
                    self?.errorMessage = error.localizedDescription
                }
            } receiveValue: { [weak self] _ in
                self?.loginSuccess = true
            }
            .store(in: &cancellables)
    }

    // MARK: - Google Sign In
    func loginWithGoogle(from viewController: UIViewController) {
        isLoading = true
        errorMessage = nil

        authService.signInWithGoogle(presentingViewController: viewController)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                self?.isLoading = false
                if case .failure(let error) = completion {
                    self?.errorMessage = error.localizedDescription
                }
            } receiveValue: { [weak self] _ in
                self?.loginSuccess = true
            }
            .store(in: &cancellables)
    }

    // MARK: - Forgot Password
    func forgotPassword() {
        guard !email.isEmpty else {
            errorMessage = "Please enter your email address first."
            return
        }
        isLoading = true

        authService.sendPasswordReset(email: email)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                self?.isLoading = false
                if case .failure(let error) = completion {
                    self?.errorMessage = error.localizedDescription
                }
            } receiveValue: { [weak self] _ in
                self?.errorMessage = "Password reset email sent. Please check your inbox."
            }
            .store(in: &cancellables)
    }

    func clearError() {
        errorMessage = nil
    }
}
