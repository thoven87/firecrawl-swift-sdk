import Foundation

/// Request parameters for crawling a website
public struct CrawlRequest: Codable, Sendable {
    /// The base URL to start crawling from
    public let url: String

    /// A prompt to use to generate the crawler options from natural language
    public let prompt: String?

    /// URL pathname regex patterns that exclude matching URLs from the crawl
    public let excludePaths: [String]?

    /// URL pathname regex patterns that include matching URLs in the crawl
    public let includePaths: [String]?

    /// Maximum depth to crawl based on discovery order
    public let maxDiscoveryDepth: Int?

    /// Sitemap mode when crawling
    public let sitemap: MapSitemapMode?

    /// Do not re-scrape the same path with different query parameters
    public let ignoreQueryParameters: Bool?

    /// Maximum number of pages to crawl
    public let limit: Int?

    /// Allows the crawler to follow internal links to sibling or parent URLs
    public let crawlEntireDomain: Bool?

    /// Allows the crawler to follow links to external websites
    public let allowExternalLinks: Bool?

    /// Allows the crawler to follow links to subdomains of the main domain
    public let allowSubdomains: Bool?

    /// Delay in seconds between scrapes
    public let delay: Double?

    /// Maximum number of concurrent scrapes
    public let maxConcurrency: Int?

    /// Webhook specification object
    public let webhook: WebhookConfig?

    /// Scrape options to apply to each page
    public let scrapeOptions: CrawlScrapeOptions?

    /// Enable zero data retention for this crawl
    public let zeroDataRetention: Bool?

    public init(
        url: String,
        prompt: String? = nil,
        excludePaths: [String]? = nil,
        includePaths: [String]? = nil,
        maxDiscoveryDepth: Int? = nil,
        sitemap: MapSitemapMode? = nil,
        ignoreQueryParameters: Bool? = nil,
        limit: Int? = nil,
        crawlEntireDomain: Bool? = nil,
        allowExternalLinks: Bool? = nil,
        allowSubdomains: Bool? = nil,
        delay: Double? = nil,
        maxConcurrency: Int? = nil,
        webhook: WebhookConfig? = nil,
        scrapeOptions: CrawlScrapeOptions? = nil,
        zeroDataRetention: Bool? = nil
    ) {
        self.url = url
        self.prompt = prompt
        self.excludePaths = excludePaths
        self.includePaths = includePaths
        self.maxDiscoveryDepth = maxDiscoveryDepth
        self.sitemap = sitemap
        self.ignoreQueryParameters = ignoreQueryParameters
        self.limit = limit
        self.crawlEntireDomain = crawlEntireDomain
        self.allowExternalLinks = allowExternalLinks
        self.allowSubdomains = allowSubdomains
        self.delay = delay
        self.maxConcurrency = maxConcurrency
        self.webhook = webhook
        self.scrapeOptions = scrapeOptions
        self.zeroDataRetention = zeroDataRetention
    }
}

/// Sitemap mode when crawling - using alias to avoid conflicts
public typealias MapSitemapMode = SitemapMode

/// Webhook configuration for crawl notifications
public struct WebhookConfig: Codable, Sendable {
    /// The URL to send the webhook to
    public let url: String

    /// Headers to send to the webhook URL
    public let headers: [String: String]?

    /// Custom metadata included in all webhook payloads
    public let metadata: [String: String]?

    /// Type of events that should be sent to the webhook URL
    public let events: [CrawlWebhookEvent]?

    public init(
        url: String,
        headers: [String: String]? = nil,
        metadata: [String: String]? = nil,
        events: [CrawlWebhookEvent]? = nil
    ) {
        self.url = url
        self.headers = headers
        self.metadata = metadata
        self.events = events
    }
}

/// Webhook events for crawl notifications
public enum CrawlWebhookEvent: String, Codable, CaseIterable, Sendable {
    case completed
    case page
    case failed
    case started
}

/// Scrape options to apply to each page during crawling
public struct CrawlScrapeOptions: Codable, Sendable {
    /// Output formats to include in the response
    public let formats: [Format]?

    /// Only return the main content of the page excluding headers, navs, footers, etc.
    public let onlyMainContent: Bool?

