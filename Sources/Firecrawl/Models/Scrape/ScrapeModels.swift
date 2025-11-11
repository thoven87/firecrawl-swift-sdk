import Foundation

/// Request parameters for scraping a single URL
public struct ScrapeRequest: Codable, Sendable {
    /// The URL to scrape
    public let url: String

    /// Formats to extract
    public let formats: [Format]?

    /// Only return the main content of the page excluding headers, navs, footers, etc.
    public let onlyMainContent: Bool?

    /// Tags to include in the output
    public let includeTags: [String]?

    /// Tags to exclude from the output
    public let excludeTags: [String]?

    /// Returns a cached version of the page if it is younger than this age in milliseconds
    public let maxAge: Int?

    /// Headers to send with the request
    public let headers: [String: String]?

    /// Delay in milliseconds before fetching the content
    public let waitFor: Int?

    /// Set to true to emulate scraping from a mobile device
    public let mobile: Bool?

    /// Skip TLS certificate verification when making requests
    public let skipTlsVerification: Bool?

    /// Timeout in milliseconds for the request
    public let timeout: Int?

    /// Controls how files are processed during scraping
    public let parsers: [Parser]?

    /// Actions to perform on the page before grabbing the content
    public let actions: [ScrapeAction]?

    /// Location settings for the request
    public let location: LocationSettings?

    /// Removes all base64 images from the output
    public let removeBase64Images: Bool?

    /// Enables ad-blocking and cookie popup blocking
    public let blockAds: Bool?

    /// Specifies the type of proxy to use
    public let proxy: ProxyType?

    /// Whether the page will be stored in the Firecrawl index and cache
    public let storeInCache: Bool?

    /// Enables zero data retention for this scrape
    public let zeroDataRetention: Bool?

    public init(
        url: String,
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
        storeInCache: Bool? = nil,
        zeroDataRetention: Bool? = nil
    ) {
        self.url = url
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
        self.zeroDataRetention = zeroDataRetention
    }

    enum CodingKeys: String, CodingKey {
        case url
        case formats
        case onlyMainContent
        case includeTags
        case excludeTags
        case maxAge
        case headers
        case waitFor
        case mobile
        case skipTlsVerification
        case timeout
        case parsers
        case actions
        case location
        case removeBase64Images
        case blockAds
        case proxy
        case storeInCache
        case zeroDataRetention
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(url, forKey: .url)

        if let formats = formats {
            let formatsString = formats.map(\.rawValue).joined(separator: ",")
            try container.encode(formatsString, forKey: .formats)
        }

        try container.encodeIfPresent(onlyMainContent, forKey: .onlyMainContent)
        try container.encodeIfPresent(includeTags, forKey: .includeTags)
        try container.encodeIfPresent(excludeTags, forKey: .excludeTags)
        try container.encodeIfPresent(maxAge, forKey: .maxAge)
        try container.encodeIfPresent(headers, forKey: .headers)
        try container.encodeIfPresent(waitFor, forKey: .waitFor)
        try container.encodeIfPresent(mobile, forKey: .mobile)
        try container.encodeIfPresent(skipTlsVerification, forKey: .skipTlsVerification)
        try container.encodeIfPresent(timeout, forKey: .timeout)
        try container.encodeIfPresent(parsers, forKey: .parsers)
        try container.encodeIfPresent(actions, forKey: .actions)
        try container.encodeIfPresent(location, forKey: .location)
        try container.encodeIfPresent(removeBase64Images, forKey: .removeBase64Images)
        try container.encodeIfPresent(blockAds, forKey: .blockAds)
        try container.encodeIfPresent(proxy, forKey: .proxy)
        try container.encodeIfPresent(storeInCache, forKey: .storeInCache)
        try container.encodeIfPresent(zeroDataRetention, forKey: .zeroDataRetention)
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        url = try container.decode(String.self, forKey: .url)

        if let formatsString = try container.decodeIfPresent(String.self, forKey: .formats) {
            formats = formatsString.split(separator: ",").compactMap {
                Format(rawValue: String($0))
            }
        } else {
            formats = nil
        }

