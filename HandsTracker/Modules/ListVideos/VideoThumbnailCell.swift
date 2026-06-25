//
//  VideoThumbnailCell.swift
//  HandsTracker
//
//  Created by Nguyễn Mai Quân on 23/6/26.
//

import UIKit

final class VideoThumbnailCell: UICollectionViewCell {

    static let reuseIdentifier = "VideoThumbnailCell"

    // MARK: - UI
    private let thumbnailImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.backgroundColor = AppColors.cardBackground
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()

    private let placeholderIcon: UIImageView = {
        let iv = UIImageView(image: UIImage(systemName: "video.fill"))
        iv.tintColor = AppColors.textSecondary
        iv.contentMode = .scaleAspectFit
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()

    private let durationLabel: UILabel = {
        let lbl = UILabel()
        lbl.font = AppFonts.caption(11)
        lbl.textColor = .white
        lbl.backgroundColor = UIColor.black.withAlphaComponent(0.55)
        lbl.textAlignment = .center
        lbl.layer.cornerRadius = 4
        lbl.clipsToBounds = true
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }()

    private let statusOverlay: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor.black.withAlphaComponent(0.45)
        v.isHidden = true
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private let statusIconView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()

    private let uploadProgressView: UIProgressView = {
        let pv = UIProgressView(progressViewStyle: .bar)
        pv.progressTintColor = AppColors.primary
        pv.trackTintColor = UIColor.white.withAlphaComponent(0.3)
        pv.isHidden = true
        pv.translatesAutoresizingMaskIntoConstraints = false
        return pv
    }()

    private let fileNameLabel: UILabel = {
        let lbl = UILabel()
        lbl.font = AppFonts.caption(11)
        lbl.textColor = AppColors.textSecondary
        lbl.numberOfLines = 1
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }()

    // MARK: - Init
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        thumbnailImageView.image = nil
        placeholderIcon.isHidden = false
        statusOverlay.isHidden = true
        uploadProgressView.isHidden = true
        uploadProgressView.progress = 0
        durationLabel.text = nil
    }

    // MARK: - Setup
    private func setupUI() {
        contentView.backgroundColor = AppColors.cardBackground
        contentView.layer.cornerRadius = 10
        contentView.clipsToBounds = true

        contentView.addSubview(thumbnailImageView)
        contentView.addSubview(placeholderIcon)
        contentView.addSubview(statusOverlay)
        statusOverlay.addSubview(statusIconView)
        contentView.addSubview(durationLabel)
        contentView.addSubview(uploadProgressView)
        contentView.addSubview(fileNameLabel)

        NSLayoutConstraint.activate([
            thumbnailImageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            thumbnailImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            thumbnailImageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            thumbnailImageView.heightAnchor.constraint(equalTo: contentView.heightAnchor, multiplier: 0.75),

            placeholderIcon.centerXAnchor.constraint(equalTo: thumbnailImageView.centerXAnchor),
            placeholderIcon.centerYAnchor.constraint(equalTo: thumbnailImageView.centerYAnchor),
            placeholderIcon.widthAnchor.constraint(equalToConstant: 32),
            placeholderIcon.heightAnchor.constraint(equalToConstant: 32),

            statusOverlay.topAnchor.constraint(equalTo: thumbnailImageView.topAnchor),
            statusOverlay.leadingAnchor.constraint(equalTo: thumbnailImageView.leadingAnchor),
            statusOverlay.trailingAnchor.constraint(equalTo: thumbnailImageView.trailingAnchor),
            statusOverlay.bottomAnchor.constraint(equalTo: thumbnailImageView.bottomAnchor),

            statusIconView.centerXAnchor.constraint(equalTo: statusOverlay.centerXAnchor),
            statusIconView.centerYAnchor.constraint(equalTo: statusOverlay.centerYAnchor),
            statusIconView.widthAnchor.constraint(equalToConstant: 28),
            statusIconView.heightAnchor.constraint(equalToConstant: 28),

            durationLabel.trailingAnchor.constraint(equalTo: thumbnailImageView.trailingAnchor, constant: -6),
            durationLabel.bottomAnchor.constraint(equalTo: thumbnailImageView.bottomAnchor, constant: -6),
            durationLabel.heightAnchor.constraint(equalToConstant: 18),

            uploadProgressView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            uploadProgressView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            uploadProgressView.bottomAnchor.constraint(equalTo: thumbnailImageView.bottomAnchor),
            uploadProgressView.heightAnchor.constraint(equalToConstant: 3),

            fileNameLabel.topAnchor.constraint(equalTo: thumbnailImageView.bottomAnchor, constant: 6),
            fileNameLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 8),
            fileNameLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8),
        ])
    }

    // MARK: - Configure
    func configure(with item: VideoItem) {
        fileNameLabel.text = item.fileName

        // Load thumbnail
        ThumbnailService.shared.thumbnail(for: item.fileURL) { [weak self] image in
            guard let self else { return }
            self.thumbnailImageView.image = image
            self.placeholderIcon.isHidden = image != nil
        }

        // Upload status
        switch item.uploadStatus {
        case .notUploaded:
            statusOverlay.isHidden = true
            uploadProgressView.isHidden = true

        case .uploading(let progress):
            statusOverlay.isHidden = true
            uploadProgressView.isHidden = false
            uploadProgressView.progress = Float(progress)

        case .uploaded:
            statusOverlay.isHidden = false
            statusIconView.image = UIImage(systemName: "checkmark.circle.fill")
            statusIconView.tintColor = UIColor(hex: "#4CAF50")
            uploadProgressView.isHidden = true

        case .failed:
            statusOverlay.isHidden = false
            statusIconView.image = UIImage(systemName: "exclamationmark.circle.fill")
            statusIconView.tintColor = AppColors.primary
            uploadProgressView.isHidden = true
        }
    }
}
