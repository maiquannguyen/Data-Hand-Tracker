//
//  PillLabel.swift
//  HandsTracker
//
//  Created by Nguyễn Mai Quân on 23/6/26.
//

import UIKit

final class PillLabel: UIView {

    private let iconView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()

    private let textLabel: UILabel = {
        let lbl = UILabel()
        lbl.font = AppFonts.caption(13)
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
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
        layer.cornerRadius = 14
        clipsToBounds = true
        backgroundColor = UIColor.black.withAlphaComponent(0.55)
        addSubview(iconView)
        addSubview(textLabel)

        NSLayoutConstraint.activate([
            iconView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10),
            iconView.centerYAnchor.constraint(equalTo: centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 14),
            iconView.heightAnchor.constraint(equalToConstant: 14),

            textLabel.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 6),
            textLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10),
            textLabel.topAnchor.constraint(equalTo: topAnchor, constant: 6),
            textLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -6)
        ])
    }

    func setText(_ text: String, isDetected: Bool) {
        textLabel.text = text
        if isDetected {
            iconView.image = UIImage(systemName: "checkmark.circle.fill")
            iconView.tintColor = UIColor(hex: "#4CAF50")
            textLabel.textColor = .white
            backgroundColor = UIColor.black.withAlphaComponent(0.55)
        } else {
            iconView.image = UIImage(systemName: "xmark.circle.fill")
            iconView.tintColor = AppColors.primary
            textLabel.textColor = UIColor.white.withAlphaComponent(0.7)
            backgroundColor = UIColor.black.withAlphaComponent(0.45)
        }
    }
}
