//
//  SharedAuthViews.swift
//  HandsTracker
//
//  Created by Nguyễn Mai Quân on 23/6/26.
//

import UIKit
import SnapKit

// MARK: - PrimaryButton

final class PrimaryButton: UIButton {

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }

    private func setupUI() {
        backgroundColor = AppColors.primary
        setTitleColor(.white, for: .normal)
        setTitleColor(UIColor.white.withAlphaComponent(0.5), for: .disabled)
        titleLabel?.font = AppFonts.headline(16)
        layer.cornerRadius = 14
        clipsToBounds = true
    }

    override var isHighlighted: Bool {
        didSet {
            UIView.animate(withDuration: 0.1) {
                self.alpha = self.isHighlighted ? 0.8 : 1.0
                self.transform = self.isHighlighted
                    ? CGAffineTransform(scaleX: 0.98, y: 0.98)
                    : .identity
            }
        }
    }
}

// MARK: - SocialSignInButton

final class SocialSignInButton: UIButton {

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }

    private func setupUI() {
        backgroundColor = AppColors.cardBackground
        setTitleColor(AppColors.textPrimary, for: .normal)
        titleLabel?.font = AppFonts.headline(15)
        layer.cornerRadius = 14
        layer.borderWidth = 1.5
        layer.borderColor = AppColors.accent.cgColor
        tintColor = AppColors.textPrimary

        // Icon left, title centered
        var config = UIButton.Configuration.plain()
        config.imagePlacement = .leading
        config.imagePadding = 10
        config.baseForegroundColor = AppColors.textPrimary
        configuration = config
    }

    override var isHighlighted: Bool {
        didSet {
            UIView.animate(withDuration: 0.1) {
                self.alpha = self.isHighlighted ? 0.7 : 1.0
            }
        }
    }
}

// MARK: - OrSeparatorView

final class OrSeparatorView: UIView {

    private let leftLine: UIView = {
        let v = UIView()
        v.backgroundColor = AppColors.accent
        return v
    }()

    private let orLabel: UILabel = {
        let lbl = UILabel()
        lbl.text = "or"
        lbl.font = AppFonts.caption(13)
        lbl.textColor = AppColors.textSecondary
        lbl.textAlignment = .center
        return lbl
    }()

    private let rightLine: UIView = {
        let v = UIView()
        v.backgroundColor = AppColors.accent
        return v
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }

    private func setupUI() {
        addSubview(leftLine)
        addSubview(orLabel)
        addSubview(rightLine)

        orLabel.snp.makeConstraints {
            $0.center.equalToSuperview()
            $0.width.equalTo(36)
        }

        leftLine.snp.makeConstraints {
            $0.leading.equalToSuperview()
            $0.trailing.equalTo(orLabel.snp.leading).offset(-8)
            $0.centerY.equalToSuperview()
            $0.height.equalTo(1)
        }

        rightLine.snp.makeConstraints {
            $0.trailing.equalToSuperview()
            $0.leading.equalTo(orLabel.snp.trailing).offset(8)
            $0.centerY.equalToSuperview()
            $0.height.equalTo(1)
        }
    }
}

// MARK: - LoadingOverlayView

final class LoadingOverlayView: UIView {

    private let blurView: UIVisualEffectView = {
        let effect = UIBlurEffect(style: .systemUltraThinMaterial)
        let v = UIVisualEffectView(effect: effect)
        return v
    }()

    private let activityIndicator: UIActivityIndicatorView = {
        let ai = UIActivityIndicatorView(style: .large)
        ai.color = AppColors.primary
        ai.startAnimating()
        return ai
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }

    private func setupUI() {
        isHidden = true
        addSubview(blurView)
        addSubview(activityIndicator)

        blurView.snp.makeConstraints { $0.edges.equalToSuperview() }
        activityIndicator.snp.makeConstraints { $0.center.equalToSuperview() }
    }
}
