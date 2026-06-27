//
//  HandDetectionService.swift
//  HandsTracker
//
//  Created by Nguyễn Mai Quân on 23/6/26.
//
//  Uses MediaPipe Hand Landmarker via SwiftTasksVision (SPM).
//
//  SETUP REQUIRED:
//  1. Add SwiftTasksVision via Xcode → File → Add Package Dependencies
//     URL: https://github.com/paescebu/SwiftTasksVision
//  2. Download hand_landmarker.task model:
//     https://storage.googleapis.com/mediapipe-models/hand_landmarker/hand_landmarker/float16/1/hand_landmarker.task
//  3. Add hand_landmarker.task to your Xcode target bundle resources.
//

import Foundation
import Combine
import AVFoundation
import MediaPipeTasksVision

// MARK: - Result

struct HandDetectionResult {
    let leftHandDetected: Bool
    let rightHandDetected: Bool
    var bothHandsDetected: Bool { leftHandDetected && rightHandDetected }
}

// MARK: - Service

final class HandDetectionService: NSObject {

    // MARK: - Configuration
    private let minHandDetectionConfidence: Float = 0.4
    private let minHandPresenceConfidence: Float  = 0.4
    private let minTrackingConfidence: Float       = 0.4
    private let missingFrameThreshold = 5

    // MARK: - State
    private var handLandmarker: HandLandmarker?

    // Monotonically increasing — MediaPipe requires each call to have a
    // strictly greater timestamp than the previous one.
    private var frameTimestamp: Int = 0

    private var leftMissCount  = 0
    private var rightMissCount = 0

    var currentOrientation: UIDeviceOrientation = .portrait

    let detectionSubject = PassthroughSubject<HandDetectionResult, Never>()

    // MARK: - Init

    override init() {
        super.init()
        setupLandmarker()
    }

    // MARK: - Setup

    private func setupLandmarker() {
        guard let modelPath = Bundle.main.path(forResource: "hand_landmarker", ofType: "task") else {
            print("[HandDetectionService] ⚠️ hand_landmarker.task not found in bundle.")
            return
        }

        do {
            let options = HandLandmarkerOptions()
            options.baseOptions.modelAssetPath        = modelPath
            options.runningMode                       = .liveStream
            options.numHands                          = 2
            options.minHandDetectionConfidence        = minHandDetectionConfidence
            options.minHandPresenceConfidence         = minHandPresenceConfidence
            options.minTrackingConfidence             = minTrackingConfidence

            // KEY FIX: The delegate must be set BEFORE creating HandLandmarker,
            // and the delegate object must be kept alive (stored as a property).
            // Setting it after init or on a temporary object silently drops results.
            options.handLandmarkerLiveStreamDelegate  = self

            handLandmarker = try HandLandmarker(options: options)
        } catch {
            print("[HandDetectionService] Failed to init HandLandmarker: \(error)")
        }
    }

    // MARK: - Detection

    func detect(in sampleBuffer: CMSampleBuffer) {
        guard let landmarker = handLandmarker else { return }

        do {
            let mpImage = try MPImage(sampleBuffer: sampleBuffer, orientation: mpOrientation())

            // Timestamp must strictly increase each call — use milliseconds
            frameTimestamp += 1

            // detectAsync is non-blocking; results arrive on the delegate below
            try landmarker.detectAsync(image: mpImage, timestampInMilliseconds: frameTimestamp)
        } catch {
            print("[HandDetectionService] detectAsync error: \(error)")
            applyMissFrame()
        }
    }

    // MARK: - Orientation Mapping
    //
    // The back camera sensor is physically in landscape orientation.
    // We pass the current UI orientation to MPImage so MediaPipe can
    // rotate the frame internally and report correct left/right handedness.

    private func mpOrientation() -> UIImage.Orientation {
        switch currentOrientation {
        case .portrait:             return .right
        case .portraitUpsideDown:   return .left
        case .landscapeLeft:        return .up
        case .landscapeRight:       return .down
        default:                    return .right
        }
    }

    // MARK: - Smoothing Helpers

    private func applyMissFrame() {
        leftMissCount  = min(leftMissCount  + 1, missingFrameThreshold)
        rightMissCount = min(rightMissCount + 1, missingFrameThreshold)
        publishResult()
    }

    private func publishResult() {
        detectionSubject.send(HandDetectionResult(
            leftHandDetected:  leftMissCount  < missingFrameThreshold,
            rightHandDetected: rightMissCount < missingFrameThreshold
        ))
    }
}

// MARK: - HandLandmarkerLiveStreamDelegate

extension HandDetectionService: HandLandmarkerLiveStreamDelegate {

    // Correct signature as per MediaPipe Tasks Vision Swift API:
    // - result is optional HandLandmarkerResult (not a wrapper type)
    // - error is (any Error)? — note `any` keyword required in Swift 5.7+
    func handLandmarker(
        _ handLandmarker: HandLandmarker,
        didFinishDetection result: HandLandmarkerResult?,
        timestampInMilliseconds: Int,
        error: (any Error)?
    ) {
        if let error {
            print("[HandDetectionService] Detection error: \(error)")
            applyMissFrame()
            return
        }

        guard let result, !result.handedness.isEmpty else {
            // No hands in frame
            applyMissFrame()
            return
        }

        var userLeftSeen  = false
        var userRightSeen = false

        for (index, handedness) in result.handedness.enumerated() {
            guard let category = handedness.first else { continue }

            // Confidence gate — skip uncertain classifications
            guard category.score >= minHandDetectionConfidence else { continue }

            // Ensure a matching landmark set exists for this hand index
            guard index < result.landmarks.count else { continue }

            // categoryName is "Left" or "Right" from MediaPipe's perspective.
            // With correct MPImage orientation set, this already maps to
            // the user's actual hand — no manual flip needed.
            switch category.categoryName?.lowercased() {
            case "left":
                userLeftSeen = true
            case "right":
                userRightSeen = true
            default:
                // Unknown categoryName: fall back to wrist x-position
                // In normalized image coords: x < 0.5 = left side of frame
                if let wrist = result.landmarks[index].first {
                    if wrist.x < 0.5 {
                        userRightSeen = true
                    } else {
                        userLeftSeen = true
                    }
                }
            }
        }

        // Update smoothing counters: reset on detection, increment on miss
        leftMissCount  = userLeftSeen  ? 0 : min(leftMissCount  + 1, missingFrameThreshold)
        rightMissCount = userRightSeen ? 0 : min(rightMissCount + 1, missingFrameThreshold)

        publishResult()
    }
}
