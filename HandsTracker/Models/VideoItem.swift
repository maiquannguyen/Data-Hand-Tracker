//
//  VideoItem.swift
//  HandsTracker
//
//  Created by Nguyễn Mai Quân on 23/6/26.
//

import Foundation

// MARK: - Local Video (stored in Documents)

struct VideoItem: Identifiable, Hashable {
    let id: UUID
    let fileName: String
    let fileURL: URL
    let createdAt: Date
    var uploadStatus: UploadStatus

    enum UploadStatus: Hashable {
        case notUploaded
        case uploading(progress: Double)
        case uploaded(remoteId: String)
        case failed(message: String)
    }

    init(fileName: String, fileURL: URL, createdAt: Date = Date(), uploadStatus: UploadStatus = .notUploaded) {
        self.id = UUID()
        self.fileName = fileName
        self.fileURL = fileURL
        self.createdAt = createdAt
        self.uploadStatus = uploadStatus
    }
}

// MARK: - API Response Models

struct UploadVideoResponse: Decodable {
    let id: String
    let url: String
    let message: String?
}

struct GetVideosResponse: Decodable {
    let videos: [RemoteVideo]
}

struct RemoteVideo: Decodable, Identifiable {
    let id: String
    let url: String
    let fileName: String
    let createdAt: String
}