        onlyMainContent = try container.decodeIfPresent(Bool.self, forKey: .onlyMainContent)
        includeTags = try container.decodeIfPresent([String].self, forKey: .includeTags)
        excludeTags = try container.decodeIfPresent([String].self, forKey: .excludeTags)
        maxAge = try container.decodeIfPresent(Int.self, forKey: .maxAge)
        headers = try container.decodeIfPresent([String: String].self, forKey: .headers)
        waitFor = try container.decodeIfPresent(Int.self, forKey: .waitFor)
        mobile = try container.decodeIfPresent(Bool.self, forKey: .mobile)
        skipTlsVerification = try container.decodeIfPresent(Bool.self, forKey: .skipTlsVerification)
        timeout = try container.decodeIfPresent(Int.self, forKey: .timeout)
        parsers = try container.decodeIfPresent([Parser].self, forKey: .parsers)
        actions = try container.decodeIfPresent([ScrapeAction].self, forKey: .actions)
        location = try container.decodeIfPresent(LocationSettings.self, forKey: .location)
        removeBase64Images = try container.decodeIfPresent(Bool.self, forKey: .removeBase64Images)
        blockAds = try container.decodeIfPresent(Bool.self, forKey: .blockAds)
        proxy = try container.decodeIfPresent(ProxyType.self, forKey: .proxy)
        storeInCache = try container.decodeIfPresent(Bool.self, forKey: .storeInCache)
        zeroDataRetention = try container.decodeIfPresent(Bool.self, forKey: .zeroDataRetention)
    }
}

/// Parser options for file processing
public enum Parser: Codable, Sendable {
    case pdf
    case pdfWithOptions(maxPages: Int)

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        if let stringValue = try? container.decode(String.self) {
            if stringValue == "pdf" {
                self = .pdf
            } else {
                throw DecodingError.dataCorruptedError(
                    in: container, debugDescription: "Unknown parser type: \(stringValue)")
            }
        } else if let objectContainer = try? decoder.container(keyedBy: CodingKeys.self) {
            let type = try objectContainer.decode(String.self, forKey: .type)
            if type == "pdf" {
                let maxPages = try objectContainer.decode(Int.self, forKey: .maxPages)
                self = .pdfWithOptions(maxPages: maxPages)
            } else {
                throw DecodingError.dataCorruptedError(
                    forKey: .type, in: objectContainer,
                    debugDescription: "Unknown parser type: \(type)")
            }
        } else {
            throw DecodingError.dataCorruptedError(
                in: container, debugDescription: "Unable to decode Parser")
        }
    }

    public func encode(to encoder: Encoder) throws {
        switch self {
        case .pdf:
            var container = encoder.singleValueContainer()
            try container.encode("pdf")
        case .pdfWithOptions(let maxPages):
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode("pdf", forKey: .type)
            try container.encode(maxPages, forKey: .maxPages)
        }
    }

    private enum CodingKeys: String, CodingKey {
        case type
        case maxPages
    }
}

