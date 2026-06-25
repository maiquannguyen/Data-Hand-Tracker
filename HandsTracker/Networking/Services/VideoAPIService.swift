//
//  VideoAPIService.swift
//  HandsTracker
//
//  Created by Nguyễn Mai Quân on 23/6/26.
//

import Foundation
import Combine

// MARK: - Protocol

protocol VideoAPIServiceProtocol {
    func fetchVideos() -> AnyPublisher<GetVideosResponse, NetworkError>

    func uploadVideo(
        item: VideoItem,
        progressHandler: ((Double) -> Void)?
    ) -> AnyPublisher<UploadVideoResponse, NetworkError>

    func deleteVideo(videoId: String) -> AnyPublisher<EmptyResponse, NetworkError>
}

// MARK: - Empty Response Helper

struct EmptyResponse: Decodable {}

// MARK: - Implementation

final class VideoAPIService: VideoAPIServiceProtocol {

    static let shared = VideoAPIService()

    private let network: NetworkServiceProtocol

    init(network: NetworkServiceProtocol = NetworkService.shared) {
        self.network = network
    }

    // MARK: - Fetch Videos

    func fetchVideos() -> AnyPublisher<GetVideosResponse, NetworkError> {
        network.request(
            endpoint: VideoEndpoint.getVideos,
            responseType: GetVideosResponse.self
        )
    }

    // MARK: - Upload Video (multipart)

    func uploadVideo(
        item: VideoItem,
        progressHandler: ((Double) -> Void)? = nil
    ) -> AnyPublisher<UploadVideoResponse, NetworkError> {
        network.uploadMultipart(
            endpoint: VideoEndpoint.uploadVideo(fileURL: item.fileURL, fileName: item.fileName),
            fileURL: item.fileURL,
            fileName: item.fileName,
            mimeType: "video/quicktime",
            multipartName: "file",
            additionalFields: [
                "fileName": item.fileName,
                "createdAt": ISO8601DateFormatter().string(from: item.createdAt)
            ],
            responseType: UploadVideoResponse.self,
            progressHandler: progressHandler
        )
    }

    // MARK: - Delete Video

    func deleteVideo(videoId: String) -> AnyPublisher<EmptyResponse, NetworkError> {
        network.request(
            endpoint: VideoEndpoint.deleteVideo(videoId: videoId),
            responseType: EmptyResponse.self
        )
    }
}
