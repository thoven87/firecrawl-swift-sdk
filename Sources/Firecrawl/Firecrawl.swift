import AsyncHTTPClient
import Crypto
import Foundation
import Logging
import NIOCore
import NIOFoundationCompat
import NIOHTTP1

/// Main client for interacting with the Firecrawl API
public final class FirecrawlClient: Sendable {
    // MARK: - Properties

    /// The API key for authentication
    private let apiKey: String

    /// The base URL for the Firecrawl API
    private let baseURL: String

    /// HTTP client for making requests
    private let httpClient: HTTPClient

    /// Logger instance
    private let logger: Logger

    /// Whether the client owns the HTTP client (for cleanup)
    private let ownsHTTPClient: Bool

    // MARK: - Initialization

    /// Initialize a new Firecrawl client
    /// - Parameters:
    ///   - apiKey: Your Firecrawl API key (should start with "fc-")
    ///   - baseURL: The base URL for the API (defaults to "https://api.firecrawl.dev")
    ///   - httpClient: Optional HTTP client to use (will create one if not provided)
    ///   - logger: Optional logger instance
    public init(
        apiKey: String,
        baseURL: String = "https://api.firecrawl.dev",
        httpClient: HTTPClient? = nil,
        logger: Logger? = nil
    ) {
        self.apiKey = apiKey
        self.baseURL = baseURL.hasSuffix("/") ? String(baseURL.dropLast()) : baseURL

        if let httpClient = httpClient {
            self.httpClient = httpClient
            self.ownsHTTPClient = false
        } else {
            self.httpClient = HTTPClient(eventLoopGroupProvider: .singleton)
            self.ownsHTTPClient = true
        }

        self.logger = logger ?? Logger(label: "firecrawl-client")
    }

    deinit {
        if ownsHTTPClient {
            try? httpClient.syncShutdown()
        }
    }

    // MARK: - Public API Methods

    /// Scrape a single URL and extract its content
    /// - Parameter request: The scrape request parameters
    /// - Returns: The scraped content and metadata
    /// - Throws: FirecrawlError on failure
    public func scrape(_ request: ScrapeRequest) async throws -> ScrapeResponse {
        logger.debug("Scraping URL: \(request.url)")

        let endpoint = "/v2/scrape"
        let response: ScrapeResponse = try await makeRequest(
            method: .POST,
            endpoint: endpoint,
            body: request
        )

        return response
    }

    /// Start a crawl job for a website
    /// - Parameter request: The crawl request parameters
    /// - Returns: The crawl job information
    /// - Throws: FirecrawlError on failure
    public func startCrawl(_ request: CrawlRequest) async throws -> CrawlResponse {
        logger.debug("Starting crawl for URL: \(request.url)")

        let endpoint = "/v2/crawl"
        let response: CrawlResponse = try await makeRequest(
            method: .POST,
            endpoint: endpoint,
            body: request
        )

        return response
    }

    /// Check the status of a crawl job
    /// - Parameter jobId: The crawl job ID
    /// - Returns: The current status and results
    /// - Throws: FirecrawlError on failure
    public func getCrawlStatus(_ jobId: String) async throws -> CrawlStatusResponse {
        logger.debug("Getting crawl status for job: \(jobId)")

        let endpoint = "/v2/crawl/\(jobId)"
        let response: CrawlStatusResponse = try await makeGenericRequest(
            method: .GET,
            endpoint: endpoint
        )

        return response
    }

    /// Cancel a crawl job
    /// - Parameter jobId: The crawl job ID to cancel
    /// - Returns: The cancellation response
    /// - Throws: FirecrawlError on failure
    public func cancelCrawl(_ jobId: String) async throws -> CrawlCancelResponse {
        logger.debug("Canceling crawl job: \(jobId)")

        let endpoint = "/v2/crawl/\(jobId)"
        let response: CrawlCancelResponse = try await makeGenericRequest(
            method: .DELETE,
            endpoint: endpoint
        )

        return response
    }

    /// Get crawl errors for a specific job
    /// - Parameter jobId: The crawl job ID
    /// - Returns: The crawl errors response
    /// - Throws: FirecrawlError on failure
    public func getCrawlErrors(_ jobId: String) async throws -> CrawlErrorsResponse {
        logger.debug("Getting crawl errors for job: \(jobId)")

        let endpoint = "/v2/crawl/\(jobId)/errors"
        let response: CrawlErrorsResponse = try await makeGenericRequest(
            method: .GET,
            endpoint: endpoint
        )

        return response
    }

