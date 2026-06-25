//
//  LoginViewController.swift
//  HandsTracker
//
//  Created by Nguyễn Mai Quân on 23/6/26.
//

import UIKit
import SnapKit
import Combine

final class LoginViewController: UIViewController {

    // MARK: - UI

    private let scrollView = UIScrollView()
    private let contentView = UIView()

    private let logoImageView: UIImageView = {
        let iv = UIImageView(image: UIImage(systemName: "hand.raised.fill"))
        iv.tintColor = AppColors.primary
        iv.contentMode = .scaleAspectFit
        return iv
    }()

    private let titleLabel: UILabel = {
        let lbl = UILabel()
        lbl.text = "login.title".localized
        lbl.font = AppFonts.title(28)
        lbl.textColor = AppColors.textPrimary
        lbl.textAlignment = .center
        return lbl
    }()

    private let subtitleLabel: UILabel = {
        let lbl = UILabel()
        lbl.text = "login.subtitle".localized
        lbl.font = AppFonts.body(15)
        lbl.textColor = AppColors.textSecondary
        lbl.textAlignment = .center
        return lbl
    }()

    private let emailField: AuthTextField = {
        let f = AuthTextField()
        f.placeholder = "login.field.email.placeholder".localized
        f.keyboardType = .emailAddress
        f.autocapitalizationType = .none
        f.autocorrectionType = .no
        f.returnKeyType = .next
        return f
    }()

    private let passwordField: AuthTextField = {
        let f = AuthTextField()
        f.placeholder = "login.field.password.placeholder".localized
        f.isSecureTextEntry = true
        f.returnKeyType = .done
        return f
    }()

    private let loginButton: PrimaryButton = {
        let btn = PrimaryButton()
        btn.setTitle("login.button.login".localized, for: .normal)
        btn.isEnabled = false
        return btn
    }()

    private let orSeparatorView = OrSeparatorView()

    private let googleButton: SocialSignInButton = {
        let btn = SocialSignInButton()
        btn.setTitle("login.button.google".localized, for: .normal)
        btn.setImage(UIImage(systemName: "g.circle.fill"), for: .normal)
        return btn
    }()

