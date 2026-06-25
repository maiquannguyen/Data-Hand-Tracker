//
//  ThumbnailService.swift
//  HandsTracker
//
//  Created by Nguyễn Mai Quân on 23/6/26.
//

import UIKit
import AVFoundation

final class ThumbnailService {

    static let shared = ThumbnailService()
    private init() {}

    private var cache = NSCache<NSURL, UIImage>()

    func thumbnail(for url: URL, at time: CMTime = .zero, completion: @escaping (UIImage?) -> Void) {
        let nsURL = url as NSURL

        // Return cached image immediately if available
        if let cached = cache.object(forKey: nsURL) {
            completion(cached)
            return
        }

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let asset = AVAsset(url: url)
            let generator = AVAssetImageGenerator(asset: asset)
            generator.appliesPreferredTrackTransform = true
            generator.maximumSize = CGSize(width: 400, height: 300)

            let requestedTime = time == .zero
                ? CMTime(seconds: min(1.0, asset.duration.seconds * 0.1), preferredTimescale: 600)
                : time

            var actualTime = CMTime.zero
            if let cgImage = try? generator.copyCGImage(at: requestedTime, actualTime: &actualTime) {
                let image = UIImage(cgImage: cgImage)
                self?.cache.setObject(image, forKey: nsURL)
                DispatchQueue.main.async { completion(image) }
            } else {
                DispatchQueue.main.async { completion(nil) }
            }
        }
    }

    func clearCache() {
        cache.removeAllObjects()
    }
}
