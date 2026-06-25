//
//  VideoCaptureViewController.swift
//  HandsTracker
//
//  Created by Nguyễn Mai Quân on 23/6/26.
//

import UIKit
import AVFoundation
import Combine

final class VideoCaptureViewController: UIViewController {

    // MARK: - UI
    private var previewLayer: AVCaptureVideoPreviewLayer?

    private let previewView: UIView = {
        let v = UIView()
        v.backgroundColor = .black
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private let leftHandLabel: PillLabel = {
        let lbl = PillLabel()
        lbl.setText("Left Hand", isDetected: false)
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }()

    private let rightHandLabel: PillLabel = {
        let lbl = PillLabel()
        lbl.setText("Right Hand", isDetected: false)
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }()

    private let countdownLabel: UILabel = {
        let lbl = UILabel()
        lbl.font = AppFonts.mono(96)
        lbl.textColor = .white
        lbl.textAlignment = .center
        lbl.alpha = 0
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }()

    private let statusBadge: StatusBadgeView = {
        let v = StatusBadgeView()
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private let stopButton: UIButton = {
        var config = UIButton.Configuration.filled()
        config.title = "Stop"
        config.image = UIImage(systemName: "stop.fill")
        config.imagePlacement = .leading
        config.imagePadding = 8
        config.baseBackgroundColor = AppColors.primary
        config.baseForegroundColor = .white
        config.cornerStyle = .capsule
        config.contentInsets = NSDirectionalEdgeInsets(top: 12, leading: 20, bottom: 12, trailing: 20)
        let btn = UIButton(configuration: config)
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }()

    private let waitingLabel: UILabel = {
        let lbl = UILabel()
        lbl.text = "Show both hands to begin"
        lbl.font = AppFonts.body(16)
        lbl.textColor = UIColor.white.withAlphaComponent(0.85)
        lbl.textAlignment = .center
        lbl.numberOfLines = 2
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }()

    // MARK: - ViewModel
    private let viewModel = VideoCaptureViewModel()
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        bindViewModel()
        setupActions()
        setupPreviewLayer()
        startCamera()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        viewModel.stopSession()
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return [.portrait, .landscape]
    }

    override var prefersStatusBarHidden: Bool { true }

    // MARK: - Setup
    private func setupUI() {
        view.backgroundColor = .black
        view.addSubview(previewView)
        view.addSubview(leftHandLabel)
        view.addSubview(rightHandLabel)
        view.addSubview(countdownLabel)
        view.addSubview(statusBadge)
        view.addSubview(stopButton)
        view.addSubview(waitingLabel)

        NSLayoutConstraint.activate([
            previewView.topAnchor.constraint(equalTo: view.topAnchor),
            previewView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            previewView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            previewView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            leftHandLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            leftHandLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),

            rightHandLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            rightHandLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),

            countdownLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            countdownLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor),

            statusBadge.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            statusBadge.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            waitingLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            waitingLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: 60),
            waitingLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            waitingLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40),

            stopButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -30),
            stopButton.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
    }

    private func setupPreviewLayer() {
        let layer = AVCaptureVideoPreviewLayer(session: viewModel.cameraService.session)
        layer.videoGravity = .resizeAspectFill
        previewView.layer.insertSublayer(layer, at: 0)
        previewLayer = layer
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = previewView.bounds
    }

    private func bindViewModel() {
        viewModel.$leftHandDetected
            .receive(on: DispatchQueue.main)
            .sink { [weak self] detected in
                self?.leftHandLabel.setText("Left Hand", isDetected: detected)
            }
            .store(in: &cancellables)

        viewModel.$rightHandDetected
            .receive(on: DispatchQueue.main)
            .sink { [weak self] detected in
                self?.rightHandLabel.setText("Right Hand", isDetected: detected)
            }
            .store(in: &cancellables)

        viewModel.$captureState
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                self?.updateUI(for: state)
            }
            .store(in: &cancellables)
    }

    private func updateUI(for state: CaptureState) {
        switch state {
        case .idle:
            waitingLabel.isHidden = false
            countdownLabel.alpha = 0
            statusBadge.setState(.idle)

        case .waitingForHands:
            waitingLabel.isHidden = false
            waitingLabel.text = "Show both hands to begin"
            countdownLabel.alpha = 0
            statusBadge.setState(.waiting)

        case .countdown(let value):
            waitingLabel.isHidden = true
            countdownLabel.text = "\(value)"
            UIView.animate(withDuration: 0.1, animations: {
                self.countdownLabel.transform = CGAffineTransform(scaleX: 1.3, y: 1.3)
                self.countdownLabel.alpha = 1
            }) { _ in
                UIView.animate(withDuration: 0.3) {
                    self.countdownLabel.transform = .identity
                }
            }
            statusBadge.setState(.countdown)

        case .recording:
            waitingLabel.isHidden = true
            UIView.animate(withDuration: 0.3) {
                self.countdownLabel.alpha = 0
            }
            statusBadge.setState(.recording)

        case .paused:
            waitingLabel.isHidden = false
            waitingLabel.text = "Recording paused — show both hands"
            statusBadge.setState(.paused)

        case .stopped:
            waitingLabel.isHidden = true
            countdownLabel.alpha = 0
            statusBadge.setState(.idle)
        }
    }

    private func setupActions() {
        stopButton.addTarget(self, action: #selector(stopTapped), for: .touchUpInside)
    }

    private func startCamera() {
        viewModel.requestPermissionAndStart { [weak self] granted in
            if !granted {
                self?.showPermissionDeniedAlert()
            }
        }
    }

    // MARK: - Actions
    @objc private func stopTapped() {
        viewModel.stopCapture { [weak self] videoItem in
            DispatchQueue.main.async {
                self?.dismiss(animated: true) {
                    // TODO: Pass videoItem to ListVideosViewModel to trigger upload prompt if needed
                    if let videoItem {
                        print("Video saved: \(videoItem.fileName)")
                    }
                }
            }
        }
    }

    private func showPermissionDeniedAlert() {
        let alert = UIAlertController(
            title: "Camera Access Required",
            message: "Please allow camera access in Settings to capture hand videos.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Open Settings", style: .default) { _ in
            if let url = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(url)
            }
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { [weak self] _ in
            self?.dismiss(animated: true)
        })
        present(alert, animated: true)
    }
}