    /// Get all active crawls
    /// - Returns: The active crawls response
    /// - Throws: FirecrawlError on failure
    public func getActiveCrawls() async throws -> ActiveCrawlsResponse {
        logger.debug("Getting active crawls")

        let endpoint = "/v2/crawl/active"
        let response: ActiveCrawlsResponse = try await makeRequest(
            method: .GET,
            endpoint: endpoint
        )

        return response
    }

    /// Preview crawl parameters generated from natural language prompt
    /// - Parameter request: The crawl params preview request
    /// - Returns: The generated crawl parameters
    /// - Throws: FirecrawlError on failure
    public func getCrawlParamsPreview(
        _ request: CrawlParamsPreviewRequest
    ) async throws -> CrawlParamsPreviewResponse {
        logger.debug("Getting crawl params preview for URL: \(request.url)")

        let endpoint = "/v2/crawl/params-preview"
        let response: CrawlParamsPreviewResponse = try await makeRequest(
            method: .POST,
            endpoint: endpoint,
            body: request
        )

        return response
    }

    /// Map a website to get all its URLs
    /// - Parameter request: The map request parameters
    /// - Returns: The list of URLs found
    /// - Throws: FirecrawlError on failure
    public func map(_ request: MapRequest) async throws -> MapResponse {
        logger.debug("Mapping URLs for: \(request.url)")

        let endpoint = "/v2/map"
        let response: MapResponse = try await makeRequest(
            method: .POST,
            endpoint: endpoint,
            body: request
        )

        return response
    }

    /// Search the web and scrape results
    /// - Parameter request: The search request parameters
    /// - Returns: The search results with scraped content
    /// - Throws: FirecrawlError on failure
    public func search(_ request: SearchRequest) async throws -> SearchResponse {
        logger.debug("Searching for: \(request.query)")

        let endpoint = "/v2/search"
        let response: SearchResponse = try await makeRequest(
            method: .POST,
            endpoint: endpoint,
            body: request
        )

        return response
    }

    /// Start an extract job for multiple URLs
    /// - Parameter request: The extract request parameters
    /// - Returns: The extract job information
    /// - Throws: FirecrawlError on failure
    public func startExtract(_ request: ExtractRequest) async throws -> ExtractResponse {
        logger.debug("Starting extract for \(request.urls.count) URLs")

        let endpoint = "/v2/extract"
        let response: ExtractResponse = try await makeRequest(
            method: .POST,
            endpoint: endpoint,
            body: request
        )

        return response
    }

    /// Check the status of an extract job
    /// - Parameter jobId: The extract job ID
    /// - Returns: The current status and extracted data
    /// - Throws: FirecrawlError on failure
    public func getExtractStatus(_ jobId: String) async throws -> ExtractStatusResponse {
        logger.debug("Getting extract status for job: \(jobId)")

        let endpoint = "/v2/extract/\(jobId)"
        let response: ExtractStatusResponse = try await makeRequest(
            method: .GET,
            endpoint: endpoint
        )

        return response
    }

    /// Cancel an extract job
    /// - Parameter jobId: The extract job ID to cancel
    /// - Returns: The cancellation response
    /// - Throws: FirecrawlError on failure
    public func cancelExtract(_ jobId: String) async throws -> ExtractCancelResponse {
        logger.debug("Canceling extract job: \(jobId)")

        let endpoint = "/v2/extract/\(jobId)"
        let response: ExtractCancelResponse = try await makeRequest(
            method: .DELETE,
            endpoint: endpoint
        )

        return response
    }

    /// Get historical token usage by billing periods
    /// - Parameter byApiKey: Whether to get usage broken down by API key
    /// - Returns: Historical token usage across billing periods
    /// - Throws: FirecrawlError on failure
    public func getHistoricalTokenUsage(byApiKey: Bool = false) async throws
        -> HistoricalTokenUsageResponse
    {
        logger.debug("Getting historical token usage (byApiKey: \(byApiKey))")

        let endpoint = "/v2/team/token-usage/historical" + (byApiKey ? "?byApiKey=true" : "")
        let response: HistoricalTokenUsageResponse = try await makeRequest(
            method: .GET,
            endpoint: endpoint
        )

        return response
    }

