//
//  VideoCaptureViewController.swift
//  HandsTracker
//
//  Created by Nguyễn Mai Quân on 23/6/26.
//

import UIKit
import AVFoundation
import Combine
import SnapKit

final class VideoCaptureViewController: UIViewController {

    // MARK: - UI

    private let previewView: UIView = {
        let v = UIView()
        v.backgroundColor = .black
        return v
    }()

    private let leftHandLabel: PillLabel = {
        let lbl = PillLabel()
        lbl.setText("Left Hand", isDetected: false)
        return lbl
    }()

    private let rightHandLabel: PillLabel = {
        let lbl = PillLabel()
        lbl.setText("Right Hand", isDetected: false)
        return lbl
    }()

    private let countdownLabel: UILabel = {
        let lbl = UILabel()
        lbl.font = AppFonts.mono(96)
        lbl.textColor = .white
        lbl.textAlignment = .center
        lbl.alpha = 0
        return lbl
    }()

    private let statusBadge: StatusBadgeView = {
        let v = StatusBadgeView()
        return v
    }()

    private let waitingLabel: UILabel = {
        let lbl = UILabel()
        lbl.text = "Show both hands to begin"
        lbl.font = AppFonts.body(16)
        lbl.textColor = UIColor.white.withAlphaComponent(0.85)
        lbl.textAlignment = .center
        lbl.numberOfLines = 2
        return lbl
    }()

