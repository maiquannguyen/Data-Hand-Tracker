//
//  VideoCaptureViewModel.swift
//  HandsTracker
//
//  Created by Nguyễn Mai Quân on 23/6/26.
//

import Foundation
import Combine
import AVFoundation
import UIKit

enum CaptureState {
    case idle
    case waitingForHands
    case countdown(Int)
    case recording
    case paused
    case stopped
}

final class VideoCaptureViewModel {

    // MARK: - Published
    @Published private(set) var captureState: CaptureState = .idle
    @Published private(set) var leftHandDetected: Bool = false
    @Published private(set) var rightHandDetected: Bool = false
    @Published private(set) var countdownValue: Int = 5

    // MARK: - Services
    let cameraService = CameraService()
    private let handDetectionService = HandDetectionService()

    private var cancellables = Set<AnyCancellable>()
    private var countdownTimer: AnyCancellable?
    private var countdownCount = 5

    // MARK: - Init
    init() {
        bindHandDetection()
    }

    // MARK: - Orientation forwarding
    /// Called by VideoCaptureViewController on each device orientation change.
    func updateOrientation(_ orientation: UIDeviceOrientation) {
        handDetectionService.currentOrientation = orientation
    }

    // MARK: - Binding
    private func bindHandDetection() {
        cameraService.sampleBufferSubject
            .sink { [weak self] buffer in
                self?.handDetectionService.detect(in: buffer)
            }
            .store(in: &cancellables)

        handDetectionService.detectionSubject
            .receive(on: DispatchQueue.main)
            .sink { [weak self] result in
                self?.handleDetectionResult(result)
            }
            .store(in: &cancellables)
    }

    private func handleDetectionResult(_ result: HandDetectionResult) {
        leftHandDetected  = result.leftHandDetected
        rightHandDetected = result.rightHandDetected

        switch captureState {
        case .idle, .waitingForHands:
            if result.bothHandsDetected {
                startCountdown()
            } else {
                captureState = .waitingForHands
            }
        case .countdown:
            if !result.bothHandsDetected {
                cancelCountdown()
                captureState = .waitingForHands
            }
        case .recording:
            if !result.bothHandsDetected {
                pauseCapture()
            }
        case .paused:
            if result.bothHandsDetected {
                resumeCapture()
            }
        case .stopped:
            break
        }
    }

    // MARK: - Countdown
    private func startCountdown() {
        countdownCount = 5
        countdownValue = countdownCount
        captureState = .countdown(countdownCount)

        countdownTimer = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self else { return }
                self.countdownCount -= 1
                if self.countdownCount <= 0 {
                    self.cancelCountdown()
                    self.startRecording()
                } else {
                    self.countdownValue = self.countdownCount
                    self.captureState = .countdown(self.countdownCount)
                }
            }
    }

    private func cancelCountdown() {
        countdownTimer?.cancel()
        countdownTimer = nil
    }

    // MARK: - Recording
    private func startRecording() {
        cameraService.startRecording()
        captureState = .recording
    }

    private func pauseCapture() {
        guard case .recording = captureState else { return }
        cameraService.pauseRecording()
        captureState = .paused
    }

    private func resumeCapture() {
        guard case .paused = captureState else { return }
        cameraService.resumeRecording()
        captureState = .recording
    }

    func stopCapture(completion: @escaping (VideoItem?) -> Void) {
        cancelCountdown()
        captureState = .stopped
        cameraService.stopRecording { [weak self] tempURL in
            guard let tempURL else {
                completion(nil)
                return
            }
            do {
                let videoItem = try VideoStorageService.shared.saveVideo(from: tempURL)
                completion(videoItem)
            } catch {
                // TODO: Handle storage error — surface to UI if needed
                print("[VideoCaptureViewModel] Failed to save video: \(error)")
                completion(nil)
            }
        }
    }

    // MARK: - Session
    func requestPermissionAndStart(completion: @escaping (Bool) -> Void) {
        cameraService.requestPermissionAndSetup { [weak self] granted in
            guard granted else {
                completion(false)
                return
            }
            self?.cameraService.startSession()
            self?.captureState = .waitingForHands
            completion(true)
        }
    }

    func stopSession() {
        cancelCountdown()
        cameraService.stopSession()
    }
}