    /// Get team queue status
    /// - Returns: Current queue status including active and waiting jobs
    /// - Throws: FirecrawlError on failure
    public func getQueueStatus() async throws -> QueueStatusResponse {
        logger.debug("Getting queue status")

        let endpoint = "/v2/team/queue-status"
        let response: QueueStatusResponse = try await makeRequest(
            method: .GET,
            endpoint: endpoint
        )

        return response
    }

    /// Get current credit usage information
    /// - Returns: Current credit usage including remaining and plan credits
    /// - Throws: FirecrawlError on failure
    public func getCreditUsage() async throws -> CreditUsageResponse {
        logger.debug("Getting credit usage information")

        let endpoint = "/v2/team/credit-usage"
        let response: CreditUsageResponse = try await makeRequest(
            method: .GET,
            endpoint: endpoint
        )

        return response
    }

    /// Get historical credit usage by billing periods
    /// - Parameter byApiKey: Whether to get usage broken down by API key
    /// - Returns: Historical credit usage across billing periods
    /// - Throws: FirecrawlError on failure
    public func getHistoricalCreditUsage(byApiKey: Bool = false) async throws
        -> HistoricalCreditUsageResponse
    {
        logger.debug("Getting historical credit usage (byApiKey: \(byApiKey))")

        let endpoint = "/v2/team/credit-usage/historical" + (byApiKey ? "?byApiKey=true" : "")
        let response: HistoricalCreditUsageResponse = try await makeRequest(
            method: .GET,
            endpoint: endpoint
        )

        return response
    }

    /// Get current token usage information
    /// - Returns: Current token usage including remaining and plan tokens
    /// - Throws: FirecrawlError on failure
    public func getTokenUsage() async throws -> TokenUsageResponse {
        logger.debug("Getting token usage information")

        let endpoint = "/v2/team/token-usage"
        let response: TokenUsageResponse = try await makeRequest(
            method: .GET,
            endpoint: endpoint
        )

        return response
    }

    /// Start a batch scrape job for multiple URLs
    /// - Parameter request: The batch scrape request parameters
    /// - Returns: The batch scrape job information
    /// - Throws: FirecrawlError on failure
    public func startBatchScrape(_ request: BatchScrapeRequest) async throws -> BatchScrapeResponse
    {
        logger.debug("Starting batch scrape for \(request.urls.count) URLs")

        let endpoint = "/v2/batch/scrape"
        let response: BatchScrapeResponse = try await makeRequest(
            method: .POST,
            endpoint: endpoint,
            body: request
        )

        return response
    }

    /// Check the status of a batch scrape job
    /// - Parameter jobId: The batch scrape job ID
    /// - Returns: The current status and results
    /// - Throws: FirecrawlError on failure
    public func getBatchScrapeStatus(_ jobId: String) async throws -> BatchScrapeStatusResponse {
        logger.debug("Getting batch scrape status for job: \(jobId)")

        let endpoint = "/v2/batch/scrape/\(jobId)"
        let response: BatchScrapeStatusResponse = try await makeRequest(
            method: .GET,
            endpoint: endpoint
        )

        return response
    }

    /// Cancel a batch scrape job
    /// - Parameter jobId: The batch scrape job ID to cancel
    /// - Returns: The cancellation response
    /// - Throws: FirecrawlError on failure
    public func cancelBatchScrape(_ jobId: String) async throws -> BatchScrapeCancelResponse {
        logger.debug("Canceling batch scrape job: \(jobId)")

        let endpoint = "/v2/batch/scrape/\(jobId)"
        let response: BatchScrapeCancelResponse = try await makeRequest(
            method: .DELETE,
            endpoint: endpoint
        )

        return response
    }

    /// Get errors from a batch scrape job
    /// - Parameter jobId: The batch scrape job ID
    /// - Returns: The errors that occurred during the batch scrape
    /// - Throws: FirecrawlError on failure
    public func getBatchScrapeErrors(_ jobId: String) async throws -> BatchScrapeErrorsResponse {
        logger.debug("Getting batch scrape errors for job: \(jobId)")

        let endpoint = "/v2/batch/scrape/\(jobId)/errors"
        let response: BatchScrapeErrorsResponse = try await makeRequest(
            method: .GET,
            endpoint: endpoint
        )

        return response
    }
}