/// Actions that can be performed on a page before scraping
public enum ScrapeAction: Codable, Sendable {
    case wait(milliseconds: Int, selector: String?)
    case screenshot(fullPage: Bool?, quality: Int?, viewport: Viewport?)
    case click(selector: String, all: Bool?)
    case write(text: String)
    case press(key: String)
    case scroll(direction: ScrollDirection?, selector: String?)
    case scrape
    case executeJavascript(script: String)
    case pdf(format: PDFFormat?, landscape: Bool?, scale: Double?)

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)

        switch type {
        case "wait":
            let milliseconds = try container.decode(Int.self, forKey: .milliseconds)
            let selector = try container.decodeIfPresent(String.self, forKey: .selector)
            self = .wait(milliseconds: milliseconds, selector: selector)

        case "screenshot":
            let fullPage = try container.decodeIfPresent(Bool.self, forKey: .fullPage)
            let quality = try container.decodeIfPresent(Int.self, forKey: .quality)
            let viewport = try container.decodeIfPresent(Viewport.self, forKey: .viewport)
            self = .screenshot(fullPage: fullPage, quality: quality, viewport: viewport)

        case "click":
            let selector = try container.decode(String.self, forKey: .selector)
            let all = try container.decodeIfPresent(Bool.self, forKey: .all)
            self = .click(selector: selector, all: all)

        case "write":
            let text = try container.decode(String.self, forKey: .text)
            self = .write(text: text)

        case "press":
            let key = try container.decode(String.self, forKey: .key)
            self = .press(key: key)

        case "scroll":
            let direction = try container.decodeIfPresent(ScrollDirection.self, forKey: .direction)
            let selector = try container.decodeIfPresent(String.self, forKey: .selector)
            self = .scroll(direction: direction, selector: selector)

        case "scrape":
            self = .scrape

        case "executeJavascript":
            let script = try container.decode(String.self, forKey: .script)
            self = .executeJavascript(script: script)

        case "pdf":
            let format = try container.decodeIfPresent(PDFFormat.self, forKey: .format)
            let landscape = try container.decodeIfPresent(Bool.self, forKey: .landscape)
            let scale = try container.decodeIfPresent(Double.self, forKey: .scale)
            self = .pdf(format: format, landscape: landscape, scale: scale)

        default:
            throw DecodingError.dataCorruptedError(
                forKey: .type, in: container, debugDescription: "Unknown action type: \(type)")
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        switch self {
        case .wait(let milliseconds, let selector):
            try container.encode("wait", forKey: .type)
            try container.encode(milliseconds, forKey: .milliseconds)
            try container.encodeIfPresent(selector, forKey: .selector)

        case .screenshot(let fullPage, let quality, let viewport):
            try container.encode("screenshot", forKey: .type)
            try container.encodeIfPresent(fullPage, forKey: .fullPage)
            try container.encodeIfPresent(quality, forKey: .quality)
            try container.encodeIfPresent(viewport, forKey: .viewport)

        case .click(let selector, let all):
            try container.encode("click", forKey: .type)
            try container.encode(selector, forKey: .selector)
            try container.encodeIfPresent(all, forKey: .all)

        case .write(let text):
            try container.encode("write", forKey: .type)
            try container.encode(text, forKey: .text)

        case .press(let key):
            try container.encode("press", forKey: .type)
            try container.encode(key, forKey: .key)

        case .scroll(let direction, let selector):
            try container.encode("scroll", forKey: .type)
            try container.encodeIfPresent(direction, forKey: .direction)
            try container.encodeIfPresent(selector, forKey: .selector)

        case .scrape:
            try container.encode("scrape", forKey: .type)

        case .executeJavascript(let script):
            try container.encode("executeJavascript", forKey: .type)
            try container.encode(script, forKey: .script)

        case .pdf(let format, let landscape, let scale):
            try container.encode("pdf", forKey: .type)
            try container.encodeIfPresent(format, forKey: .format)
            try container.encodeIfPresent(landscape, forKey: .landscape)
            try container.encodeIfPresent(scale, forKey: .scale)
        }
    }

    private enum CodingKeys: String, CodingKey {
        case type
        case milliseconds
        case selector
        case fullPage
        case quality
        case viewport
        case all
        case text
        case key
        case direction
        case script
        case format
        case landscape
        case scale
    }
}

/// Viewport configuration for screenshots
public struct Viewport: Codable, Sendable {
    /// The width of the viewport in pixels
    public let width: Int

    /// The height of the viewport in pixels
    public let height: Int

    public init(width: Int, height: Int) {
        self.width = width
        self.height = height
    }
}

/// Scroll direction enumeration
public enum ScrollDirection: String, Codable, CaseIterable, Sendable {
    case up
    case down
}

/// PDF format options
public enum PDFFormat: String, Codable, CaseIterable, Sendable {
    case A0, A1, A2, A3, A4, A5, A6
    case Letter, Legal, Tabloid, Ledger
}

/// Location settings for scraping
public struct LocationSettings: Codable, Sendable {
    /// ISO 3166-1 alpha-2 country code
    public let country: String

    /// Preferred languages and locales
    public let languages: [String]?

    public init(country: String, languages: [String]? = nil) {
        self.country = country
        self.languages = languages
    }
}

/// Proxy type enumeration
public enum ProxyType: String, Codable, CaseIterable, Sendable {
    case basic
    case stealth
    case auto
}

