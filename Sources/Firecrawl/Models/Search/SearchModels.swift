import Foundation

/// Request parameters for searching the web
public struct SearchRequest: Codable, Sendable {
    /// The search query
    public let query: String

    /// Maximum number of results to return (1-100, default 5)
    public let limit: Int?

    /// Sources to search
    public let sources: [SearchSource]?

    /// Categories to filter results by
    public let categories: [SearchCategory]?

    /// Time-based search parameter
    public let tbs: String?

    /// Location parameter for search results
    public let location: String?

    /// ISO country code for geo-targeting search results
    public let country: String?

    /// Timeout in milliseconds
    public let timeout: Int?

    /// Excludes invalid URLs from search results
    public let ignoreInvalidURLs: Bool?

    /// Options for scraping search results
    public let scrapeOptions: SearchScrapeOptions?

    public init(
        query: String,
        limit: Int? = nil,
        sources: [SearchSource]? = nil,
        categories: [SearchCategory]? = nil,
        tbs: String? = nil,
        location: String? = nil,
        country: String? = nil,
        timeout: Int? = nil,
        ignoreInvalidURLs: Bool? = nil,
        scrapeOptions: SearchScrapeOptions? = nil
    ) {
        self.query = query
        self.limit = limit
        self.sources = sources
        self.categories = categories
        self.tbs = tbs
        self.location = location
        self.country = country
        self.timeout = timeout
        self.ignoreInvalidURLs = ignoreInvalidURLs
        self.scrapeOptions = scrapeOptions
    }
}

/// Search source types
public enum SearchSource: Codable, Sendable {
    case web(tbs: String? = nil, location: String? = nil)
    case images
    case news

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        switch self {
        case .web(let tbs, let location):
            try container.encode("web", forKey: .type)
            try container.encodeIfPresent(tbs, forKey: .tbs)
            try container.encodeIfPresent(location, forKey: .location)
        case .images:
            try container.encode("images", forKey: .type)
        case .news:
            try container.encode("news", forKey: .type)
        }
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)

        switch type {
        case "web":
            let tbs = try container.decodeIfPresent(String.self, forKey: .tbs)
            let location = try container.decodeIfPresent(String.self, forKey: .location)
            self = .web(tbs: tbs, location: location)
        case "images":
            self = .images
        case "news":
            self = .news
        default:
            throw DecodingError.dataCorrupted(
                DecodingError.Context(
                    codingPath: decoder.codingPath,
                    debugDescription: "Unknown search source type: \(type)")
            )
        }
    }

    enum CodingKeys: String, CodingKey {
        case type
        case tbs
        case location
    }
}

/// Search category types
public enum SearchCategory: Codable, Sendable {
    case github
    case research
    case pdf

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        switch self {
        case .github:
            try container.encode("github", forKey: .type)
        case .research:
            try container.encode("research", forKey: .type)
        case .pdf:
            try container.encode("pdf", forKey: .type)
        }
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)

        switch type {
        case "github":
            self = .github
        case "research":
            self = .research
        case "pdf":
            self = .pdf
        default:
            throw DecodingError.dataCorrupted(
                DecodingError.Context(
                    codingPath: decoder.codingPath,
                    debugDescription: "Unknown search category type: \(type)")
            )
        }
    }

    enum CodingKeys: String, CodingKey {
        case type
    }
}

/// Scrape options for search results
public struct SearchScrapeOptions: Codable, Sendable {
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

/// Response from the search endpoint
public struct SearchResponse: FirecrawlResponse, Sendable {
    public let success: Bool
    public let data: SearchData?
    public let warning: String?

    public init(success: Bool, data: SearchData? = nil, warning: String? = nil) {
        self.success = success
        self.data = data
        self.warning = warning
    }
}

/// Search data containing different types of results
public struct SearchData: Codable, Sendable {
    /// Web search results
    public let web: [WebSearchResult]?

    /// Image search results
    public let images: [ImageSearchResult]?

    /// News search results
    public let news: [NewsSearchResult]?