// MARK: - Convenience Methods

extension FirecrawlClient {
    /// Scrape a URL with default settings
    /// - Parameters:
    ///   - url: The URL to scrape
    ///   - formats: Optional formats to extract (defaults to markdown)
    /// - Returns: The scraped content
    /// - Throws: FirecrawlError on failure
    public func scrape(url: String, formats: [Format] = [.markdown]) async throws -> ScrapeResponse
    {
        let request = ScrapeRequest(url: url, formats: formats)
        return try await scrape(request)
    }

    /// Start a crawl with basic settings
    /// - Parameters:
    ///   - url: The URL to crawl
    ///   - limit: Maximum number of pages to crawl
    ///   - formats: Optional formats to extract (defaults to markdown)
    /// - Returns: The crawl job information
    /// - Throws: FirecrawlError on failure
    public func crawl(url: String, limit: Int? = nil, formats: [Format] = [.markdown]) async throws
        -> CrawlResponse
    {
        let scrapeOptions = CrawlScrapeOptions(formats: formats)
        let request = CrawlRequest(url: url, limit: limit, scrapeOptions: scrapeOptions)
        return try await startCrawl(request)
    }

    /// Map a website's URLs with basic settings
    /// - Parameters:
    ///   - url: The URL to map
    ///   - limit: Maximum number of URLs to return
    ///   - search: Search query to order results by relevance
    /// - Returns: The list of URLs
    /// - Throws: FirecrawlError on failure
    public func map(url: String, limit: Int? = nil, search: String? = nil) async throws
        -> MapResponse
    {
        let request = MapRequest(url: url, search: search, limit: limit)
        return try await map(request)
    }

    /// Search the web with basic settings
    /// - Parameters:
    ///   - query: The search query
    ///   - limit: Number of results to return
    ///   - sources: Search sources (defaults to web)
    ///   - formats: Optional formats to extract (defaults to markdown)
    /// - Returns: The search results with web, images, and news arrays
    /// - Throws: FirecrawlError on failure
    public func search(
        query: String, limit: Int = 5, sources: [SearchSource] = [.web()],
        formats: [Format] = [.markdown]
    ) async throws
        -> SearchResponse
    {
        let scrapeOptions = SearchScrapeOptions(formats: formats)
        let request = SearchRequest(
            query: query, limit: limit, sources: sources, scrapeOptions: scrapeOptions)
        return try await search(request)
    }

    /// Extract data using a natural language prompt
    /// - Parameters:
    ///   - urls: The URLs to extract from
    ///   - prompt: Natural language description of what to extract
    /// - Returns: The extract job information
    /// - Throws: FirecrawlError on failure
    public func extract(urls: [String], prompt: String) async throws -> ExtractResponse {
        let request = ExtractRequest(urls: urls, prompt: prompt)
        return try await startExtract(request)
    }

    /// Extract data using a predefined schema
    /// - Parameters:
    ///   - urls: The URLs to extract from
    ///   - schema: The schema definition for extraction
    /// - Returns: The extract job information
    /// - Throws: FirecrawlError on failure
    public func extract(urls: [String], schema: ExtractionSchema) async throws -> ExtractResponse {
        let request = ExtractRequest(urls: urls, schema: schema)
        return try await startExtract(request)
    }

    /// Start a batch scrape with basic settings
    /// - Parameters:
    ///   - urls: The URLs to scrape
    ///   - formats: Optional formats to extract (defaults to markdown)
    ///   - maxConcurrency: Maximum number of concurrent scrapes
    /// - Returns: The batch scrape job information
    /// - Throws: FirecrawlError on failure
    public func batchScrape(
        urls: [String],
        formats: [Format] = [.markdown],
        maxConcurrency: Int? = nil
    ) async throws -> BatchScrapeResponse {
        let request = BatchScrapeRequest(
            urls: urls,
            maxConcurrency: maxConcurrency,
            formats: formats
        )
        return try await startBatchScrape(request)
    }
}

// MARK: - Polling Utilities