/// Response from the scrape endpoint
public struct ScrapeResponse: FirecrawlResponse, Sendable {
    public let success: Bool
    public let data: ScrapeData?

    public init(success: Bool, data: ScrapeData? = nil) {
        self.success = success
        self.data = data
    }
}

/// Data returned from a successful scrape
public struct ScrapeData: Codable, Sendable {
    /// Markdown content
    public let markdown: String?

    /// Summary of the page if `summary` is in formats
    public let summary: String?

    /// HTML version of the content if `html` is in formats
    public let html: String?

    /// Raw HTML content if `rawHtml` is in formats
    public let rawHtml: String?

    /// Screenshot URL if `screenshot` is in formats
    public let screenshot: String?

    /// List of links if `links` is in formats
    public let links: [String]?

    /// Results of actions if actions were specified
    public let actions: ActionResults?

    /// Metadata about the scraped page
    public let metadata: ScrapeMetadata?

    /// Warning message if any issues occurred
    public let warning: String?

    /// Change tracking information if requested
    public let changeTracking: ChangeTrackingInfo?

    /// Branding information if requested
    public let branding: JSONValue?

    public init(
        markdown: String? = nil,
        summary: String? = nil,
        html: String? = nil,
        rawHtml: String? = nil,
        screenshot: String? = nil,
        links: [String]? = nil,
        actions: ActionResults? = nil,
        metadata: ScrapeMetadata? = nil,
        warning: String? = nil,
        changeTracking: ChangeTrackingInfo? = nil,
        branding: JSONValue? = nil
    ) {
        self.markdown = markdown
        self.summary = summary
        self.html = html
        self.rawHtml = rawHtml
        self.screenshot = screenshot
        self.links = links
        self.actions = actions
        self.metadata = metadata
        self.warning = warning
        self.changeTracking = changeTracking
        self.branding = branding
    }
}

/// Results of actions performed on the page
public struct ActionResults: Codable, Sendable {
    /// Screenshot URLs in order of screenshot actions
    public let screenshots: [String]?

    /// Scrape contents in order of scrape actions
    public let scrapes: [ScrapeResult]?

    /// JavaScript return values in order of executeJavascript actions
    public let javascriptReturns: [JavaScriptReturn]?

    /// Generated PDFs in order of pdf actions
    public let pdfs: [String]?

    public init(
        screenshots: [String]? = nil,
        scrapes: [ScrapeResult]? = nil,
        javascriptReturns: [JavaScriptReturn]? = nil,
        pdfs: [String]? = nil
    ) {
        self.screenshots = screenshots
        self.scrapes = scrapes
        self.javascriptReturns = javascriptReturns
        self.pdfs = pdfs
    }
}

/// Result of a scrape action
public struct ScrapeResult: Codable, Sendable {
    public let url: String
    public let html: String

    public init(url: String, html: String) {
        self.url = url
        self.html = html
    }
}

/// JavaScript execution return value
public struct JavaScriptReturn: Codable, Sendable {
    public let type: String
    public let value: JSONValue

    public init(type: String, value: JSONValue) {
        self.type = type
        self.value = value
    }
}

/// Metadata extracted from the scraped page
public struct ScrapeMetadata: Codable, Sendable {
    /// Title extracted from the page
    public let title: MetadataValue?

    /// Description extracted from the page
    public let description: MetadataValue?

    /// Language extracted from the page
    public let language: MetadataValue?

    /// Source URL
    public let sourceURL: String?

    /// Keywords extracted from the page
    public let keywords: MetadataValue?

    /// Alternative locales for the page
    public let ogLocaleAlternate: [String]?

    /// The status code of the page
    public let statusCode: Int?

    /// Error message if any
    public let error: String?

    public init(
        title: MetadataValue? = nil,
        description: MetadataValue? = nil,
        language: MetadataValue? = nil,
        sourceURL: String? = nil,
        keywords: MetadataValue? = nil,
        ogLocaleAlternate: [String]? = nil,
        statusCode: Int? = nil,
        error: String? = nil
    ) {
        self.title = title
        self.description = description
        self.language = language
        self.sourceURL = sourceURL
        self.keywords = keywords
        self.ogLocaleAlternate = ogLocaleAlternate
        self.statusCode = statusCode
        self.error = error
    }
}

