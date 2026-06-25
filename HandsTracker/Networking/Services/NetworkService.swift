//
//  NetworkService.swift
//  HandsTracker
//
//  Created by Nguyễn Mai Quân on 23/6/26.
//

import Foundation
import Alamofire
import Combine

// MARK: - Protocol

protocol NetworkServiceProtocol {
    func request<T: Decodable>(endpoint: Endpoint, responseType: T.Type) -> AnyPublisher<T, NetworkError>

    func uploadMultipart<T: Decodable>(
        endpoint: Endpoint,
        fileURL: URL,
        fileName: String,
        mimeType: String,
        multipartName: String,
        additionalFields: [String: String],
        responseType: T.Type,
        progressHandler: ((Double) -> Void)?
    ) -> AnyPublisher<T, NetworkError>

    func uploadFile<T: Decodable>(
        endpoint: Endpoint,
        fileURL: URL,
        mimeType: String,
        responseType: T.Type,
        progressHandler: ((Double) -> Void)?
    ) -> AnyPublisher<T, NetworkError>
}

// MARK: - Implementation

final class NetworkService: NetworkServiceProtocol {

    static let shared = NetworkService()

    private let session: Session

    private init() {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = Constants.API.timeoutInterval
        session = Session(configuration: configuration)
    }

    // MARK: - Auth Headers

    private func buildHeaders(from base: HTTPHeaders) -> HTTPHeaders {
        var headers = base
        if let bearer = AuthTokenManager.shared.bearerHeader {
            headers.add(name: "Authorization", value: bearer)
        }
        return headers
    }

    // MARK: - Standard Request

    func request<T: Decodable>(
        endpoint: Endpoint,
        responseType: T.Type
    ) -> AnyPublisher<T, NetworkError> {
        Future { [weak self] promise in
            guard let self else { return }
            let headers = self.buildHeaders(from: endpoint.headers)

            self.session
                .request(
                    endpoint.fullURL,
                    method: endpoint.method,
                    parameters: endpoint.parameters,
                    encoding: endpoint.encoding,
                    headers: headers
                )
                .validate()
                .responseDecodable(of: T.self) { response in
                    switch response.result {
                    case .success(let value):
                        promise(.success(value))
                    case .failure(let error):
                        promise(.failure(self.mapError(error, response: response)))
                    }
                }
        }
        .eraseToAnyPublisher()
    }

    // MARK: - Multipart Upload

    func uploadMultipart<T: Decodable>(
        endpoint: Endpoint,
        fileURL: URL,
        fileName: String,
        mimeType: String,
        multipartName: String,
        additionalFields: [String: String] = [:],
        responseType: T.Type,
        progressHandler: ((Double) -> Void)? = nil
    ) -> AnyPublisher<T, NetworkError> {
        Future { [weak self] promise in
            guard let self else { return }
            let headers = self.buildHeaders(from: endpoint.headers)

            self.session
                .upload(
                    multipartFormData: { formData in
                        formData.append(fileURL, withName: multipartName, fileName: fileName, mimeType: mimeType)
                        for (key, value) in additionalFields {
                            if let data = value.data(using: .utf8) {
                                formData.append(data, withName: key)
                            }
                        }
                    },
                    to: endpoint.fullURL,
                    method: endpoint.method,
                    headers: headers
                )
                .uploadProgress { progress in
                    progressHandler?(progress.fractionCompleted)
                }
                .validate()
                .responseDecodable(of: T.self) { response in
                    switch response.result {
                    case .success(let value):
                        promise(.success(value))
                    case .failure(let error):
                        promise(.failure(self.mapError(error, response: response)))
                    }
                }
        }
        .eraseToAnyPublisher()
    }

    // MARK: - Raw File Upload

    func uploadFile<T: Decodable>(
        endpoint: Endpoint,
        fileURL: URL,
        mimeType: String,
        responseType: T.Type,
        progressHandler: ((Double) -> Void)? = nil
    ) -> AnyPublisher<T, NetworkError> {
        Future { [weak self] promise in
            guard let self else { return }
            var headers = self.buildHeaders(from: endpoint.headers)
            headers.add(name: "Content-Type", value: mimeType)

            self.session
                .upload(fileURL, to: endpoint.fullURL, method: endpoint.method, headers: headers)
                .uploadProgress { progress in
                    progressHandler?(progress.fractionCompleted)
                }
                .validate()
                .responseDecodable(of: T.self) { response in
                    switch response.result {
                    case .success(let value):
                        promise(.success(value))
                    case .failure(let error):
                        promise(.failure(self.mapError(error, response: response)))
                    }
                }
        }
        .eraseToAnyPublisher()
    }

    // MARK: - Error Mapping

    private func mapError<T>(_ error: AFError, response: DataResponse<T, AFError>) -> NetworkError {
        if let statusCode = response.response?.statusCode, statusCode >= 400 {
            let message = response.data
                .flatMap { try? JSONSerialization.jsonObject(with: $0) as? [String: Any] }
                .flatMap { $0["message"] as? String }
            return .serverError(statusCode: statusCode, message: message)
        }
        return .unknown(error)
    }
}