extension FirecrawlClient {
    /// Wait for a crawl job to complete with polling
    /// - Parameters:
    ///   - jobId: The crawl job ID
    ///   - pollInterval: How often to check status (in seconds, defaults to 2)
    ///   - timeout: Maximum time to wait (in seconds, defaults to 300)
    /// - Returns: The final crawl status with all results
    /// - Throws: FirecrawlError on failure or timeout
    public func waitForCrawlCompletion(
        _ jobId: String,
        pollInterval: TimeInterval = 2.0,
        timeout: TimeInterval = 300.0
    ) async throws -> CrawlStatusResponse {
        logger.debug("Waiting for crawl completion: \(jobId)")

        let startTime = Date()

        while Date().timeIntervalSince(startTime) < timeout {
            let status = try await getCrawlStatus(jobId)

            if status.status.isFinal {
                logger.debug("Crawl completed with status: \(status.status)")
                return status
            }

            logger.debug("Crawl still in progress, sleeping for \(pollInterval)s")
            try await Task.sleep(nanoseconds: UInt64(pollInterval * 1_000_000_000))
        }

        throw FirecrawlError.unknown(408, "Crawl job timed out after \(timeout) seconds")
    }

    /// Wait for a batch scrape job to complete with polling
    /// - Parameters:
    ///   - jobId: The batch scrape job ID
    ///   - pollInterval: How often to check status (in seconds, defaults to 2)
    ///   - timeout: Maximum time to wait (in seconds, defaults to 300)
    /// - Returns: The final batch scrape status with all results
    /// - Throws: FirecrawlError on failure or timeout
    public func waitForBatchScrapeCompletion(
        _ jobId: String,
        pollInterval: TimeInterval = 2.0,
        timeout: TimeInterval = 300.0
    ) async throws -> BatchScrapeStatusResponse {
        logger.debug("Waiting for batch scrape completion: \(jobId)")

        let startTime = Date()

        while Date().timeIntervalSince(startTime) < timeout {
            let status = try await getBatchScrapeStatus(jobId)

            if status.status.isFinal {
                logger.debug("Batch scrape completed with status: \(status.status)")
                return status
            }

            logger.debug("Batch scrape still in progress, sleeping for \(pollInterval)s")
            try await Task.sleep(nanoseconds: UInt64(pollInterval * 1_000_000_000))
        }

        throw FirecrawlError.unknown(408, "Batch scrape job timed out after \(timeout) seconds")
    }

    /// Wait for an extract job to complete with polling
    /// - Parameters:
    ///   - jobId: The extract job ID
    ///   - pollInterval: How often to check status (in seconds, defaults to 2)
    ///   - timeout: Maximum time to wait (in seconds, defaults to 300)
    /// - Returns: The final extract status with extracted data
    /// - Throws: FirecrawlError on failure or timeout
    public func waitForExtractCompletion(
        _ jobId: String,
        pollInterval: TimeInterval = 2.0,
        timeout: TimeInterval = 300.0
    ) async throws -> ExtractStatusResponse {
        logger.debug("Waiting for extract completion: \(jobId)")

        let startTime = Date()

        while Date().timeIntervalSince(startTime) < timeout {
            let status = try await getExtractStatus(jobId)

            if status.status.isFinal {
                logger.debug("Extract completed with status: \(status.status)")
                return status
            }

            logger.debug("Extract still in progress, sleeping for \(pollInterval)s")
            try await Task.sleep(nanoseconds: UInt64(pollInterval * 1_000_000_000))
        }

        throw FirecrawlError.unknown(408, "Extract job timed out after \(timeout) seconds")
    }
}

// MARK: - HTTP Client Implementation

