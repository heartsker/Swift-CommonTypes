//
//  Created by Daniel Pustotin on 23.04.2024.
//

import Foundation

public struct BackendRequest {
    // MARK: - Public properties

    var endpoint: any Endpoint
    var timeout: TimeInterval = .tenSeconds
    var method: HttpMethod = .get
    var queryItems: [URLQueryItem] = []
    var headers: [String: String] = [:]
    var contentType: RequestContentType = .json
    var cachePolicy: CachePolicy = .useProtocolCachePolicy

    var data: RequestDataRepresentable?
    var retriesStrategy: RetryStrategy = ExponentialBackoffStrategy()

    // MARK: - Constructor

    internal init(
        endpoint: any Endpoint,
        timeout: TimeInterval = .tenSeconds,
        method: HttpMethod = .get,
        queryItems: [URLQueryItem] = [],
        headers: [String: String] = [:],
        contentType: RequestContentType = .json,
        cachePolicy: CachePolicy = .useProtocolCachePolicy,
        data: RequestDataRepresentable? = nil,
        retriesStrategy: RetryStrategy = ExponentialBackoffStrategy()
    ) {
        self.endpoint = endpoint
        self.timeout = timeout
        self.method = method
        self.queryItems = queryItems
        self.headers = headers
        self.contentType = contentType
        self.data = data
        self.retriesStrategy = retriesStrategy
    }

    // MARK: - Public methods

    func copy(
        timeout: TimeInterval? = nil,
        method: HttpMethod? = nil,
        queryItems: [URLQueryItem]? = nil,
        headers: [String: String]? = nil,
        contentType: RequestContentType? = nil,
        cachePolicy: CachePolicy? = nil,
        data: RequestDataRepresentable? = nil,
        explicitSession: AuthSession? = nil,
        retriesStrategy: RetryStrategy? = nil
    ) -> BackendRequest {
        BackendRequest(
            endpoint: endpoint,
            timeout: timeout ?? self.timeout,
            method: method ?? self.method,
            queryItems: queryItems ?? self.queryItems,
            headers: headers ?? self.headers,
            contentType: contentType ?? self.contentType,
            cachePolicy: cachePolicy ?? self.cachePolicy,
            data: data ?? self.data,
            retriesStrategy: retriesStrategy ?? self.retriesStrategy
        )
    }

    func buildURLRequest() throws -> (URLRequest, Data?) {
        guard let url = URL(string: endpoint.url) else {
            throw BackendRequesterError.badEndpoint(endpoint)
        }

        var request = URLRequest(url: url, timeoutInterval: timeout)
        request.httpMethod = method.rawValue
        request.url?.append(queryItems: queryItems)
        request.allHTTPHeaderFields = headers
        request.cachePolicy = cachePolicy

        request.setValue(contentType.rawValue, forHTTPHeaderField: "Content-Type")

        let contentData: Data?

        switch contentType {
        case .json:
            contentData = JSON(from: data ?? Data())?.encoded

        case .jpeg, .png:
            contentData = data as? Data
        }

        if method == .get, contentData != nil {
            throw BackendRequesterError.dataPassedForGetRequest
        }

        return (request, contentData)
    }
}

extension BackendRequest: Loggable {
    public var logDescription: String {
        "Backend request to \(endpoint.logDescription)"
    }

    public var info: [String: (any CustomStringConvertible)?] {
        [
            "endpoint": endpoint.logDescription,
            "timeout": timeout,
            "method": method.logDescription,
            "query items": queryItems,
            "headers": headers,
            "content type": contentType,
            "cache policy": cachePolicy.logDescription,
            "has data": data != nil,
            "retries strategy": retriesStrategy.logDescription
        ]
    }
}

extension BackendRequest: CustomStringConvertible {}