    /// Tags to include in the output
    public let includeTags: [String]?

    /// Tags to exclude from the output
    public let excludeTags: [String]?

    /// Returns a cached version if younger than this age in milliseconds
    public let maxAge: Int?

    /// Headers to send with the request
    public let headers: [String: String]?

    /// Delay in milliseconds before fetching the content
    public let waitFor: Int?

    /// Emulate scraping from a mobile device
    public let mobile: Bool?

    /// Skip TLS certificate verification
    public let skipTlsVerification: Bool?

    /// Timeout in milliseconds for the request
    public let timeout: Int?

    /// Controls how files are processed during scraping
    public let parsers: [Parser]?

    /// Actions to perform on the page before grabbing the content
    public let actions: [ScrapeAction]?

    /// Location settings for the request
    public let location: LocationSettings?

    /// Remove all base64 images from the output
    public let removeBase64Images: Bool?

    /// Enable ad-blocking and cookie popup blocking
    public let blockAds: Bool?

    /// Type of proxy to use
    public let proxy: ProxyType?

    /// Store the page in the Firecrawl index and cache
    public let storeInCache: Bool?

    public init(
        formats: [Format]? = nil,
        onlyMainContent: Bool? = nil,
        includeTags: [String]? = nil,
        excludeTags: [String]? = nil,
        maxAge: Int? = nil,
        headers: [String: String]? = nil,
        waitFor: Int? = nil,
        mobile: Bool? = nil,
        skipTlsVerification: Bool? = nil,
        timeout: Int? = nil,
        parsers: [Parser]? = nil,
        actions: [ScrapeAction]? = nil,
        location: LocationSettings? = nil,
        removeBase64Images: Bool? = nil,
        blockAds: Bool? = nil,
        proxy: ProxyType? = nil,
        storeInCache: Bool? = nil
    ) {
        self.formats = formats
        self.onlyMainContent = onlyMainContent
        self.includeTags = includeTags
        self.excludeTags = excludeTags
        self.maxAge = maxAge
        self.headers = headers
        self.waitFor = waitFor
        self.mobile = mobile
        self.skipTlsVerification = skipTlsVerification
        self.timeout = timeout
        self.parsers = parsers
        self.actions = actions
        self.location = location
        self.removeBase64Images = removeBase64Images
        self.blockAds = blockAds
        self.proxy = proxy
        self.storeInCache = storeInCache
    }
}

// MARK: - Webhook Models

/// Webhook payload structure for Firecrawl events
public struct FirecrawlWebhookPayload: Codable, Sendable {
    /// The event type (e.g., "crawl.started", "crawl.page", "crawl.completed")
    public let type: String

    /// The event data
    public let data: WebhookEventData

    /// Custom metadata included in webhook configuration
    public let metadata: [String: String]?

    public init(type: String, data: WebhookEventData, metadata: [String: String]? = nil) {
        self.type = type
        self.data = data
        self.metadata = metadata
    }
}

/// Webhook event data - varies by event type
public struct WebhookEventData: Codable, Sendable {
    /// Job ID for the operation
    public let jobId: String?

    /// URL being processed (for page events)
    public let url: String?

    /// Current status of the job
    public let status: String?

    /// Page content (for page events)
    public let markdown: String?
    public let html: String?
    public let rawHtml: String?
    public let links: [String]?
    public let screenshot: String?

    /// Page metadata
    public let metadata: WebhookPageMetadata?

    /// Progress information (for status events)
    public let total: Int?
    public let completed: Int?
    public let creditsUsed: Int?

    /// Error information (for failed events)
    public let error: String?

    public init(
        jobId: String? = nil,
        url: String? = nil,
        status: String? = nil,
        markdown: String? = nil,
        html: String? = nil,
        rawHtml: String? = nil,
        links: [String]? = nil,
        screenshot: String? = nil,
        metadata: WebhookPageMetadata? = nil,
        total: Int? = nil,
        completed: Int? = nil,
        creditsUsed: Int? = nil,
        error: String? = nil
    ) {
        self.jobId = jobId
        self.url = url
        self.status = status
        self.markdown = markdown
        self.html = html
        self.rawHtml = rawHtml
        self.links = links
        self.screenshot = screenshot
        self.metadata = metadata
        self.total = total
        self.completed = completed
        self.creditsUsed = creditsUsed
        self.error = error
    }
}