extension FirecrawlClient {
    /// Make an HTTP request to the Firecrawl API
    private func makeRequest<T: Codable, U: FirecrawlResponse>(
        method: NIOHTTP1.HTTPMethod,
        endpoint: String,
        body: T? = nil
    ) async throws -> U {
        // Construct URL
        guard let url = URL(string: "\(baseURL)\(endpoint)") else {
            throw FirecrawlError.invalidURL("\(baseURL)\(endpoint)")
        }

        // Create request
        var request = HTTPClientRequest(url: url.absoluteString)
        request.method = method

        // Add headers
        request.headers.add(name: "Authorization", value: "Bearer \(apiKey)")
        request.headers.add(name: "Content-Type", value: "application/json")
        request.headers.add(name: "User-Agent", value: "Firecrawl-Swift-SDK/1.0.0")

        // Add body if present
        if let body = body {
            do {
                let jsonData = try JSONEncoder().encode(body)
                request.body = .bytes(jsonData)
            } catch {
                throw FirecrawlError.encodingError(error)
            }
        }

        // Execute request
        let response: HTTPClientResponse
        do {
            response = try await httpClient.execute(request, timeout: .seconds(30))
        } catch {
            throw FirecrawlError.networkError(error)
        }

        // Read response body
        let responseBody: ByteBuffer
        do {
            responseBody = try await response.body.collect(upTo: 10 * 1024 * 1024)  // 10MB limit
        } catch {
            throw FirecrawlError.networkError(error)
        }

        // Handle HTTP status codes
        switch response.status.code {
        case 200...299:
            // Success - decode response
            do {
                let decoder = JSONDecoder()
                let result = try decoder.decode(U.self, from: responseBody)
                return result
            } catch {
                logger.error("Failed to decode response: \(error)")
                throw FirecrawlError.decodingError(error)
            }

        case 400:
            // Bad request - try to decode error response
            if let errorResponse = try? JSONDecoder().decode(
                FirecrawlErrorResponse.self, from: responseBody)
            {
                throw FirecrawlError.badRequest(errorResponse.error, errorResponse.validationErrors)
            } else {
                throw FirecrawlError.badRequest("Bad request", nil)
            }

        case 401:
            // Unauthorized
            if let errorResponse = try? JSONDecoder().decode(
                FirecrawlErrorResponse.self, from: responseBody)
            {
                throw FirecrawlError.unauthorized(errorResponse.error)
            } else {
                throw FirecrawlError.unauthorized("Invalid API key")
            }

        case 402:
            // Payment required
            if let errorResponse = try? JSONDecoder().decode(
                FirecrawlErrorResponse.self, from: responseBody)
            {
                throw FirecrawlError.paymentRequired(errorResponse.error)
            } else {
                throw FirecrawlError.paymentRequired("Payment required")
            }

        case 404:
            // Not found
            if let errorResponse = try? JSONDecoder().decode(
                FirecrawlErrorResponse.self, from: responseBody)
            {
                throw FirecrawlError.notFound(errorResponse.error)
            } else {
                throw FirecrawlError.notFound("Resource not found")
            }

        case 429:
            // Rate limit exceeded
            if let errorResponse = try? JSONDecoder().decode(
                FirecrawlErrorResponse.self, from: responseBody)
            {
                throw FirecrawlError.rateLimitExceeded(errorResponse.error)
            } else {
                throw FirecrawlError.rateLimitExceeded("Rate limit exceeded")
            }

        case 500...599:
            // Server error
            if let errorResponse = try? JSONDecoder().decode(
                FirecrawlErrorResponse.self, from: responseBody)
            {
                throw FirecrawlError.serverError(Int(response.status.code), errorResponse.error)
            } else {
                throw FirecrawlError.serverError(Int(response.status.code), "Server error")
            }

        default:
            // Unknown status code
            let message = String(buffer: responseBody)
            throw FirecrawlError.unknown(Int(response.status.code), message)
        }
    }

}

// MARK: - Webhook Signature Verification

extension FirecrawlClient {
    /// Webhook signature verification error
    public enum WebhookSignatureError: Error, LocalizedError, Sendable {
        case missingSignatureHeader
        case invalidSignatureFormat
        case invalidSignature

        public var errorDescription: String? {
            switch self {
            case .missingSignatureHeader:
                return "Missing X-Firecrawl-Signature header"
            case .invalidSignatureFormat:
                return "Invalid signature format. Expected format: sha256=<hash>"
            case .invalidSignature:
                return "Webhook signature verification failed"
            }
        }
    }

