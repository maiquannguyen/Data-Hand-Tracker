//
//  VideoStorageService.swift
//  HandsTracker
//
//  Created by Nguyễn Mai Quân on 23/6/26.
//

import Foundation

// MARK: - Protocol

protocol VideoStorageServiceProtocol {
    var videosDirectory: URL { get }
    func saveVideo(from tempURL: URL) throws -> VideoItem
    func loadAllVideos() -> [VideoItem]
    func deleteVideo(_ item: VideoItem) throws
}

// MARK: - Implementation

final class VideoStorageService: VideoStorageServiceProtocol {

    static let shared = VideoStorageService()
    private init() {
        createVideosDirectoryIfNeeded()
    }

    // MARK: - Directory

    var videosDirectory: URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return docs.appendingPathComponent(Constants.Storage.videosFolderName, isDirectory: true)
    }

    private func createVideosDirectoryIfNeeded() {
        let dir = videosDirectory
        if !FileManager.default.fileExists(atPath: dir.path) {
            try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        }
    }

    // MARK: - Save

    func saveVideo(from tempURL: URL) throws -> VideoItem {
        let fileName = "\(UUID().uuidString).mov"
        let destination = videosDirectory.appendingPathComponent(fileName)
        try FileManager.default.copyItem(at: tempURL, to: destination)
        return VideoItem(fileName: fileName, fileURL: destination, createdAt: Date())
    }

    // MARK: - Load

    func loadAllVideos() -> [VideoItem] {
        guard let contents = try? FileManager.default.contentsOfDirectory(
            at: videosDirectory,
            includingPropertiesForKeys: [.creationDateKey],
            options: .skipsHiddenFiles
        ) else { return [] }

        return contents
            .filter { $0.pathExtension == "mov" || $0.pathExtension == "mp4" }
            .compactMap { url -> VideoItem? in
                let attrs = try? FileManager.default.attributesOfItem(atPath: url.path)
                let createdAt = attrs?[.creationDate] as? Date ?? Date()
                return VideoItem(fileName: url.lastPathComponent, fileURL: url, createdAt: createdAt)
            }
            .sorted { $0.createdAt > $1.createdAt }
    }

    // MARK: - Delete

    func deleteVideo(_ item: VideoItem) throws {
        try FileManager.default.removeItem(at: item.fileURL)
    }
}
