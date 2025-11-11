import Foundation

/// Base response structure for Firecrawl API
public protocol FirecrawlResponse: Codable, Sendable {
    var success: Bool { get }
}

/// Format options for content extraction
public enum Format: String, Codable, CaseIterable, Sendable {
    case markdown
    case summary
    case html
    case rawHtml = "rawHtml"
    case links
    case images
    case screenshot
    case json
    case changeTracking
    case branding

    /// Returns all available formats as a comma-separated string
    public static var allFormatsString: String {
        return allCases.map(\.rawValue).joined(separator: ",")
    }
}

/// Content extraction result
public struct ExtractedContent: Codable, Equatable, Sendable {
    public let markdown: String?
    public let html: String?
    public let rawHtml: String?
    public let text: String?
    public let screenshot: String?
    public let links: [String]?

    enum CodingKeys: String, CodingKey {
        case markdown
        case html
        case rawHtml = "raw-html"
        case text
        case screenshot
        case links
    }

    public init(
        markdown: String? = nil,
        html: String? = nil,
        rawHtml: String? = nil,
        text: String? = nil,
        screenshot: String? = nil,
        links: [String]? = nil
    ) {
        self.markdown = markdown
        self.html = html
        self.rawHtml = rawHtml
        self.text = text
        self.screenshot = screenshot
        self.links = links
    }
}

/// Metadata about a scraped page
public struct PageMetadata: Codable, Equatable, Sendable {
    public let title: String?
    public let description: String?
    public let keywords: String?
    public let robots: String?
    public let ogTitle: String?
    public let ogDescription: String?
    public let ogUrl: String?
    public let ogImage: String?
    public let ogAudio: String?
    public let ogDeterminer: String?
    public let ogLocale: String?
    public let ogLocaleAlternate: [String]?
    public let ogSiteName: String?
    public let ogVideo: String?
    public let dctermsCreated: String?
    public let dctermsType: String?
    public let dctermsLanguage: String?
    public let dctermsIdentifier: String?
    public let dctermsTitle: String?
    public let dctermsSubject: String?
    public let sourceURL: String?
    public let statusCode: Int?
    public let error: String?

    public init(
        title: String? = nil,
        description: String? = nil,
        keywords: String? = nil,
        robots: String? = nil,
        ogTitle: String? = nil,
        ogDescription: String? = nil,
        ogUrl: String? = nil,
        ogImage: String? = nil,
        ogAudio: String? = nil,
        ogDeterminer: String? = nil,
        ogLocale: String? = nil,
        ogLocaleAlternate: [String]? = nil,
        ogSiteName: String? = nil,
        ogVideo: String? = nil,
        dctermsCreated: String? = nil,
        dctermsType: String? = nil,
        dctermsLanguage: String? = nil,
        dctermsIdentifier: String? = nil,
        dctermsTitle: String? = nil,
        dctermsSubject: String? = nil,
        sourceURL: String? = nil,
        statusCode: Int? = nil,
        error: String? = nil
    ) {
        self.title = title
        self.description = description
        self.keywords = keywords
        self.robots = robots
        self.ogTitle = ogTitle
        self.ogDescription = ogDescription
        self.ogUrl = ogUrl
        self.ogImage = ogImage
        self.ogAudio = ogAudio
        self.ogDeterminer = ogDeterminer
        self.ogLocale = ogLocale
        self.ogLocaleAlternate = ogLocaleAlternate
        self.ogSiteName = ogSiteName
        self.ogVideo = ogVideo
        self.dctermsCreated = dctermsCreated
        self.dctermsType = dctermsType
        self.dctermsLanguage = dctermsLanguage
        self.dctermsIdentifier = dctermsIdentifier
        self.dctermsTitle = dctermsTitle
        self.dctermsSubject = dctermsSubject
        self.sourceURL = sourceURL
        self.statusCode = statusCode
        self.error = error
    }
}

/// Warning information
public struct Warning: Codable, Equatable, Sendable {
    public let code: String
    public let message: String
    public let url: String?

    public init(code: String, message: String, url: String? = nil) {
        self.code = code
        self.message = message
        self.url = url
    }
}

/// Job status for async operations
public enum JobStatus: String, Codable, CaseIterable, Sendable {
    case scraping
    case completed
    case failed
    case cancelled

    /// Whether the job is in a final state
    public var isFinal: Bool {
        switch self {
        case .completed, .failed, .cancelled:
            return true
        case .scraping:
            return false
        }
    }
}