/// Metadata value that can be string or array of strings
public enum MetadataValue: Codable, Sendable {
    case string(String)
    case array([String])

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        if let stringValue = try? container.decode(String.self) {
            self = .string(stringValue)
        } else if let arrayValue = try? container.decode([String].self) {
            self = .array(arrayValue)
        } else {
            throw DecodingError.typeMismatch(
                MetadataValue.self,
                DecodingError.Context(
                    codingPath: decoder.codingPath,
                    debugDescription: "Expected String or [String]"
                )
            )
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()

        switch self {
        case .string(let value):
            try container.encode(value)
        case .array(let values):
            try container.encode(values)
        }
    }
}

/// Change tracking information
public struct ChangeTrackingInfo: Codable, Sendable {
    /// Timestamp of the previous scrape
    public let previousScrapeAt: String?

    /// Result of the comparison
    public let changeStatus: ChangeStatus

    /// Visibility of the current page
    public let visibility: VisibilityStatus

    /// Git-style diff when using 'git-diff' mode
    public let diff: String?

    /// JSON comparison results when using 'json' mode
    public let json: JSONValue?

    public init(
        previousScrapeAt: String? = nil,
        changeStatus: ChangeStatus,
        visibility: VisibilityStatus,
        diff: String? = nil,
        json: JSONValue? = nil
    ) {
        self.previousScrapeAt = previousScrapeAt
        self.changeStatus = changeStatus
        self.visibility = visibility
        self.diff = diff
        self.json = json
    }
}

/// Change status enumeration
public enum ChangeStatus: String, Codable, CaseIterable, Sendable {
    case new
    case same
    case changed
    case removed
}

/// Visibility status enumeration
public enum VisibilityStatus: String, Codable, CaseIterable, Sendable {
    case visible
    case hidden
}

// MARK: - Batch Scrape Models

/// Webhook configuration for batch scrape
public struct BatchWebhook: Codable, Sendable {
    /// The URL to send the webhook to
    public let url: String

    /// Headers to send to the webhook URL
    public let headers: [String: String]?

    /// Custom metadata included in all webhook payloads
    public let metadata: [String: JSONValue]?

    /// Type of events that should be sent to the webhook URL
    public let events: [WebhookEvent]?

    public init(
        url: String,
        headers: [String: String]? = nil,
        metadata: [String: JSONValue]? = nil,
        events: [WebhookEvent]? = nil
    ) {
        self.url = url
        self.headers = headers
        self.metadata = metadata
        self.events = events
    }
}

/// Webhook event types
public enum WebhookEvent: String, Codable, CaseIterable, Sendable {
    case completed
    case page
    case failed
    case started
}

/// Request parameters for batch scraping multiple URLs
public struct BatchScrapeRequest: Codable, Sendable {
    /// The URLs to scrape
    public let urls: [String]

    /// Webhook specification
    public let webhook: BatchWebhook?

    /// Maximum number of concurrent scrapes
    public let maxConcurrency: Int?

    /// Whether to ignore invalid URLs
    public let ignoreInvalidURLs: Bool?

    /// Formats to extract
    public let formats: [Format]?

    /// Only return the main content of the page excluding headers, navs, footers, etc.
    public let onlyMainContent: Bool?

    /// Tags to include in the output
    public let includeTags: [String]?

    /// Tags to exclude from the output
    public let excludeTags: [String]?

    /// Returns a cached version of the page if it is younger than this age in milliseconds
    public let maxAge: Int?

    /// Headers to send with the request
    public let headers: [String: String]?

    /// Delay in milliseconds before fetching the content
    public let waitFor: Int?

    /// Set to true to emulate scraping from a mobile device
    public let mobile: Bool?

    /// Skip TLS certificate verification when making requests
    public let skipTlsVerification: Bool?

    /// Timeout in milliseconds for the request
    public let timeout: Int?

    /// Controls how files are processed during scraping
    public let parsers: [Parser]?

    /// Actions to perform on the page before grabbing the content
    public let actions: [ScrapeAction]?