    /// Stop button — anchored to bottom-center in portrait,
    /// bottom-trailing in landscape so it never overlaps the hands.
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
        return UIButton(configuration: config)
    }()

    /// Orientation toggle button — lets user lock/unlock rotation.
    private let orientationButton: UIButton = {
        var config = UIButton.Configuration.filled()
        config.image = UIImage(systemName: "rotate.right")
        config.baseBackgroundColor = UIColor.black.withAlphaComponent(0.55)
        config.baseForegroundColor = .white
        config.cornerStyle = .capsule
        config.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 10)
        return UIButton(configuration: config)
    }()

    // MARK: - Layout constraints that change on rotation

    private var portraitConstraints  = [Constraint]()
    private var landscapeConstraints = [Constraint]()
    private var stopButtonConstraint: Constraint?

    // MARK: - Preview layer

    private var previewLayer: AVCaptureVideoPreviewLayer?

    // MARK: - ViewModel

    private let viewModel = VideoCaptureViewModel()
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupConstraints()
        bindViewModel()
        setupActions()
        setupPreviewLayer()
        startCamera()
        observeOrientation()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        viewModel.stopSession()
        NotificationCenter.default.removeObserver(self, name: UIDevice.orientationDidChangeNotification, object: nil)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = previewView.bounds

        // Sync preview layer connection orientation
        if let connection = previewLayer?.connection, connection.isVideoRotationAngleSupported(0) {
            updatePreviewOrientation(connection: connection)
        }
    }

    // MARK: - Orientation Support

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return [.portrait, .landscapeLeft, .landscapeRight]
    }

    override var prefersStatusBarHidden: Bool { true }

    private func observeOrientation() {
        UIDevice.current.beginGeneratingDeviceOrientationNotifications()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(deviceOrientationDidChange),
            name: UIDevice.orientationDidChangeNotification,
            object: nil
        )
    }

    @objc private func deviceOrientationDidChange() {
        let orientation = UIDevice.current.orientation
        guard orientation.isValidInterfaceOrientation else { return }

        // Inform HandDetectionService so it can pass correct orientation to MPImage
        viewModel.updateOrientation(orientation)

        // Update button layout
//        updateLayoutForOrientation(orientation)
    }

    private func updateLayoutForOrientation(_ orientation: UIDeviceOrientation) {
        // Re-apply stop button position
        stopButton.snp.updateConstraints { make in
            if orientation.isLandscape {
                make.trailing.equalTo(view.safeAreaLayoutGuide).inset(24)
                make.bottom.equalTo(view.safeAreaLayoutGuide).inset(24)
                make.centerX.equalToSuperview().priority(.low)
            } else {
                make.centerX.equalToSuperview()
                make.bottom.equalTo(view.safeAreaLayoutGuide).inset(30)
                make.trailing.equalToSuperview().priority(.low)
            }
        }
        UIView.animate(withDuration: 0.25) { self.view.layoutIfNeeded() }
    }

    private func updatePreviewOrientation(connection: AVCaptureConnection) {
        let orientation = UIDevice.current.orientation
        if #available(iOS 17.0, *) {
            let angle: CGFloat
            switch orientation {
            case .landscapeLeft:        angle = 0
            case .landscapeRight:       angle = 180
            case .portraitUpsideDown:   angle = 270
            default:                    angle = 90   // portrait
            }
            if connection.isVideoRotationAngleSupported(angle) {
                connection.videoRotationAngle = angle
            }
        } else {
            // Fallback on earlier versions
            if let videoOrientation = videoOrientation(for: orientation),
               connection.isVideoOrientationSupported {
                connection.videoOrientation = videoOrientation
            }
        }
    }
    
    private func videoOrientation(for deviceOrientation: UIDeviceOrientation) -> AVCaptureVideoOrientation? {
        switch deviceOrientation {
        case .portrait:
            return .portrait
        case .portraitUpsideDown:
            return .portraitUpsideDown
        case .landscapeLeft:
            // Device left = camera right
            return .landscapeRight
        case .landscapeRight:
            return .landscapeLeft
        default:
            return nil
        }
    }

    // MARK: - Setup UI

    private func setupUI() {
        view.backgroundColor = .black
        [previewView, leftHandLabel, rightHandLabel,
         countdownLabel, statusBadge, waitingLabel,
         stopButton, orientationButton].forEach { view.addSubview($0) }
    }

    private func setupConstraints() {
        previewView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }

        leftHandLabel.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide).offset(20)
            $0.leading.equalTo(view.safeAreaLayoutGuide).offset(20)
        }

        rightHandLabel.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide).offset(20)
            $0.trailing.equalTo(view.safeAreaLayoutGuide).inset(20)
        }

        statusBadge.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide).offset(20)
            $0.centerX.equalToSuperview()
        }

        countdownLabel.snp.makeConstraints {
            $0.center.equalToSuperview()
        }

        waitingLabel.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.centerY.equalToSuperview().offset(70)
            $0.leading.trailing.equalToSuperview().inset(40)
        }

        // Stop button — portrait default (center bottom)
        stopButton.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.bottom.equalTo(view.safeAreaLayoutGuide).inset(30)
        }

        orientationButton.snp.makeConstraints {
            $0.bottom.equalTo(view.safeAreaLayoutGuide).inset(30)
            $0.leading.equalTo(view.safeAreaLayoutGuide).offset(24)
            $0.size.equalTo(CGSize(width: 44, height: 44))
        }
    }

    // MARK: - Preview Layer

    private func setupPreviewLayer() {
        let layer = AVCaptureVideoPreviewLayer(session: viewModel.cameraService.session)
        layer.videoGravity = .resizeAspectFill
        previewView.layer.insertSublayer(layer, at: 0)
        previewLayer = layer
    }

    // MARK: - Binding

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
            UIView.animate(withDuration: 0.3) { self.countdownLabel.alpha = 0 }
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

    // MARK: - Actions

    private func setupActions() {
        stopButton.addTarget(self, action: #selector(stopTapped), for: .touchUpInside)
        orientationButton.addTarget(self, action: #selector(orientationTapped), for: .touchUpInside)
    }

    @objc private func stopTapped() {
        viewModel.stopCapture { [weak self] videoItem in
            DispatchQueue.main.async {
                self?.dismiss(animated: true) {
                    // TODO: Pass videoItem to ListVideosViewModel to trigger upload prompt if needed
                    if let videoItem {
                        print("[Capture] Video saved: \(videoItem.fileName)")
                    }
                }
            }
        }
    }

    @objc private func orientationTapped() {
        // TODO: Implement orientation lock toggle if needed
        // For now, rotation follows device naturally via supportedInterfaceOrientations
    }

    // MARK: - Camera

    private func startCamera() {
        viewModel.requestPermissionAndStart { [weak self] granted in
            if !granted { self?.showPermissionDeniedAlert() }
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