/// Page metadata included in webhook events
public struct WebhookPageMetadata: Codable, Sendable {
    public let title: String?
    public let description: String?
    public let statusCode: Int?
    public let sourceURL: String?
    public let error: String?

    public init(
        title: String? = nil,
        description: String? = nil,
        statusCode: Int? = nil,
        sourceURL: String? = nil,
        error: String? = nil
    ) {
        self.title = title
        self.description = description
        self.statusCode = statusCode
        self.sourceURL = sourceURL
        self.error = error
    }
}

/// Webhook event types for different operations
public enum WebhookEventType: String, CaseIterable, Codable, Sendable {
    // Crawl events
    case crawlStarted = "crawl.started"
    case crawlPage = "crawl.page"
    case crawlCompleted = "crawl.completed"
    case crawlFailed = "crawl.failed"

    // Batch scrape events
    case batchScrapeStarted = "batch.scrape.started"
    case batchScrapePage = "batch.scrape.page"
    case batchScrapeCompleted = "batch.scrape.completed"
    case batchScrapeFailed = "batch.scrape.failed"

    // Extract events
    case extractStarted = "extract.started"
    case extractCompleted = "extract.completed"
    case extractFailed = "extract.failed"
}

/// Specialized webhook payload for crawl events
public struct CrawlWebhookPayload: Codable, Sendable {
    public let type: WebhookEventType
    public let data: CrawlWebhookData
    public let metadata: [String: String]?

    public init(type: WebhookEventType, data: CrawlWebhookData, metadata: [String: String]? = nil) {
        self.type = type
        self.data = data
        self.metadata = metadata
    }
}

/// Crawl-specific webhook data
public struct CrawlWebhookData: Codable, Sendable {
    public let jobId: String
    public let url: String?
    public let status: String?
    public let markdown: String?
    public let html: String?
    public let rawHtml: String?
    public let links: [String]?
    public let screenshot: String?
    public let metadata: WebhookPageMetadata?
    public let total: Int?
    public let completed: Int?
    public let creditsUsed: Int?
    public let error: String?

    public init(
        jobId: String,
        url: String? = nil,
        status: String? = nil,
        markdown: String? = nil,
        html: String? = nil,
        rawHtml: String? = nil,
        links: [String]? = nil,
        screenshot: String? = nil,
        metadata: WebhookPageMetadata? = nil,
        total: Int? = nil,
        completed: Int? = nil,
        creditsUsed: Int? = nil,
        error: String? = nil
    ) {
        self.jobId = jobId
        self.url = url
        self.status = status
        self.markdown = markdown
        self.html = html
        self.rawHtml = rawHtml
        self.links = links
        self.screenshot = screenshot
        self.metadata = metadata
        self.total = total
        self.completed = completed
        self.creditsUsed = creditsUsed
        self.error = error
    }
}

/// Specialized webhook payload for batch scrape events
public struct BatchScrapeWebhookPayload: Codable, Sendable {
    public let type: WebhookEventType
    public let data: BatchScrapeWebhookData
    public let metadata: [String: String]?

    public init(
        type: WebhookEventType, data: BatchScrapeWebhookData, metadata: [String: String]? = nil
    ) {
        self.type = type
        self.data = data
        self.metadata = metadata
    }
}

/// Batch scrape-specific webhook data
public struct BatchScrapeWebhookData: Codable, Sendable {
    public let jobId: String
    public let url: String?
    public let status: String?
    public let markdown: String?
    public let html: String?
    public let rawHtml: String?
    public let links: [String]?
    public let screenshot: String?
    public let metadata: WebhookPageMetadata?
    public let total: Int?
    public let completed: Int?
    public let creditsUsed: Int?
    public let error: String?

