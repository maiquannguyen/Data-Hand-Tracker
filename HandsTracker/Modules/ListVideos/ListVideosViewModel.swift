//
//  ListVideosViewModel.swift
//  HandsTracker
//
//  Created by Nguyễn Mai Quân on 23/6/26.
//

import Foundation
import Combine

final class ListVideosViewModel {

    // MARK: - Published
    @Published private(set) var videos: [VideoItem] = []
    @Published private(set) var isLoading: Bool = false
    @Published private(set) var errorMessage: String?
    @Published private(set) var uploadingIDs: Set<UUID> = []

    // MARK: - Services
    private let storageService: VideoStorageServiceProtocol
    private let apiService: VideoAPIServiceProtocol
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Init
    init(
        storageService: VideoStorageServiceProtocol = VideoStorageService.shared,
        apiService: VideoAPIServiceProtocol = VideoAPIService.shared
    ) {
        self.storageService = storageService
        self.apiService = apiService
    }

    // MARK: - Load Local Videos
    func loadVideos() {
        videos = storageService.loadAllVideos()
    }

    // MARK: - Upload Single Video
    func uploadVideo(_ item: VideoItem) {
        guard !uploadingIDs.contains(item.id) else { return }

        uploadingIDs.insert(item.id)
        updateVideo(item.id, status: .uploading(progress: 0))

        apiService.uploadVideo(item: item) { [weak self] progress in
            self?.updateVideo(item.id, status: .uploading(progress: progress))
        }
        .receive(on: DispatchQueue.main)
        .sink { [weak self] completion in
            self?.uploadingIDs.remove(item.id)
            if case .failure(let error) = completion {
                self?.updateVideo(item.id, status: .failed(message: error.localizedDescription))
                self?.errorMessage = error.localizedDescription
            }
        } receiveValue: { [weak self] response in
            self?.updateVideo(item.id, status: .uploaded(remoteId: response.id))
        }
        .store(in: &cancellables)
    }

    // MARK: - Upload All Pending
    func uploadAllPending() {
        let pending = videos.filter {
            if case .notUploaded = $0.uploadStatus { return true }
            if case .failed = $0.uploadStatus { return true }
            return false
        }
        pending.forEach { uploadVideo($0) }
    }

    // MARK: - Delete Video
    func deleteVideo(_ item: VideoItem) {
        do {
            try storageService.deleteVideo(item)
            videos.removeAll { $0.id == item.id }
        } catch {
            errorMessage = "Failed to delete video: \(error.localizedDescription)"
        }
    }

    // MARK: - Helpers
    private func updateVideo(_ id: UUID, status: VideoItem.UploadStatus) {
        if let index = videos.firstIndex(where: { $0.id == id }) {
            videos[index].uploadStatus = status
        }
    }

    func clearError() {
        errorMessage = nil
    }
}
