//
//  RegisterViewController.swift
//  HandsTracker
//
//  Created by Nguyễn Mai Quân on 23/6/26.
//

import UIKit
import SnapKit
import Combine

final class RegisterViewController: UIViewController {

    // MARK: - UI

    private let scrollView = UIScrollView()
    private let contentView = UIView()

    private let titleLabel: UILabel = {
        let lbl = UILabel()
        lbl.text = "register.title".localized
        lbl.font = AppFonts.title(28)
        lbl.textColor = AppColors.textPrimary
        return lbl
    }()

    private let subtitleLabel: UILabel = {
        let lbl = UILabel()
        lbl.text = "register.subtitle".localized
        lbl.font = AppFonts.body(15)
        lbl.textColor = AppColors.textSecondary
        return lbl
    }()

    private let nameField: AuthTextField = {
        let f = AuthTextField()
        f.placeholder = "register.field.name.placeholder".localized
        f.autocapitalizationType = .words
        f.returnKeyType = .next
        return f
    }()

    private let emailField: AuthTextField = {
        let f = AuthTextField()
        f.placeholder = "register.field.email.placeholder".localized
        f.keyboardType = .emailAddress
        f.autocapitalizationType = .none
        f.autocorrectionType = .no
        f.returnKeyType = .next
        return f
    }()

    private let passwordField: AuthTextField = {
        let f = AuthTextField()
        f.placeholder = "register.field.password.placeholder".localized
        f.isSecureTextEntry = true
        f.returnKeyType = .next
        return f
    }()

    private let confirmPasswordField: AuthTextField = {
        let f = AuthTextField()
        f.placeholder = "register.field.confirm.placeholder".localized
        f.isSecureTextEntry = true
        f.returnKeyType = .done
        return f
    }()

    // Terms checkbox row
    private let termsRowView = UIView()

    private let termsCheckbox: UIButton = {
        let btn = UIButton(type: .custom)
        btn.setImage(UIImage(systemName: "square"), for: .normal)
        btn.setImage(UIImage(systemName: "checkmark.square.fill"), for: .selected)
        btn.tintColor = AppColors.primary
        return btn
    }()

    private let termsLabel: UITextView = {
        let tv = UITextView()
        tv.isScrollEnabled = false
        tv.isEditable = false
        tv.backgroundColor = .clear
        tv.textContainerInset = .zero
        tv.textContainer.lineFragmentPadding = 0

        // Build attributed string with tappable "Terms & Conditions"
        let prefix = "register.terms.prefix".localized
        let link = "register.terms.link".localized
        let full = prefix + link

        let attributedString = NSMutableAttributedString(
            string: full,
            attributes: [
                .font: AppFonts.body(13),
                .foregroundColor: AppColors.textSecondary
            ]
        )
        if let range = full.range(of: link) {
            let nsRange = NSRange(range, in: full)
            attributedString.addAttributes([
                .foregroundColor: AppColors.primary,
                .underlineStyle: NSUnderlineStyle.single.rawValue,
                .link: "terms://open"
            ], range: nsRange)
        }
        tv.attributedText = attributedString
        return tv
    }()

    private let createButton: PrimaryButton = {
        let btn = PrimaryButton()
        btn.setTitle("register.button.create".localized, for: .normal)
        btn.isEnabled = false
        btn.alpha = 0.5
        return btn
    }()

    private let loadingOverlay = LoadingOverlayView()

    // MARK: - ViewModel
    private let viewModel = RegisterViewModel()
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
        title = "register.title".localized

        view.addSubview(scrollView)
        scrollView.addSubview(contentView)

        [titleLabel, subtitleLabel,
         nameField, emailField, passwordField, confirmPasswordField,
         termsRowView, createButton].forEach { contentView.addSubview($0) }

        termsRowView.addSubview(termsCheckbox)
        termsRowView.addSubview(termsLabel)

        view.addSubview(loadingOverlay)