    /// Location settings for the request
    public let location: LocationSettings?

    /// Removes all base64 images from the output
    public let removeBase64Images: Bool?

    /// Enables ad-blocking and cookie popup blocking
    public let blockAds: Bool?

    /// Specifies the type of proxy to use
    public let proxy: ProxyType?

    /// Whether the page will be stored in the Firecrawl index and cache
    public let storeInCache: Bool?

    /// Enables zero data retention for this batch scrape
    public let zeroDataRetention: Bool?

    public init(
        urls: [String],
        webhook: BatchWebhook? = nil,
        maxConcurrency: Int? = nil,
        ignoreInvalidURLs: Bool? = nil,
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
        storeInCache: Bool? = nil,
        zeroDataRetention: Bool? = nil
    ) {
        self.urls = urls
        self.webhook = webhook
        self.maxConcurrency = maxConcurrency
        self.ignoreInvalidURLs = ignoreInvalidURLs
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
        self.zeroDataRetention = zeroDataRetention
    }

    enum CodingKeys: String, CodingKey {
        case urls
        case webhook
        case maxConcurrency
        case ignoreInvalidURLs
        case formats
        case onlyMainContent
        case includeTags
        case excludeTags
        case maxAge
        case headers
        case waitFor
        case mobile
        case skipTlsVerification
        case timeout
        case parsers
        case actions
        case location
        case removeBase64Images
        case blockAds
        case proxy
        case storeInCache
        case zeroDataRetention
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(urls, forKey: .urls)
        try container.encodeIfPresent(webhook, forKey: .webhook)
        try container.encodeIfPresent(maxConcurrency, forKey: .maxConcurrency)
        try container.encodeIfPresent(ignoreInvalidURLs, forKey: .ignoreInvalidURLs)

        if let formats = formats {
            let formatsString = formats.map(\.rawValue).joined(separator: ",")
            try container.encode(formatsString, forKey: .formats)
        }

        try container.encodeIfPresent(onlyMainContent, forKey: .onlyMainContent)
        try container.encodeIfPresent(includeTags, forKey: .includeTags)
        try container.encodeIfPresent(excludeTags, forKey: .excludeTags)
        try container.encodeIfPresent(maxAge, forKey: .maxAge)
        try container.encodeIfPresent(headers, forKey: .headers)
        try container.encodeIfPresent(waitFor, forKey: .waitFor)
        try container.encodeIfPresent(mobile, forKey: .mobile)
        try container.encodeIfPresent(skipTlsVerification, forKey: .skipTlsVerification)
        try container.encodeIfPresent(timeout, forKey: .timeout)
        try container.encodeIfPresent(parsers, forKey: .parsers)
        try container.encodeIfPresent(actions, forKey: .actions)
        try container.encodeIfPresent(location, forKey: .location)
        try container.encodeIfPresent(removeBase64Images, forKey: .removeBase64Images)
        try container.encodeIfPresent(blockAds, forKey: .blockAds)
        try container.encodeIfPresent(proxy, forKey: .proxy)
        try container.encodeIfPresent(storeInCache, forKey: .storeInCache)
        try container.encodeIfPresent(zeroDataRetention, forKey: .zeroDataRetention)
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        urls = try container.decode([String].self, forKey: .urls)
        webhook = try container.decodeIfPresent(BatchWebhook.self, forKey: .webhook)
        maxConcurrency = try container.decodeIfPresent(Int.self, forKey: .maxConcurrency)
        ignoreInvalidURLs = try container.decodeIfPresent(Bool.self, forKey: .ignoreInvalidURLs)

        if let formatsString = try container.decodeIfPresent(String.self, forKey: .formats) {
            formats = formatsString.split(separator: ",").compactMap {
                Format(rawValue: String($0))
            }
        } else {
            formats = nil
        }

