//
//  LaunchViewController.swift
//  HandsTracker
//
//  Created by Nguyễn Mai Quân on 23/6/26.
//

import UIKit
import Lottie
import Combine

final class LaunchViewController: UIViewController {

    // MARK: - UI
    private let animationView: LottieAnimationView = {
        let av = LottieAnimationView(name: "loading")
        av.contentMode = .scaleAspectFit
        av.loopMode = .playOnce
        av.translatesAutoresizingMaskIntoConstraints = false
        return av
    }()

    private let appNameLabel: UILabel = {
        let lbl = UILabel()
        lbl.text = "Hands Tracker"
        lbl.font = AppFonts.title(32)
        lbl.textColor = AppColors.primary
        lbl.textAlignment = .center
        lbl.alpha = 0
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }()

    // MARK: - ViewModel
    private let viewModel = LaunchViewModel()
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        bindViewModel()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        playAnimation()
    }

    // MARK: - Setup
    private func setupUI() {
        view.backgroundColor = AppColors.background
        view.addSubview(animationView)
        view.addSubview(appNameLabel)

        NSLayoutConstraint.activate([
            animationView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            animationView.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -40),
            animationView.widthAnchor.constraint(equalToConstant: 200),
            animationView.heightAnchor.constraint(equalToConstant: 200),

            appNameLabel.topAnchor.constraint(equalTo: animationView.bottomAnchor, constant: 20),
            appNameLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            appNameLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20)
        ])
    }

    private func bindViewModel() {
        viewModel.$destination
            .compactMap { $0 }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] destination in
                self?.navigate(to: destination)
            }
            .store(in: &cancellables)
    }

    // MARK: - Animation
    private func playAnimation() {
        animationView.play { [weak self] finished in
            guard finished else { return }
            UIView.animate(withDuration: 0.6) {
                self?.appNameLabel.alpha = 1
            } completion: { _ in
                self?.viewModel.animationDidFinish()
            }
        }
    }

    // MARK: - Navigation
    private func navigate(to destination: LaunchViewModel.Destination) {
        switch destination {
        case .terms:
            let termsVC = TermsViewController()
            termsVC.modalPresentationStyle = .overFullScreen
            termsVC.modalTransitionStyle = .crossDissolve
            present(termsVC, animated: true)
        case .home:
            UIApplication.shared.setRootViewController(HomeTabBarController(), animated: true)
        }
    }
}
