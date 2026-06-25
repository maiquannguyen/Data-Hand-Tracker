//
//  LaunchViewController.swift
//  HandsTracker
//
//  Created by Nguyễn Mai Quân on 23/6/26.
//

import UIKit
import Lottie
import Combine
import SnapKit

final class LaunchViewController: UIViewController {

    // MARK: - UI
    private let animationView: LottieAnimationView = {
        let av = LottieAnimationView(name: "loading")
        av.contentMode = .scaleAspectFit
        av.loopMode = .playOnce
        return av
    }()

    private let appNameLabel: UILabel = {
        let lbl = UILabel()
        lbl.text = "Hands Tracker"
        lbl.font = AppFonts.title(32)
        lbl.textColor = AppColors.primary
        lbl.textAlignment = .center
        lbl.alpha = 0
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

        animationView.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.centerY.equalToSuperview().offset(-40)
            $0.size.equalTo(CGSize(width: 200, height: 200))
        }

        appNameLabel.snp.makeConstraints {
            $0.top.equalTo(animationView.snp.bottom).offset(20)
            $0.leading.trailing.equalToSuperview().inset(20)
        }
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
        case .login:
            let nav = UINavigationController(rootViewController: LoginViewController())
            UIApplication.shared.setRootViewController(nav, animated: true)
        case .home:
            UIApplication.shared.setRootViewController(HomeTabBarController(), animated: true)
        }
    }
}