    private let registerButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("login.button.register".localized, for: .normal)
        btn.titleLabel?.font = AppFonts.headline(15)
        btn.setTitleColor(AppColors.primary, for: .normal)
        btn.layer.borderColor = AppColors.primary.cgColor
        btn.layer.borderWidth = 1.5
        btn.layer.cornerRadius = 14
        return btn
    }()

    private let forgotPasswordButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("login.button.forgot".localized, for: .normal)
        btn.titleLabel?.font = AppFonts.body(14)
        btn.setTitleColor(AppColors.textSecondary, for: .normal)
        return btn
    }()

    private let loadingOverlay = LoadingOverlayView()

    // MARK: - ViewModel
    private let viewModel = LoginViewModel()
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupConstraints()
        bindViewModel()
        setupActions()
        setupKeyboardDismiss()
    }

    // MARK: - Setup UI
    private func setupUI() {
        view.backgroundColor = AppColors.background
        navigationController?.setNavigationBarHidden(true, animated: false)

        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        [logoImageView, titleLabel, subtitleLabel,
         emailField, passwordField,
         loginButton, orSeparatorView, googleButton,
         forgotPasswordButton, registerButton].forEach { contentView.addSubview($0) }

        view.addSubview(loadingOverlay)
    }

    // MARK: - SnapKit Constraints
    private func setupConstraints() {
        scrollView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }

        contentView.snp.makeConstraints {
            $0.edges.equalToSuperview()
            $0.width.equalTo(scrollView)
        }

        logoImageView.snp.makeConstraints {
            $0.top.equalToSuperview().offset(60)
            $0.centerX.equalToSuperview()
            $0.size.equalTo(CGSize(width: 64, height: 64))
        }

        titleLabel.snp.makeConstraints {
            $0.top.equalTo(logoImageView.snp.bottom).offset(16)
            $0.leading.trailing.equalToSuperview().inset(24)
        }

        subtitleLabel.snp.makeConstraints {
            $0.top.equalTo(titleLabel.snp.bottom).offset(8)
            $0.leading.trailing.equalToSuperview().inset(24)
        }

        emailField.snp.makeConstraints {
            $0.top.equalTo(subtitleLabel.snp.bottom).offset(36)
            $0.leading.trailing.equalToSuperview().inset(24)
            $0.height.equalTo(54)
        }

        passwordField.snp.makeConstraints {
            $0.top.equalTo(emailField.snp.bottom).offset(14)
            $0.leading.trailing.equalToSuperview().inset(24)
            $0.height.equalTo(54)
        }

        loginButton.snp.makeConstraints {
            $0.top.equalTo(passwordField.snp.bottom).offset(24)
            $0.leading.trailing.equalToSuperview().inset(24)
            $0.height.equalTo(54)
        }

        orSeparatorView.snp.makeConstraints {
            $0.top.equalTo(loginButton.snp.bottom).offset(20)
            $0.leading.trailing.equalToSuperview().inset(24)
            $0.height.equalTo(20)
        }

        googleButton.snp.makeConstraints {
            $0.top.equalTo(orSeparatorView.snp.bottom).offset(20)
            $0.leading.trailing.equalToSuperview().inset(24)
            $0.height.equalTo(54)
        }

        forgotPasswordButton.snp.makeConstraints {
            $0.top.equalTo(googleButton.snp.bottom).offset(20)
            $0.centerX.equalToSuperview()
            $0.height.equalTo(36)
        }

        registerButton.snp.makeConstraints {
            $0.top.equalTo(forgotPasswordButton.snp.bottom).offset(12)
            $0.leading.trailing.equalToSuperview().inset(24)
            $0.height.equalTo(54)
            $0.bottom.equalToSuperview().offset(-40)
        }

        loadingOverlay.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
    }

    // MARK: - Binding
    private func bindViewModel() {
        // Email → ViewModel
        emailField.textPublisher
            .assign(to: &viewModel.$email)

        // Password → ViewModel
        passwordField.textPublisher
            .assign(to: &viewModel.$password)

        // Enable/disable login button
        viewModel.$isLoginEnabled
            .receive(on: DispatchQueue.main)
            .sink { [weak self] enabled in
                self?.loginButton.isEnabled = enabled
                UIView.animate(withDuration: 0.2) {
                    self?.loginButton.alpha = enabled ? 1 : 0.5
                }
            }
            .store(in: &cancellables)

        // Loading
        viewModel.$isLoading
            .receive(on: DispatchQueue.main)
            .sink { [weak self] loading in
                self?.loadingOverlay.isHidden = !loading
            }
            .store(in: &cancellables)

        // Error
        viewModel.$errorMessage
            .compactMap { $0 }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] message in
                self?.showAlert(message: message)
                self?.viewModel.clearError()
            }
            .store(in: &cancellables)

        // Success
        viewModel.$loginSuccess
            .filter { $0 }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.navigateToHome()
            }
            .store(in: &cancellables)
    }

    // MARK: - Actions
    private func setupActions() {
        loginButton.addTarget(self, action: #selector(loginTapped), for: .touchUpInside)
        googleButton.addTarget(self, action: #selector(googleTapped), for: .touchUpInside)
        registerButton.addTarget(self, action: #selector(registerTapped), for: .touchUpInside)
        forgotPasswordButton.addTarget(self, action: #selector(forgotTapped), for: .touchUpInside)

        emailField.returnHandler = { [weak self] in self?.passwordField.becomeFirstResponder() }
        passwordField.returnHandler = { [weak self] in self?.viewModel.loginWithEmail() }
    }

    @objc private func loginTapped() {
        viewModel.loginWithEmail()
    }

    @objc private func googleTapped() {
        viewModel.loginWithGoogle(from: self)
    }

    @objc private func registerTapped() {
        let registerVC = RegisterViewController()
        navigationController?.pushViewController(registerVC, animated: true)
    }

    @objc private func forgotTapped() {
        viewModel.forgotPassword()
    }

    // MARK: - Navigation
    private func navigateToHome() {
        UIApplication.shared.setRootViewController(HomeTabBarController(), animated: true)
    }

    // MARK: - Helpers
    private func setupKeyboardDismiss() {
        let tap = UITapGestureRecognizer(target: view, action: #selector(UIView.endEditing(_:)))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }

    private func showAlert(message: String) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