    public init(
        jobId: String,
        url: String? = nil,
        status: String? = nil,
        markdown: String? = nil,
        html: String? = nil,
        rawHtml: String? = nil,
        links: [String]? = nil,
        screenshot: String? = nil,
        metadata: WebhookPageMetadata? = nil,
        total: Int? = nil,
        completed: Int? = nil,
        creditsUsed: Int? = nil,
        error: String? = nil
    ) {
        self.jobId = jobId
        self.url = url
        self.status = status
        self.markdown = markdown
        self.html = html
        self.rawHtml = rawHtml
        self.links = links
        self.screenshot = screenshot
        self.metadata = metadata
        self.total = total
        self.completed = completed
        self.creditsUsed = creditsUsed
        self.error = error
    }
}

/// Response from the crawl endpoint (initial response)
public struct CrawlResponse: FirecrawlResponse, Sendable {
    public let success: Bool
    public let id: String?
    public let url: String?

    public init(success: Bool, id: String? = nil, url: String? = nil) {
        self.success = success
        self.id = id
        self.url = url
    }
}

/// Status response for checking crawl progress
public struct CrawlStatusResponse: Codable, Sendable {
    public let status: JobStatus
    public let total: Int?
    public let completed: Int?
    public let creditsUsed: Int?
    public let expiresAt: String?
    public let next: String?
    public let data: [CrawlResult]?

    public init(
        status: JobStatus,
        total: Int? = nil,
        completed: Int? = nil,
        creditsUsed: Int? = nil,
        expiresAt: String? = nil,
        next: String? = nil,
        data: [CrawlResult]? = nil
    ) {
        self.status = status
        self.total = total
        self.completed = completed
        self.creditsUsed = creditsUsed
        self.expiresAt = expiresAt
        self.next = next
        self.data = data
    }

    enum CodingKeys: String, CodingKey {
        case status
        case total
        case completed
        case creditsUsed
        case expiresAt
        case next
        case data
    }
}

/// Individual page result from a crawl
public struct CrawlResult: Codable, Sendable {
    /// The scraped content in markdown format
    public let markdown: String?

    /// The scraped content in summary format
    public let summary: String?

    /// The scraped content in HTML format
    public let html: String?

    /// The scraped content in raw HTML format
    public let rawHtml: String?

    /// Screenshot URL if requested
    public let screenshot: String?

    /// Extracted links from the page
    public let links: [String]?

    /// Results of actions if actions were specified
    public let actions: ActionResults?

    /// Change tracking information if requested
    public let changeTracking: ChangeTrackingInfo?

    /// Branding information if requested
    public let branding: String?

    /// Metadata about the crawled page
    public let metadata: ScrapeMetadata?

    /// Any warnings encountered during crawling this page
    public let warning: String?

    public init(
        markdown: String? = nil,
        summary: String? = nil,
        html: String? = nil,
        rawHtml: String? = nil,
        screenshot: String? = nil,
        links: [String]? = nil,
        actions: ActionResults? = nil,
        changeTracking: ChangeTrackingInfo? = nil,
        branding: String? = nil,
        metadata: ScrapeMetadata? = nil,
        warning: String? = nil
    ) {
        self.markdown = markdown
        self.summary = summary
        self.html = html
        self.rawHtml = rawHtml
        self.screenshot = screenshot
        self.links = links
        self.actions = actions
        self.changeTracking = changeTracking
        self.branding = branding
        self.metadata = metadata
        self.warning = warning
    }
}

/// Request to cancel a crawl job
public struct CrawlCancelRequest: Codable, Sendable {
    /// The crawl job ID to cancel
    public let id: String

    public init(id: String) {
        self.id = id
    }
}

/// Response from canceling a crawl job
public struct CrawlCancelResponse: Codable, Sendable {
    public let status: String

    public init(status: String) {
        self.status = status
    }
}

/// Request for crawl params preview endpoint
public struct CrawlParamsPreviewRequest: Codable, Sendable {
    /// The URL to crawl
    public let url: String

    /// Natural language prompt describing what you want to crawl
    public let prompt: String

    public init(url: String, prompt: String) {
        self.url = url
        self.prompt = prompt
    }
}

/// Response from crawl params preview endpoint
public struct CrawlParamsPreviewResponse: FirecrawlResponse, Sendable {
    public let success: Bool
    public let data: CrawlParamsPreviewData?

