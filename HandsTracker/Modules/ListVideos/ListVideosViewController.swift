//
//  ListVideosViewController.swift
//  HandsTracker
//
//  Created by Nguyễn Mai Quân on 23/6/26.
//

import UIKit
import SnapKit
import Combine

final class ListVideosViewController: UIViewController {

    // MARK: - UI
    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.minimumInteritemSpacing = 12
        layout.minimumLineSpacing = 12
        layout.sectionInset = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.backgroundColor = AppColors.background
        cv.register(VideoThumbnailCell.self, forCellWithReuseIdentifier: VideoThumbnailCell.reuseIdentifier)
        cv.delegate = self
        cv.dataSource = self
        cv.alwaysBounceVertical = true
        return cv
    }()

    private let emptyStateView: UIView = {
        let v = UIView()
        v.isHidden = true
        return v
    }()

    private let emptyIconView: UIImageView = {
        let iv = UIImageView(image: UIImage(systemName: "video.slash"))
        iv.tintColor = AppColors.accent
        iv.contentMode = .scaleAspectFit
        return iv
    }()

    private let emptyTitleLabel: UILabel = {
        let lbl = UILabel()
        lbl.text = "videos.empty.title".localized
        lbl.font = AppFonts.headline(20)
        lbl.textColor = AppColors.textPrimary
        lbl.textAlignment = .center
        return lbl
    }()

    private let emptySubtitleLabel: UILabel = {
        let lbl = UILabel()
        lbl.text = "videos.empty.subtitle".localized
        lbl.font = AppFonts.body(15)
        lbl.textColor = AppColors.textSecondary
        lbl.textAlignment = .center
        lbl.numberOfLines = 2
        return lbl
    }()

    private lazy var uploadAllButton: UIBarButtonItem = {
        UIBarButtonItem(
            title: "videos.upload.all".localized,
            style: .plain,
            target: self,
            action: #selector(uploadAllTapped)
        )
    }()

    private let loadingOverlay = LoadingOverlayView()

    // MARK: - ViewModel
    private let viewModel = ListVideosViewModel()
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "List Videos"
        view.backgroundColor = AppColors.background
        setupUI()
        setupConstraints()
        bindViewModel()
        viewModel.loadVideos()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Refresh list each time we return (e.g. after a new capture)
        viewModel.loadVideos()
    }

    // MARK: - Setup
    private func setupUI() {
        navigationItem.rightBarButtonItem = uploadAllButton

        view.addSubview(collectionView)
        view.addSubview(emptyStateView)
        emptyStateView.addSubview(emptyIconView)
        emptyStateView.addSubview(emptyTitleLabel)
        emptyStateView.addSubview(emptySubtitleLabel)
        view.addSubview(loadingOverlay)
    }

    private func setupConstraints() {
        collectionView.snp.makeConstraints {
            $0.edges.equalTo(view.safeAreaLayoutGuide)
        }

        emptyStateView.snp.makeConstraints {
            $0.center.equalTo(view.safeAreaLayoutGuide)
            $0.leading.trailing.equalToSuperview().inset(40)
        }

        emptyIconView.snp.makeConstraints {
            $0.top.equalToSuperview()
            $0.centerX.equalToSuperview()
            $0.size.equalTo(CGSize(width: 80, height: 80))
        }

        emptyTitleLabel.snp.makeConstraints {
            $0.top.equalTo(emptyIconView.snp.bottom).offset(16)
            $0.leading.trailing.equalToSuperview()
        }

        emptySubtitleLabel.snp.makeConstraints {
            $0.top.equalTo(emptyTitleLabel.snp.bottom).offset(8)
            $0.leading.trailing.equalToSuperview()
            $0.bottom.equalToSuperview()
        }

        loadingOverlay.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
    }

    // MARK: - Binding
    private func bindViewModel() {
        viewModel.$videos
            .receive(on: DispatchQueue.main)
            .sink { [weak self] videos in
                self?.collectionView.reloadData()
                self?.emptyStateView.isHidden = !videos.isEmpty
                self?.collectionView.isHidden = videos.isEmpty
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
    }

    // MARK: - Actions
    @objc private func uploadAllTapped() {
        viewModel.uploadAllPending()
    }

    private func showAlert(message: String) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    private func showVideoOptions(for item: VideoItem, at indexPath: IndexPath) {
        let sheet = UIAlertController(title: item.fileName, message: nil, preferredStyle: .actionSheet)

        sheet.addAction(UIAlertAction(title: "videos.upload.button".localized, style: .default) { [weak self] _ in
            self?.viewModel.uploadVideo(item)
        })

        sheet.addAction(UIAlertAction(title: "Delete", style: .destructive) { [weak self] _ in
            self?.viewModel.deleteVideo(item)
        })

        sheet.addAction(UIAlertAction(title: "Cancel", style: .cancel))

        if let popover = sheet.popoverPresentationController {
            if let cell = collectionView.cellForItem(at: indexPath) {
                popover.sourceView = cell
                popover.sourceRect = cell.bounds
            }
        }
        present(sheet, animated: true)
    }
}

// MARK: - UICollectionViewDataSource
extension ListVideosViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        viewModel.videos.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: VideoThumbnailCell.reuseIdentifier,
            for: indexPath
        ) as? VideoThumbnailCell else { return UICollectionViewCell() }
        cell.configure(with: viewModel.videos[indexPath.item])
        return cell
    }
}

// MARK: - UICollectionViewDelegate
extension ListVideosViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let item = viewModel.videos[indexPath.item]
        showVideoOptions(for: item, at: indexPath)
    }
}

// MARK: - UICollectionViewDelegateFlowLayout
extension ListVideosViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        let padding: CGFloat = 16 * 2 + 12
        let width = (collectionView.bounds.width - padding) / 2
        return CGSize(width: width, height: width * 1.3)
    }
}