        onlyMainContent = try container.decodeIfPresent(Bool.self, forKey: .onlyMainContent)
        includeTags = try container.decodeIfPresent([String].self, forKey: .includeTags)
        excludeTags = try container.decodeIfPresent([String].self, forKey: .excludeTags)
        maxAge = try container.decodeIfPresent(Int.self, forKey: .maxAge)
        headers = try container.decodeIfPresent([String: String].self, forKey: .headers)
        waitFor = try container.decodeIfPresent(Int.self, forKey: .waitFor)
        mobile = try container.decodeIfPresent(Bool.self, forKey: .mobile)
        skipTlsVerification = try container.decodeIfPresent(Bool.self, forKey: .skipTlsVerification)
        timeout = try container.decodeIfPresent(Int.self, forKey: .timeout)
        parsers = try container.decodeIfPresent([Parser].self, forKey: .parsers)
        actions = try container.decodeIfPresent([ScrapeAction].self, forKey: .actions)
        location = try container.decodeIfPresent(LocationSettings.self, forKey: .location)
        removeBase64Images = try container.decodeIfPresent(Bool.self, forKey: .removeBase64Images)
        blockAds = try container.decodeIfPresent(Bool.self, forKey: .blockAds)
        proxy = try container.decodeIfPresent(ProxyType.self, forKey: .proxy)
        storeInCache = try container.decodeIfPresent(Bool.self, forKey: .storeInCache)
        zeroDataRetention = try container.decodeIfPresent(Bool.self, forKey: .zeroDataRetention)
    }
}

/// Response from starting a batch scrape
public struct BatchScrapeResponse: FirecrawlResponse, Sendable {
    public let success: Bool
    public let id: String?
    public let url: String?
    public let invalidURLs: [String]?

    public init(
        success: Bool,
        id: String? = nil,
        url: String? = nil,
        invalidURLs: [String]? = nil
    ) {
        self.success = success
        self.id = id
        self.url = url
        self.invalidURLs = invalidURLs
    }
}

/// Status response for checking batch scrape progress
public struct BatchScrapeStatusResponse: FirecrawlResponse, Sendable {
    public let success: Bool
    public let status: JobStatus
    public let total: Int?
    public let completed: Int?
    public let creditsUsed: Int?
    public let expiresAt: String?
    public let next: String?
    public let data: [BatchScrapeResult]?

    public init(
        success: Bool = true,
        status: JobStatus,
        total: Int? = nil,
        completed: Int? = nil,
        creditsUsed: Int? = nil,
        expiresAt: String? = nil,
        next: String? = nil,
        data: [BatchScrapeResult]? = nil
    ) {
        self.success = success
        self.status = status
        self.total = total
        self.completed = completed
        self.creditsUsed = creditsUsed
        self.expiresAt = expiresAt
        self.next = next
        self.data = data
    }
}

/// Individual batch scrape result
public struct BatchScrapeResult: Codable, Sendable {
    /// Markdown content
    public let markdown: String?

    /// HTML content if requested
    public let html: String?

    /// Raw HTML content if requested
    public let rawHtml: String?

    /// List of links if requested
    public let links: [String]?

    /// Screenshot URL if requested
    public let screenshot: String?

    /// Metadata about the scraped page
    public let metadata: ScrapeMetadata?

    public init(
        markdown: String? = nil,
        html: String? = nil,
        rawHtml: String? = nil,
        links: [String]? = nil,
        screenshot: String? = nil,
        metadata: ScrapeMetadata? = nil
    ) {
        self.markdown = markdown
        self.html = html
        self.rawHtml = rawHtml
        self.links = links
        self.screenshot = screenshot
        self.metadata = metadata
    }
}

/// Response from canceling a batch scrape
public struct BatchScrapeCancelResponse: FirecrawlResponse, Sendable {
    public let success: Bool
    public let message: String?

    public init(success: Bool, message: String? = nil) {
        self.success = success
        self.message = message
    }
}

/// Response containing batch scrape errors
public struct BatchScrapeErrorsResponse: FirecrawlResponse, Sendable {
    public let success: Bool
    public let errors: [BatchScrapeError]?
    public let robotsBlocked: [String]?

    public init(
        success: Bool = true, errors: [BatchScrapeError]? = nil, robotsBlocked: [String]? = nil
    ) {
        self.success = success
        self.errors = errors
        self.robotsBlocked = robotsBlocked
    }
}

/// Individual batch scrape error
public struct BatchScrapeError: Codable, Sendable {
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
