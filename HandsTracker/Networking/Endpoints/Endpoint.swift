//
//  Endpoint.swift
//  HandsTracker
//
//  Created by Nguyễn Mai Quân on 23/6/26.
//

import Foundation
import Alamofire

// MARK: - Endpoint Protocol

protocol Endpoint {
    var baseURL: String { get }
    var path: String { get }
    var method: HTTPMethod { get }
    var headers: HTTPHeaders { get }
    var parameters: Parameters? { get }
    var encoding: ParameterEncoding { get }
}

extension Endpoint {
    var baseURL: String { Constants.API.baseURL }

    var fullURL: String { baseURL + path }

    var headers: HTTPHeaders {
        HTTPHeaders([
            HTTPHeader.contentType("application/json"),
            HTTPHeader.accept("application/json")
        ])
    }

    var parameters: Parameters? { nil }

    var encoding: ParameterEncoding { JSONEncoding.default }
}

// MARK: - Video Endpoints

enum VideoEndpoint: Endpoint {

    case getVideos
    case uploadVideo(fileURL: URL, fileName: String)
    case deleteVideo(videoId: String)

    var path: String {
        switch self {
        case .getVideos:            return "/videos"
        case .uploadVideo:          return "/videos/upload"
        case .deleteVideo(let id):  return "/videos/\(id)"
        }
    }

    var method: HTTPMethod {
        switch self {
        case .getVideos:    return .get
        case .uploadVideo:  return .post
        case .deleteVideo:  return .delete
        }
    }

    var parameters: Parameters? {
        switch self {
        case .getVideos, .uploadVideo, .deleteVideo:
            return nil
        }
    }

    var encoding: ParameterEncoding {
        switch self {
        case .getVideos, .deleteVideo:  return URLEncoding.default
        case .uploadVideo:              return JSONEncoding.default
        }
    }
}
