import Foundation

/// Request parameters for mapping a website's URLs
public struct MapRequest: Codable, Sendable {
    /// The base URL to start crawling from
    public let url: String

    /// Specify a search query to order the results by relevance
    public let search: String?

    /// Sitemap mode when mapping
    public let sitemap: SitemapMode?

    /// Include subdomains of the website
    public let includeSubdomains: Bool?

    /// Do not return URLs with query parameters
    public let ignoreQueryParameters: Bool?

    /// Maximum number of links to return
    public let limit: Int?

    /// Timeout in milliseconds
    public let timeout: Int?

    /// Location settings for the request
    public let location: LocationSettings?

    public init(
        url: String,
        search: String? = nil,
        sitemap: SitemapMode? = nil,
        includeSubdomains: Bool? = nil,
        ignoreQueryParameters: Bool? = nil,
        limit: Int? = nil,
        timeout: Int? = nil,
        location: LocationSettings? = nil
    ) {
        self.url = url
        self.search = search
        self.sitemap = sitemap
        self.includeSubdomains = includeSubdomains
        self.ignoreQueryParameters = ignoreQueryParameters
        self.limit = limit
        self.timeout = timeout
        self.location = location
    }
}

/// Sitemap mode enumeration
public enum SitemapMode: String, Codable, CaseIterable, Sendable {
    case skip
    case include
    case only
}

/// Response from the map endpoint
public struct MapResponse: FirecrawlResponse, Sendable {
    public let success: Bool
    public let links: [MapLink]?

    public init(success: Bool, links: [MapLink]? = nil) {
        self.success = success
        self.links = links
    }
}

/// Individual link from mapping
public struct MapLink: Codable, Equatable, Sendable {
    /// The URL that was found
    public let url: String

    /// The title of the page, if available
    public let title: String?

    /// A description of the page, if available
    public let description: String?

    public init(
        url: String,
        title: String? = nil,
        description: String? = nil
    ) {
        self.url = url
        self.title = title
        self.description = description
    }
}
