//
//  GoCaptureViewController.swift
//  HandsTracker
//
//  Created by Nguyễn Mai Quân on 23/6/26.
//

import UIKit

final class GoCaptureViewController: UIViewController {

    // MARK: - UI
    private let captureButton: UIButton = {
        var config = UIButton.Configuration.filled()
        config.title = "Capture Action"
        config.image = UIImage(systemName: "hand.raised.fill")
        config.imagePlacement = .top
        config.imagePadding = 12
        config.baseBackgroundColor = AppColors.primary
        config.baseForegroundColor = .white
        config.cornerStyle = .large
        config.contentInsets = NSDirectionalEdgeInsets(top: 24, leading: 32, bottom: 24, trailing: 32)
        let btn = UIButton(configuration: config)
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }()

    private let subtitleLabel: UILabel = {
        let lbl = UILabel()
        lbl.text = "Tap to start tracking your hand movements"
        lbl.font = AppFonts.body(15)
        lbl.textColor = AppColors.textSecondary
        lbl.textAlignment = .center
        lbl.numberOfLines = 2
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }()

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Go Capture"
        view.backgroundColor = AppColors.background
        setupUI()
        setupActions()
    }

    // MARK: - Setup
    private func setupUI() {
        view.addSubview(captureButton)
        view.addSubview(subtitleLabel)

        NSLayoutConstraint.activate([
            captureButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            captureButton.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -20),

            subtitleLabel.topAnchor.constraint(equalTo: captureButton.bottomAnchor, constant: 20),
            subtitleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            subtitleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40)
        ])
    }

    private func setupActions() {
        captureButton.addTarget(self, action: #selector(captureButtonTapped), for: .touchUpInside)
    }

    // MARK: - Actions
    @objc private func captureButtonTapped() {
        let captureVC = VideoCaptureViewController()
        captureVC.modalPresentationStyle = .fullScreen
        present(captureVC, animated: true)
    }
}
