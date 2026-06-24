//
//  HandDetectionService.swift
//  HandsTracker
//
//  Created by Nguyễn Mai Quân on 23/6/26.
//

import Foundation
import Vision
import CoreImage
import Combine

struct HandDetectionResult {
    let leftHandDetected: Bool
    let rightHandDetected: Bool

    var bothHandsDetected: Bool { leftHandDetected && rightHandDetected }
}

final class HandDetectionService {

    private let requestHandler = VNSequenceRequestHandler()
    private var detectionRequest: VNDetectHumanHandPoseRequest?

    let detectionSubject = PassthroughSubject<HandDetectionResult, Never>()

    init() {
        setupRequest()
    }

    private func setupRequest() {
        let request = VNDetectHumanHandPoseRequest { [weak self] request, error in
            self?.handleResults(request: request, error: error)
        }
        request.maximumHandCount = 2
        detectionRequest = request
    }

    func detect(in sampleBuffer: CMSampleBuffer) {
        guard let request = detectionRequest,
              let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        do {
            try requestHandler.perform([request], on: pixelBuffer, orientation: .up)
        } catch {
            detectionSubject.send(HandDetectionResult(leftHandDetected: false, rightHandDetected: false))
        }
    }

    private func handleResults(request: VNRequest, error: Error?) {
        guard let observations = request.results as? [VNHumanHandPoseObservation] else {
            detectionSubject.send(HandDetectionResult(leftHandDetected: false, rightHandDetected: false))
            return
        }

        var leftDetected = false
        var rightDetected = false

        for observation in observations {
            switch observation.chirality {
            case .left:  leftDetected = true
            case .right: rightDetected = true
            default:
                if !leftDetected { leftDetected = true }
                else { rightDetected = true }
            }
        }

        detectionSubject.send(HandDetectionResult(leftHandDetected: leftDetected, rightHandDetected: rightDetected))
    }
}