    public init(success: Bool, data: CrawlParamsPreviewData? = nil) {
        self.success = success
        self.data = data
    }
}

/// Generated crawl parameters data
public struct CrawlParamsPreviewData: Codable, Sendable {
    /// The URL to crawl
    public let url: String

    /// URL patterns to include
    public let includePaths: [String]?

    /// URL patterns to exclude
    public let excludePaths: [String]?

    /// Maximum crawl depth
    public let maxDepth: Int?

    /// Maximum discovery depth
    public let maxDiscoveryDepth: Int?

    /// Whether to crawl the entire domain
    public let crawlEntireDomain: Bool?

    /// Whether to allow external links
    public let allowExternalLinks: Bool?

    /// Whether to allow subdomains
    public let allowSubdomains: Bool?

    /// Sitemap handling strategy
    public let sitemap: String?

    /// Whether to ignore query parameters
    public let ignoreQueryParameters: Bool?

    /// Whether to deduplicate similar URLs
    public let deduplicateSimilarURLs: Bool?

    /// Delay between requests in milliseconds
    public let delay: Double?

    /// Maximum number of pages to crawl
    public let limit: Int?

    public init(
        url: String,
        includePaths: [String]? = nil,
        excludePaths: [String]? = nil,
        maxDepth: Int? = nil,
        maxDiscoveryDepth: Int? = nil,
        crawlEntireDomain: Bool? = nil,
        allowExternalLinks: Bool? = nil,
        allowSubdomains: Bool? = nil,
        sitemap: String? = nil,
        ignoreQueryParameters: Bool? = nil,
        deduplicateSimilarURLs: Bool? = nil,
        delay: Double? = nil,
        limit: Int? = nil
    ) {
        self.url = url
        self.includePaths = includePaths
        self.excludePaths = excludePaths
        self.maxDepth = maxDepth
        self.maxDiscoveryDepth = maxDiscoveryDepth
        self.crawlEntireDomain = crawlEntireDomain
        self.allowExternalLinks = allowExternalLinks
        self.allowSubdomains = allowSubdomains
        self.sitemap = sitemap
        self.ignoreQueryParameters = ignoreQueryParameters
        self.deduplicateSimilarURLs = deduplicateSimilarURLs
        self.delay = delay
        self.limit = limit
    }
}

/// Request for crawl errors endpoint
public struct CrawlErrorsResponse: Codable, Sendable {
    /// Errored scrape jobs and error details
    public let errors: [CrawlError]?

    /// List of URLs that were blocked by robots.txt
    public let robotsBlocked: [String]?

    public init(errors: [CrawlError]? = nil, robotsBlocked: [String]? = nil) {
        self.errors = errors
        self.robotsBlocked = robotsBlocked
    }
}

/// Individual crawl error details
public struct CrawlError: Codable, Sendable {
    public let id: String?
    public let timestamp: String?
    public let url: String
    public let error: String

    public init(id: String? = nil, timestamp: String? = nil, url: String, error: String) {
        self.id = id
        self.timestamp = timestamp
        self.url = url
        self.error = error
    }
}

/// Response from active crawls endpoint
public struct ActiveCrawlsResponse: FirecrawlResponse, Sendable {
    public let success: Bool
    public let crawls: [ActiveCrawl]?

    public init(success: Bool, crawls: [ActiveCrawl]? = nil) {
        self.success = success
        self.crawls = crawls
    }
}

/// Individual active crawl information
public struct ActiveCrawl: Codable, Sendable {
    public let id: String
    public let teamId: String
    public let url: String
    public let options: ActiveCrawlOptions

    public init(id: String, teamId: String, url: String, options: ActiveCrawlOptions) {
        self.id = id
        self.teamId = teamId
        self.url = url
        self.options = options
    }
}

/// Options for active crawls
public struct ActiveCrawlOptions: Codable, Sendable {
    public let scrapeOptions: CrawlScrapeOptions?

    public init(scrapeOptions: CrawlScrapeOptions? = nil) {
        self.scrapeOptions = scrapeOptions
    }
}
