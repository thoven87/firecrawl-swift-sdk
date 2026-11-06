import Foundation
import Logging

/// Job descriptor returned when starting a crawl (id + url).
public typealias CrawlJob = CrawlResponse

// MARK: - Configuration

/// Configuration for retry behavior.
public struct RetryConfig: Sendable {
    public let maxAttempts: Int
    public let initialDelay: TimeInterval
    public let maxDelay: TimeInterval
    public let multiplier: Double

    public static let `default` = RetryConfig(
        maxAttempts: 3,
        initialDelay: 1.0,
        maxDelay: 30.0,
        multiplier: 2.0
    )

    public init(
        maxAttempts: Int = 3,
        initialDelay: TimeInterval = 1.0,
        maxDelay: TimeInterval = 30.0,
        multiplier: Double = 2.0
    ) {
        self.maxAttempts = maxAttempts
        self.initialDelay = initialDelay
        self.maxDelay = maxDelay
        self.multiplier = multiplier
    }
}

// MARK: - FirecrawlService

/// Context-aware Firecrawl service (v2.8.0): env API key, Spark models, parallel agents, webhooks, retry.
/// Use this when integrating with HIKARU Security Layer or Supabase; never hardcode API keys.
public final class FirecrawlService: Sendable {
    public let client: FirecrawlClient
    private let retryConfig: RetryConfig
    private let logger: Logger

    /// Environment key used for API key (never hardcode the key).
    public static let apiKeyEnvironmentKey = "FIRECRAWL_API_KEY"

    /// Create service with API key from environment.
    /// - Parameters:
    ///   - baseURL: Optional base URL (defaults to https://api.firecrawl.dev).
    ///   - retryConfig: Retry with exponential backoff (default 3 attempts).
    ///   - logger: Optional logger.
    /// - Throws: `FirecrawlError.configurationError` if `FIRECRAWL_API_KEY` is missing or empty.
    public init(
        baseURL: String = "https://api.firecrawl.dev",
        retryConfig: RetryConfig = .default,
        logger: Logger? = nil
    ) throws {
        try Self.validateEnvironment()
        let apiKey = ProcessInfo.processInfo.environment[Self.apiKeyEnvironmentKey]!
        self.client = FirecrawlClient(apiKey: apiKey.trimmingCharacters(in: .whitespacesAndNewlines), baseURL: baseURL, logger: logger)
        self.retryConfig = retryConfig
        self.logger = logger ?? Logger(label: "firecrawl-service")
    }

    /// Validates that required environment variables (e.g. API key) are present.
    /// Call before making any external requests; throws if configuration is invalid.
    /// - Throws: `FirecrawlError.configurationError` if `FIRECRAWL_API_KEY` is missing or empty.
    public static func validateEnvironment() throws {
        guard let apiKey = ProcessInfo.processInfo.environment[Self.apiKeyEnvironmentKey],
              !apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        else {
            throw FirecrawlError.configurationError(
                "Missing or empty \(Self.apiKeyEnvironmentKey). Set it in the environment and never hardcode. External requests are not permitted until the key is validated as PRESENT."
            )
        }
    }

    /// Create service with an explicitly provided API key (e.g. from a secure vault).
    /// Prefer `init(baseURL:retryConfig:logger:)` with env when possible.
    public init(
        apiKey: String,
        baseURL: String = "https://api.firecrawl.dev",
        retryConfig: RetryConfig = .default,
        logger: Logger? = nil
    ) {
        self.client = FirecrawlClient(apiKey: apiKey, baseURL: baseURL, logger: logger)
        self.retryConfig = retryConfig
        self.logger = logger ?? Logger(label: "firecrawl-service")
    }

    // MARK: - Scrape

    /// Scrape a single URL with the given formats.
    /// - Parameters:
    ///   - url: URL to scrape.
    ///   - formats: Format names (e.g. "markdown", "html"); invalid names are skipped; defaults to markdown.
    /// - Returns: ScrapeResponse with content and metadata.
    public func scrape(url: String, formats: [String] = ["markdown"]) async throws -> ScrapeResponse
    {
        let formatList: [Format] = formats.isEmpty
            ? [.markdown]
            : formats.compactMap { Format(rawValue: $0) }
        if formatList.isEmpty {
            logger.warning("No valid formats in \(formats); using markdown")
        }
        let request = ScrapeRequest(url: url, formats: formatList.isEmpty ? [.markdown] : formatList)
        return try await withRetry {
            try await self.client.scrape(request)
        }
    }