        termsLabel.delegate = self
    }

    // MARK: - SnapKit Constraints
    private func setupConstraints() {
        scrollView.snp.makeConstraints {
            $0.edges.equalTo(view.safeAreaLayoutGuide)
        }

        contentView.snp.makeConstraints {
            $0.edges.equalToSuperview()
            $0.width.equalTo(scrollView)
        }

        titleLabel.snp.makeConstraints {
            $0.top.equalToSuperview().offset(28)
            $0.leading.trailing.equalToSuperview().inset(24)
        }

        subtitleLabel.snp.makeConstraints {
            $0.top.equalTo(titleLabel.snp.bottom).offset(6)
            $0.leading.trailing.equalToSuperview().inset(24)
        }

        nameField.snp.makeConstraints {
            $0.top.equalTo(subtitleLabel.snp.bottom).offset(28)
            $0.leading.trailing.equalToSuperview().inset(24)
            $0.height.equalTo(54)
        }

        emailField.snp.makeConstraints {
            $0.top.equalTo(nameField.snp.bottom).offset(14)
            $0.leading.trailing.equalToSuperview().inset(24)
            $0.height.equalTo(54)
        }

        passwordField.snp.makeConstraints {
            $0.top.equalTo(emailField.snp.bottom).offset(14)
            $0.leading.trailing.equalToSuperview().inset(24)
            $0.height.equalTo(54)
        }

        confirmPasswordField.snp.makeConstraints {
            $0.top.equalTo(passwordField.snp.bottom).offset(14)
            $0.leading.trailing.equalToSuperview().inset(24)
            $0.height.equalTo(54)
        }

        termsRowView.snp.makeConstraints {
            $0.top.equalTo(confirmPasswordField.snp.bottom).offset(20)
            $0.leading.trailing.equalToSuperview().inset(24)
        }

        termsCheckbox.snp.makeConstraints {
            $0.leading.equalToSuperview()
            $0.top.equalToSuperview().offset(2)
            $0.size.equalTo(CGSize(width: 24, height: 24))
        }

        termsLabel.snp.makeConstraints {
            $0.leading.equalTo(termsCheckbox.snp.trailing).offset(8)
            $0.trailing.equalToSuperview()
            $0.top.bottom.equalToSuperview()
        }

        createButton.snp.makeConstraints {
            $0.top.equalTo(termsRowView.snp.bottom).offset(24)
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
        nameField.textPublisher.assign(to: &viewModel.$fullName)
        emailField.textPublisher.assign(to: &viewModel.$email)
        passwordField.textPublisher.assign(to: &viewModel.$password)
        confirmPasswordField.textPublisher.assign(to: &viewModel.$confirmPassword)

        viewModel.$isRegisterEnabled
            .receive(on: DispatchQueue.main)
            .sink { [weak self] enabled in
                self?.createButton.isEnabled = enabled
                UIView.animate(withDuration: 0.2) {
                    self?.createButton.alpha = enabled ? 1 : 0.5
                }
            }
            .store(in: &cancellables)

        viewModel.$isLoading
            .receive(on: DispatchQueue.main)
            .sink { [weak self] loading in
                self?.loadingOverlay.isHidden = !loading
            }
            .store(in: &cancellables)

        viewModel.$errorMessage
            .compactMap { $0 }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] message in
                self?.showAlert(message: message)
                self?.viewModel.clearError()
            }
            .store(in: &cancellables)

        viewModel.$registerSuccess
            .filter { $0 }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.navigateToHome()
            }
            .store(in: &cancellables)
    }

    // MARK: - Actions
    private func setupActions() {
        createButton.addTarget(self, action: #selector(createTapped), for: .touchUpInside)
        termsCheckbox.addTarget(self, action: #selector(checkboxTapped), for: .touchUpInside)

        nameField.returnHandler = { [weak self] in self?.emailField.becomeFirstResponder() }
        emailField.returnHandler = { [weak self] in self?.passwordField.becomeFirstResponder() }
        passwordField.returnHandler = { [weak self] in self?.confirmPasswordField.becomeFirstResponder() }
        confirmPasswordField.returnHandler = { [weak self] in self?.viewModel.register() }
    }

    @objc private func createTapped() {
        viewModel.register()
    }

    @objc private func checkboxTapped() {
        termsCheckbox.isSelected.toggle()
        viewModel.hasAcceptedTerms = termsCheckbox.isSelected
    }

    // MARK: - Navigation
    private func navigateToHome() {
        UIApplication.shared.setRootViewController(HomeTabBarController(), animated: true)
    }

    private func openTerms() {
        let termsVC = TermsViewController()
        termsVC.modalPresentationStyle = .overFullScreen
        termsVC.modalTransitionStyle = .crossDissolve
        present(termsVC, animated: true)
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

// MARK: - UITextViewDelegate (Terms link tap)
extension RegisterViewController: UITextViewDelegate {
    func textView(
        _ textView: UITextView,
        shouldInteractWith URL: URL,
        in characterRange: NSRange,
        interaction: UITextItemInteraction
    ) -> Bool {
        if URL.scheme == "terms" {
            openTerms()
            return false
        }
        return true
    }
}