    /// Verify the authenticity of a webhook request from Firecrawl
    /// - Parameters:
    ///   - payload: The raw request body as ByteBuffer
    ///   - signature: The X-Firecrawl-Signature header value
    ///   - secret: Your webhook secret key
    /// - Throws: WebhookSignatureError if verification fails
    public static func verifyWebhookSignature(
        payload: ByteBuffer,
        signature: String,
        secret: String
    ) throws {
        // Extract algorithm and hash from signature header
        let components = signature.split(separator: "=", maxSplits: 1)
        guard components.count == 2,
            components[0] == "sha256"
        else {
            throw WebhookSignatureError.invalidSignatureFormat
        }

        let providedHash = String(components[1])

        // Compute expected signature using HMAC-SHA256
        let key = SymmetricKey(data: Data(secret.utf8))
        let payloadData = Data(buffer: payload)
        let computedHash = HMAC<SHA256>.authenticationCode(for: payloadData, using: key)
        let expectedHash = Data(computedHash).map { String(format: "%02hhx", $0) }.joined()

        // Use timing-safe comparison
        guard providedHash.count == expectedHash.count else {
            throw WebhookSignatureError.invalidSignature
        }

        var result = 0
        for (provided, expected) in zip(providedHash, expectedHash) {
            result |= Int(provided.asciiValue ?? 0) ^ Int(expected.asciiValue ?? 0)
        }

        if result != 0 {
            throw WebhookSignatureError.invalidSignature
        }
    }

    /// Convenience method to verify webhook signature with string payload
    /// - Parameters:
    ///   - payload: The raw request body as String
    ///   - signature: The X-Firecrawl-Signature header value
    ///   - secret: Your webhook secret key
    /// - Throws: WebhookSignatureError if verification fails
    public static func verifyWebhookSignature(
        payload: String,
        signature: String,
        secret: String
    ) throws {
        let buffer = ByteBuffer(string: payload)
        try verifyWebhookSignature(
            payload: buffer,
            signature: signature,
            secret: secret
        )
    }
}

// MARK: - HTTP Request Helpers

extension FirecrawlClient {
    /// Overloaded version for GET requests without body
    private func makeRequest<U: FirecrawlResponse>(
        method: NIOHTTP1.HTTPMethod,
        endpoint: String
    ) async throws -> U {
        return try await makeRequest(
            method: method,
            endpoint: endpoint,
            body: Optional<String>.none
        )
    }

    /// Generic makeRequest for any Codable response (not requiring FirecrawlResponse)
    private func makeGenericRequest<U: Codable>(
        method: NIOHTTP1.HTTPMethod,
        endpoint: String
    ) async throws -> U {
        logger.debug("Making \(method.rawValue) request to: \(endpoint)")

        var request = HTTPClientRequest(url: "\(baseURL)\(endpoint)")
        request.method = method
        request.headers.add(name: "Authorization", value: "Bearer \(apiKey)")
        request.headers.add(name: "Content-Type", value: "application/json")
        request.headers.add(name: "User-Agent", value: "Firecrawl-Swift-SDK/1.0.0")

        let response = try await httpClient.execute(request, timeout: .seconds(30))

        guard response.status == .ok else {
            let bodyBytes = try await response.body.collect(upTo: 1024 * 1024)
            let bodyString = String(buffer: bodyBytes)
            logger.error("Request failed with status \(response.status): \(bodyString)")

            let decoder = JSONDecoder()
            if let errorResponse = try? decoder.decode(
                FirecrawlErrorResponse.self, from: bodyBytes)
            {
                switch response.status.code {
                case 401:
                    throw FirecrawlError.unauthorized(errorResponse.error)
                case 402:
                    throw FirecrawlError.paymentRequired(errorResponse.error)
                case 429:
                    throw FirecrawlError.rateLimitExceeded(errorResponse.error)
                case 400:
                    throw FirecrawlError.badRequest(
                        errorResponse.error, errorResponse.validationErrors)
                case 404:
                    throw FirecrawlError.notFound(errorResponse.error)
                case 500...599:
                    throw FirecrawlError.serverError(
                        Int(response.status.code), errorResponse.error)
                default:
                    throw FirecrawlError.unknown(Int(response.status.code), errorResponse.error)
                }
            }

            throw FirecrawlError.unknown(
                Int(response.status.code),
                "HTTP \(response.status.code): \(bodyString)"
            )
        }

        let bodyBytes = try await response.body.collect(upTo: 10 * 1024 * 1024)
        let decoder = JSONDecoder()

        do {
            let result = try decoder.decode(U.self, from: bodyBytes)
            return result
        } catch {
            let bodyString = String(buffer: bodyBytes)
            logger.error("Failed to decode response: \(error)")
            logger.debug("Response body: \(bodyString)")
            throw FirecrawlError.decodingError(error)
        }
    }
}
