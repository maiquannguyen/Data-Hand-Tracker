//
//  TermsViewController.swift
//  HandsTracker
//
//  Created by Nguyễn Mai Quân on 23/6/26.
//

import UIKit
import PDFKit
import Combine

final class TermsViewController: UIViewController {

    // MARK: - UI
    private let containerView: UIView = {
        let v = UIView()
        v.backgroundColor = AppColors.background
        v.layer.cornerRadius = 20
        v.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        v.clipsToBounds = true
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private let titleLabel: UILabel = {
        let lbl = UILabel()
        lbl.text = "Terms & Conditions"
        lbl.font = AppFonts.headline(22)
        lbl.textColor = AppColors.textPrimary
        lbl.textAlignment = .center
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }()

    private let pdfView: PDFView = {
        let pv = PDFView()
        pv.autoScales = true
        pv.displayMode = .singlePageContinuous
        pv.displayDirection = .vertical
        pv.backgroundColor = AppColors.cardBackground
        pv.translatesAutoresizingMaskIntoConstraints = false
        return pv
    }()

    private let acceptButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("I Accept", for: .normal)
        btn.titleLabel?.font = AppFonts.headline(17)
        btn.backgroundColor = AppColors.primary
        btn.setTitleColor(.white, for: .normal)
        btn.setTitleColor(UIColor.white.withAlphaComponent(0.5), for: .disabled)
        btn.layer.cornerRadius = 14
        btn.isEnabled = false
        btn.alpha = 0.5
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }()

    private let scrollHintLabel: UILabel = {
        let lbl = UILabel()
        lbl.text = "Scroll to the bottom to accept"
        lbl.font = AppFonts.caption(12)
        lbl.textColor = AppColors.textSecondary
        lbl.textAlignment = .center
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }()

    // MARK: - ViewModel
    private let viewModel = TermsViewModel()
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadPDF()
        bindViewModel()
        setupActions()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        attachScrollDelegate()
    }

    // MARK: - Setup
    private func setupUI() {
        view.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        view.addSubview(containerView)
        [titleLabel, pdfView, scrollHintLabel, acceptButton].forEach { containerView.addSubview($0) }

        NSLayoutConstraint.activate([
            containerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            containerView.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.85),

            titleLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 24),
            titleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),

            pdfView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 16),
            pdfView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            pdfView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            pdfView.bottomAnchor.constraint(equalTo: scrollHintLabel.topAnchor, constant: -12),

            scrollHintLabel.bottomAnchor.constraint(equalTo: acceptButton.topAnchor, constant: -8),
            scrollHintLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            scrollHintLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),

            acceptButton.bottomAnchor.constraint(equalTo: containerView.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            acceptButton.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 24),
            acceptButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -24),
            acceptButton.heightAnchor.constraint(equalToConstant: 54)
        ])
    }

    private func attachScrollDelegate() {
        guard let scrollView = pdfView.subviews.compactMap({ $0 as? UIScrollView }).first,
              scrollView.delegate == nil else { return }
        scrollView.delegate = self
    }

    private func loadPDF() {
        guard let pdfURL = Bundle.main.url(forResource: "terms_and_conditions", withExtension: "pdf"),
              let document = PDFDocument(url: pdfURL) else {
            pdfView.document = createPlaceholderPDFDocument()
            return
        }
        pdfView.document = document
    }

    private func createPlaceholderPDFDocument() -> PDFDocument {
        let pdfData = NSMutableData()
        UIGraphicsBeginPDFContextToData(pdfData, CGRect(x: 0, y: 0, width: 612, height: 792), nil)
        UIGraphicsBeginPDFPage()
        let text = """
        Terms and Conditions

        Welcome to Hands Tracker. By using this application, you agree to the following terms and conditions.

        1. Data Collection
        This application may capture video of your hands for analysis purposes. All data is stored locally on your device.

        2. Privacy
        We respect your privacy. No personal data is transmitted without your consent.

        3. Usage
        This app is intended for personal use only. Redistribution is prohibited.

        4. Disclaimer
        This application is provided "as is" without warranty of any kind.

        5. Changes
        We reserve the right to update these terms at any time.

        Please read and accept these terms to continue using the application.
        """
        let attrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 14),
            .foregroundColor: UIColor.black
        ]
        text.draw(in: CGRect(x: 40, y: 40, width: 532, height: 712), withAttributes: attrs)
        UIGraphicsEndPDFContext()
        return PDFDocument(data: pdfData as Data) ?? PDFDocument()
    }

    private func bindViewModel() {
        viewModel.$isAcceptEnabled
            .receive(on: DispatchQueue.main)
            .sink { [weak self] enabled in
                self?.acceptButton.isEnabled = enabled
                UIView.animate(withDuration: 0.3) {
                    self?.acceptButton.alpha = enabled ? 1.0 : 0.5
                    self?.scrollHintLabel.alpha = enabled ? 0.0 : 1.0
                }
            }
            .store(in: &cancellables)

        viewModel.$didAccept
            .filter { $0 }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.navigateToHome()
            }
            .store(in: &cancellables)
    }

    private func setupActions() {
        acceptButton.addTarget(self, action: #selector(acceptTapped), for: .touchUpInside)
    }

    // MARK: - Actions
    @objc private func acceptTapped() {
        viewModel.acceptTerms()
    }

    // MARK: - Navigation
    private func navigateToHome() {
        let homeVC = HomeTabBarController()
        UIApplication.shared.setRootViewController(homeVC, animated: true)
    }
}

// MARK: - UIScrollViewDelegate
extension TermsViewController: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let bottomOffset = scrollView.contentSize.height - scrollView.bounds.height
        if scrollView.contentOffset.y >= bottomOffset - 20 {
            viewModel.userScrolledToBottom()
        }
    }
}
