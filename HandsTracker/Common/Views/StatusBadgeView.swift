//
//  StatusBadgeView.swift
//  HandsTracker
//
//  Created by Nguyễn Mai Quân on 23/6/26.
//

import UIKit

enum RecordingStatus {
    case idle, waiting, countdown, recording, paused
}

final class StatusBadgeView: UIView {

    private let dotView: UIView = {
        let v = UIView()
        v.layer.cornerRadius = 5
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private let statusLabel: UILabel = {
        let lbl = UILabel()
        lbl.font = AppFonts.caption(13)
        lbl.textColor = .white
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }()

    private var pulseAnimation: CABasicAnimation = {
        let anim = CABasicAnimation(keyPath: "opacity")
        anim.fromValue = 1.0
        anim.toValue = 0.3
        anim.duration = 0.6
        anim.autoreverses = true
        anim.repeatCount = .infinity
        return anim
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
        backgroundColor = UIColor.black.withAlphaComponent(0.55)
        layer.cornerRadius = 12
        clipsToBounds = true
        addSubview(dotView)
        addSubview(statusLabel)

        NSLayoutConstraint.activate([
            dotView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10),
            dotView.centerYAnchor.constraint(equalTo: centerYAnchor),
            dotView.widthAnchor.constraint(equalToConstant: 10),
            dotView.heightAnchor.constraint(equalToConstant: 10),

            statusLabel.leadingAnchor.constraint(equalTo: dotView.trailingAnchor, constant: 6),
            statusLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10),
            statusLabel.topAnchor.constraint(equalTo: topAnchor, constant: 6),
            statusLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -6)
        ])
    }

    func setState(_ status: RecordingStatus) {
        dotView.layer.removeAllAnimations()
        switch status {
        case .idle:
            isHidden = true
            dotView.backgroundColor = .gray
            statusLabel.text = "Ready"
        case .waiting:
            isHidden = false
            dotView.backgroundColor = UIColor(hex: "#FFD600")
            statusLabel.text = "Waiting for hands..."
            dotView.layer.add(pulseAnimation, forKey: "pulse")
        case .countdown:
            isHidden = false
            dotView.backgroundColor = UIColor(hex: "#FF9800")
            statusLabel.text = "Get ready..."
        case .recording:
            isHidden = false
            dotView.backgroundColor = AppColors.primary
            statusLabel.text = "Recording"
            dotView.layer.add(pulseAnimation, forKey: "pulse")
        case .paused:
            isHidden = false
            dotView.backgroundColor = UIColor(hex: "#FFD600")
            statusLabel.text = "Paused"
        }
    }
}
