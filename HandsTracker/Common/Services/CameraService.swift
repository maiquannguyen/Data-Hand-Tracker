//
//  CameraService.swift
//  HandsTracker
//
//  Created by Nguyễn Mai Quân on 23/6/26.
//

import Foundation
import AVFoundation
import Combine

final class CameraService: NSObject {

    // MARK: - Published
    let sampleBufferSubject = PassthroughSubject<CMSampleBuffer, Never>()

    // MARK: - Session
    let session = AVCaptureSession()
    private var videoOutput: AVCaptureVideoDataOutput?
    private var movieOutput: AVCaptureMovieFileOutput?
    private let sessionQueue = DispatchQueue(label: "com.handstracker.camera.session")
    private var currentDevice: AVCaptureDevice?

    // MARK: - State
    private(set) var isRecording = false
    var recordingURL: URL?
    var recordingCompletionHandler: ((URL?) -> Void)?

    // MARK: - Setup
    func requestPermissionAndSetup(completion: @escaping (Bool) -> Void) {
        AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
            guard granted else {
                DispatchQueue.main.async { completion(false) }
                return
            }
            self?.sessionQueue.async {
                self?.setupSession()
                DispatchQueue.main.async { completion(true) }
            }
        }
    }

    private func setupSession() {
        session.beginConfiguration()
        session.sessionPreset = .high

        let discoverySession = AVCaptureDevice.DiscoverySession(
            deviceTypes: [.builtInUltraWideCamera, .builtInWideAngleCamera],
            mediaType: .video,
            position: .back
        )
        guard let camera = discoverySession.devices.first else {
            session.commitConfiguration()
            return
        }
        currentDevice = camera

        do {
            let input = try AVCaptureDeviceInput(device: camera)
            if session.canAddInput(input) { session.addInput(input) }
        } catch {
            session.commitConfiguration()
            return
        }

        let videoDataOutput = AVCaptureVideoDataOutput()
        videoDataOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "com.handstracker.camera.buffer"))
        videoDataOutput.alwaysDiscardsLateVideoFrames = true
        if session.canAddOutput(videoDataOutput) { session.addOutput(videoDataOutput) }
        self.videoOutput = videoDataOutput

        let movieOutput = AVCaptureMovieFileOutput()
        if session.canAddOutput(movieOutput) { session.addOutput(movieOutput) }
        self.movieOutput = movieOutput

        session.commitConfiguration()
    }

    // MARK: - Session Control
    func startSession() {
        sessionQueue.async { [weak self] in
            guard let self, !self.session.isRunning else { return }
            self.session.startRunning()
        }
    }

    func stopSession() {
        sessionQueue.async { [weak self] in
            guard let self, self.session.isRunning else { return }
            self.session.stopRunning()
        }
    }

    // MARK: - Recording
    func startRecording() {
        guard let movieOutput, !movieOutput.isRecording else { return }
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("mov")
        recordingURL = url
        movieOutput.startRecording(to: url, recordingDelegate: self)
        isRecording = true
    }

    func stopRecording(completion: @escaping (URL?) -> Void) {
        guard let movieOutput, movieOutput.isRecording else {
            completion(nil)
            return
        }
        recordingCompletionHandler = completion
        movieOutput.stopRecording()
        isRecording = false
    }

    func pauseRecording() {
        movieOutput?.stopRecording()
    }

    func resumeRecording() {
        startRecording()
    }
}

// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate
extension CameraService: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        sampleBufferSubject.send(sampleBuffer)
    }
}

// MARK: - AVCaptureFileOutputRecordingDelegate
extension CameraService: AVCaptureFileOutputRecordingDelegate {
    func fileOutput(
        _ output: AVCaptureFileOutput,
        didFinishRecordingTo outputFileURL: URL,
        from connections: [AVCaptureConnection],
        error: Error?
    ) {
        DispatchQueue.main.async { [weak self] in
            self?.recordingCompletionHandler?(error == nil ? outputFileURL : nil)
            self?.recordingCompletionHandler = nil
        }
    }
}