    public init(
        web: [WebSearchResult]? = nil,
        images: [ImageSearchResult]? = nil,
        news: [NewsSearchResult]? = nil
    ) {
        self.web = web
        self.images = images
        self.news = news
    }
}

/// Web search result
public struct WebSearchResult: Codable, Sendable {
    /// Title from search result
    public let title: String?

    /// Description from search result
    public let description: String?

    /// URL of the search result
    public let url: String?

    /// Markdown content if scraping was requested
    public let markdown: String?

    /// HTML content if requested in formats
    public let html: String?

    /// Raw HTML content if requested in formats
    public let rawHtml: String?

    /// Links found if requested in formats
    public let links: [String]?

    /// Screenshot URL if requested in formats
    public let screenshot: String?

    /// Metadata about the result
    public let metadata: SearchResultMetadata?

    public init(
        title: String? = nil,
        description: String? = nil,
        url: String? = nil,
        markdown: String? = nil,
        html: String? = nil,
        rawHtml: String? = nil,
        links: [String]? = nil,
        screenshot: String? = nil,
        metadata: SearchResultMetadata? = nil
    ) {
        self.title = title
        self.description = description
        self.url = url
        self.markdown = markdown
        self.html = html
        self.rawHtml = rawHtml
        self.links = links
        self.screenshot = screenshot
        self.metadata = metadata
    }
}

/// Image search result
public struct ImageSearchResult: Codable, Sendable {
    /// Title from search result
    public let title: String?

    /// URL of the image
    public let imageUrl: String?

    /// Width of the image
    public let imageWidth: Int?

    /// Height of the image
    public let imageHeight: Int?

    /// URL of the search result
    public let url: String?

    /// Position of the search result
    public let position: Int?

    public init(
        title: String? = nil,
        imageUrl: String? = nil,
        imageWidth: Int? = nil,
        imageHeight: Int? = nil,
        url: String? = nil,
        position: Int? = nil
    ) {
        self.title = title
        self.imageUrl = imageUrl
        self.imageWidth = imageWidth
        self.imageHeight = imageHeight
        self.url = url
        self.position = position
    }
}

/// News search result
public struct NewsSearchResult: Codable, Sendable {
    /// Title of the article
    public let title: String?

    /// Snippet from the article
    public let snippet: String?

    /// URL of the article
    public let url: String?

    /// Date of the article
    public let date: String?

    /// Image URL of the article
    public let imageUrl: String?

    /// Position of the article
    public let position: Int?

    /// Markdown content if scraping was requested
    public let markdown: String?

    /// HTML content if requested in formats
    public let html: String?

    /// Raw HTML content if requested in formats
    public let rawHtml: String?

    /// Links found if requested in formats
    public let links: [String]?

    /// Screenshot URL if requested in formats
    public let screenshot: String?

    /// Metadata about the result
    public let metadata: SearchResultMetadata?

    public init(
        title: String? = nil,
        snippet: String? = nil,
        url: String? = nil,
        date: String? = nil,
        imageUrl: String? = nil,
        position: Int? = nil,
        markdown: String? = nil,
        html: String? = nil,
        rawHtml: String? = nil,
        links: [String]? = nil,
        screenshot: String? = nil,
        metadata: SearchResultMetadata? = nil
    ) {
        self.title = title
        self.snippet = snippet
        self.url = url
        self.date = date
        self.imageUrl = imageUrl
        self.position = position
        self.markdown = markdown
        self.html = html
        self.rawHtml = rawHtml
        self.links = links
        self.screenshot = screenshot
        self.metadata = metadata
    }
}

/// Metadata for search results
public struct SearchResultMetadata: Codable, Sendable {
    public let title: String?
    public let description: String?
    public let sourceURL: String?
    public let statusCode: Int?
    public let error: String?

    public init(
        title: String? = nil,
        description: String? = nil,
        sourceURL: String? = nil,
        statusCode: Int? = nil,
        error: String? = nil
    ) {
        self.title = title
        self.description = description
        self.sourceURL = sourceURL
        self.statusCode = statusCode
        self.error = error
    }
}