    // MARK: - Crawl

    /// Start a crawl with a maximum discovery depth.
    /// - Parameters:
    ///   - url: Root URL to crawl.
    ///   - maxDepth: Maximum depth to crawl (maps to maxDiscoveryDepth).
    /// - Returns: CrawlJob (id and url) for status polling or webhooks.
    public func crawl(url: String, maxDepth: Int) async throws -> CrawlJob {
        let request = CrawlRequest(
            url: url,
            maxDiscoveryDepth: maxDepth,
            scrapeOptions: CrawlScrapeOptions(formats: [.markdown])
        )
        return try await withRetry {
            try await self.client.startCrawl(request)
        }
    }

    // MARK: - Agent

    /// Run an agent task with the given Spark model and wait for completion (polling).
    /// - Parameters:
    ///   - task: Prompt describing what data to extract.
    ///   - model: Spark 1 Fast / Mini / Pro (default .mini).
    /// - Returns: AgentResponse with status and extracted data when completed.
    public func agent(task: String, model: SparkModel = .mini) async throws -> AgentResponse {
        try await withRetry {
            try await self.client.agent(task: task, model: model)
        }
    }

    /// Start an agent task with webhook for async completion (v2.8.0).
    /// - Parameters:
    ///   - task: Prompt describing what data to extract.
    ///   - model: Spark model to use.
    ///   - webhook: Webhook URL and optional events (started, action, completed, failed, cancelled).
    /// - Returns: Job id for correlation with webhook payloads.
    public func agentWithWebhook(
        task: String,
        model: SparkModel = .mini,
        webhook: AgentWebhook
    ) async throws -> String {
        let request = AgentRequest(prompt: task, model: model, webhook: webhook)
        let response = try await withRetry {
            try await self.client.startAgent(request)
        }
        guard let id = response.id else {
            throw FirecrawlError.invalidResponse("Agent start response missing id")
        }
        return id
    }

    /// Run multiple agent tasks in parallel (v2.8.0 parallel agents).
    /// - Parameters:
    ///   - tasks: List of prompts to run.
    ///   - model: Spark model for all tasks (e.g. .fast for throughput).
    /// - Returns: Array of AgentResponse in same order as tasks; failed tasks throw.
    public func agentParallel(
        tasks: [String],
        model: SparkModel = .fast
    ) async throws -> [AgentResponse] {
        try await withThrowingTaskGroup(of: (Int, AgentResponse).self) { group in
            for (index, task) in tasks.enumerated() {
                group.addTask {
                    let response = try await self.agent(task: task, model: model)
                    return (index, response)
                }
            }
            var pairs: [(Int, AgentResponse)] = []
            for try await pair in group {
                pairs.append(pair)
            }
            return pairs.sorted(by: { $0.0 < $1.0 }).map(\.1)
        }
    }

    // MARK: - Map

    /// Map a URL and return discovered links, optionally bypassing cache.
    /// - Parameters:
    ///   - url: URL to map.
    ///   - ignoreCache: If true, bypass cached results (v2.8.0).
    /// - Returns: Array of URLs (valid URL strings only).
    public func map(url: String, ignoreCache: Bool = false) async throws -> [URL] {
        let request = MapRequest(url: url, ignoreCache: ignoreCache)
        let response = try await withRetry {
            try await self.client.map(request)
        }
        let links = response.links ?? []
        return links.compactMap { URL(string: $0.url) }
    }

    // MARK: - Retry (exponential backoff)

    private func withRetry<T: Sendable>(
        _ operation: @Sendable () async throws -> T
    ) async throws -> T {
        var delay = retryConfig.initialDelay
        var lastError: Error?
        for attempt in 1...retryConfig.maxAttempts {
            do {
                return try await operation()
            } catch {
                lastError = error
                if attempt == retryConfig.maxAttempts { break }
                let capped = min(delay, retryConfig.maxDelay)
                logger.debug("Attempt \(attempt) failed, retrying in \(capped)s: \(error)")
                try await Task.sleep(nanoseconds: UInt64(capped * 1_000_000_000))
                delay *= retryConfig.multiplier
            }
        }
        if let fc = lastError as? FirecrawlError { throw fc }
        throw lastError ?? FirecrawlError.unknown(0, "Retry exhausted")
    }
}
