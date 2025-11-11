import Foundation

/// Request parameters for extracting structured data from webpages
public struct ExtractRequest: Codable, Sendable {
    /// The URLs to extract data from (URLs should be in glob format)
    public let urls: [String]

    /// Natural language prompt to guide the extraction process
    public let prompt: String?

    /// Schema definition for the data to extract
    public let schema: ExtractionSchema?

    /// When true, the extraction will use web search to find additional data
    public let enableWebSearch: Bool?

    /// When true, sitemap.xml files will be ignored during website scanning
    public let ignoreSitemap: Bool?

    /// When true, subdomains of the provided URLs will also be scanned
    public let includeSubdomains: Bool?

    /// When true, the sources used to extract the data will be included in the response
    public let showSources: Bool?

    /// Scraping options to use when processing URLs
    public let scrapeOptions: ExtractScrapeOptions?

    /// Whether to ignore invalid URLs
    public let ignoreInvalidURLs: Bool?

    public init(
        urls: [String],
        prompt: String? = nil,
        schema: ExtractionSchema? = nil,
        enableWebSearch: Bool? = nil,
        ignoreSitemap: Bool? = nil,
        includeSubdomains: Bool? = nil,
        showSources: Bool? = nil,
        scrapeOptions: ExtractScrapeOptions? = nil,
        ignoreInvalidURLs: Bool? = nil
    ) {
        self.urls = urls
        self.prompt = prompt
        self.schema = schema
        self.enableWebSearch = enableWebSearch
        self.ignoreSitemap = ignoreSitemap
        self.includeSubdomains = includeSubdomains
        self.showSources = showSources
        self.scrapeOptions = scrapeOptions
        self.ignoreInvalidURLs = ignoreInvalidURLs
    }
}

/// Schema definition for structured data extraction
public struct ExtractionSchema: Codable, Sendable {
    /// Type of the schema (usually "object")
    public let type: String

    /// Properties to extract
    public let properties: [String: SchemaProperty]

    /// Required properties
    public let required: [String]?

    /// Additional properties allowed
    public let additionalProperties: Bool?

    public init(
        type: String = "object",
        properties: [String: SchemaProperty],
        required: [String]? = nil,
        additionalProperties: Bool? = nil
    ) {
        self.type = type
        self.properties = properties
        self.required = required
        self.additionalProperties = additionalProperties
    }

    enum CodingKeys: String, CodingKey {
        case type
        case properties
        case required
        case additionalProperties = "additionalProperties"
    }
}

/// Schema property definition - using indirect to handle recursion
public indirect enum SchemaProperty: Codable, Sendable {
    case string(description: String?, enumValues: [String]?, format: String?, example: String?)
    case number(description: String?, minimum: Double?, maximum: Double?, example: Double?)
    case integer(description: String?, minimum: Double?, maximum: Double?, example: Int?)
    case boolean(description: String?, example: Bool?)
    case array(description: String?, items: SchemaProperty)
    case object(description: String?, properties: [String: SchemaProperty], required: [String]?)

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)
        let description = try container.decodeIfPresent(String.self, forKey: .description)

        switch type {
        case "string":
            let enumValues = try container.decodeIfPresent([String].self, forKey: .enumValues)
            let format = try container.decodeIfPresent(String.self, forKey: .format)
            let example = try container.decodeIfPresent(String.self, forKey: .example)
            self = .string(
                description: description, enumValues: enumValues, format: format, example: example)

        case "number":
            let minimum = try container.decodeIfPresent(Double.self, forKey: .minimum)
            let maximum = try container.decodeIfPresent(Double.self, forKey: .maximum)
            let example = try container.decodeIfPresent(Double.self, forKey: .example)
            self = .number(
                description: description, minimum: minimum, maximum: maximum, example: example)

        case "integer":
            let minimum = try container.decodeIfPresent(Double.self, forKey: .minimum)
            let maximum = try container.decodeIfPresent(Double.self, forKey: .maximum)
            let example = try container.decodeIfPresent(Int.self, forKey: .example)
            self = .integer(
                description: description, minimum: minimum, maximum: maximum, example: example)

        case "boolean":
            let example = try container.decodeIfPresent(Bool.self, forKey: .example)
            self = .boolean(description: description, example: example)

        case "array":
            let items = try container.decode(SchemaProperty.self, forKey: .items)
            self = .array(description: description, items: items)

        case "object":
            let properties = try container.decode(
                [String: SchemaProperty].self, forKey: .properties)
            let required = try container.decodeIfPresent([String].self, forKey: .required)
            self = .object(description: description, properties: properties, required: required)

        default:
            throw DecodingError.dataCorrupted(
                DecodingError.Context(
                    codingPath: decoder.codingPath,
                    debugDescription: "Unknown schema property type: \(type)"
                )
            )
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        switch self {
        case .string(let description, let enumValues, let format, let example):
            try container.encode("string", forKey: .type)
            try container.encodeIfPresent(description, forKey: .description)
            try container.encodeIfPresent(enumValues, forKey: .enumValues)
            try container.encodeIfPresent(format, forKey: .format)
            try container.encodeIfPresent(example, forKey: .example)

        case .number(let description, let minimum, let maximum, let example):
            try container.encode("number", forKey: .type)
            try container.encodeIfPresent(description, forKey: .description)
            try container.encodeIfPresent(minimum, forKey: .minimum)
            try container.encodeIfPresent(maximum, forKey: .maximum)
            try container.encodeIfPresent(example, forKey: .example)

        case .integer(let description, let minimum, let maximum, let example):
            try container.encode("integer", forKey: .type)
            try container.encodeIfPresent(description, forKey: .description)
            try container.encodeIfPresent(minimum, forKey: .minimum)
            try container.encodeIfPresent(maximum, forKey: .maximum)
            try container.encodeIfPresent(example, forKey: .example)

        case .boolean(let description, let example):
            try container.encode("boolean", forKey: .type)
            try container.encodeIfPresent(description, forKey: .description)
            try container.encodeIfPresent(example, forKey: .example)

        case .array(let description, let items):
            try container.encode("array", forKey: .type)
            try container.encodeIfPresent(description, forKey: .description)
            try container.encode(items, forKey: .items)

        case .object(let description, let properties, let required):
            try container.encode("object", forKey: .type)
            try container.encodeIfPresent(description, forKey: .description)
            try container.encode(properties, forKey: .properties)
            try container.encodeIfPresent(required, forKey: .required)
        }
    }

    private enum CodingKeys: String, CodingKey {
        case type
        case description
        case items
        case properties
        case required
        case enumValues = "enum"
        case format
        case minimum
        case maximum
        case example
    }
}

/// Simplified JSON value type for extracted data
public enum JSONValue: Codable, Equatable, Sendable {
    case string(String)
    case number(Double)
    case boolean(Bool)
    case array([JSONValue])
    case object([String: JSONValue])
    case null

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        if container.decodeNil() {
            self = .null
        } else if let stringValue = try? container.decode(String.self) {
            self = .string(stringValue)
        } else if let doubleValue = try? container.decode(Double.self) {
            self = .number(doubleValue)
        } else if let boolValue = try? container.decode(Bool.self) {
            self = .boolean(boolValue)
        } else if let arrayValue = try? container.decode([JSONValue].self) {
            self = .array(arrayValue)
        } else if let objectValue = try? container.decode([String: JSONValue].self) {
            self = .object(objectValue)
        } else {
            throw DecodingError.typeMismatch(
                JSONValue.self,
                DecodingError.Context(
                    codingPath: decoder.codingPath,
                    debugDescription: "Unable to decode JSONValue"
                )
            )
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()

        switch self {
        case .string(let value):
            try container.encode(value)
        case .number(let value):
            try container.encode(value)
        case .boolean(let value):
            try container.encode(value)
        case .array(let value):
            try container.encode(value)
        case .object(let value):
            try container.encode(value)
        case .null:
            try container.encodeNil()
        }
    }
}

/// Scrape options for extraction
public struct ExtractScrapeOptions: Codable, Sendable {
    /// Formats to extract
    public let formats: [Format]?

    /// Only return the main content of the page
    public let onlyMainContent: Bool?

    /// Tags to include in the output
    public let includeTags: [String]?

    /// Tags to exclude from the output
    public let excludeTags: [String]?

    /// Returns a cached version if younger than this age in milliseconds
    public let maxAge: Int?

    /// Headers to send with the request
    public let headers: [String: String]?

    /// Delay in milliseconds before fetching content
    public let waitFor: Int?

    /// Emulate scraping from a mobile device
    public let mobile: Bool?

    /// Skip TLS certificate verification
    public let skipTlsVerification: Bool?

    /// Timeout in milliseconds
    public let timeout: Int?

    /// File processing parsers
    public let parsers: [Parser]?

    /// Actions to perform on the page
    public let actions: [ScrapeAction]?

    /// Location settings
    public let location: LocationSettings?

    /// Remove base64 images from output
    public let removeBase64Images: Bool?

    /// Enable ad-blocking
    public let blockAds: Bool?

    /// Proxy type to use
    public let proxy: ProxyType?

    /// Store in Firecrawl cache
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

    enum CodingKeys: String, CodingKey {
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
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

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
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

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
    }
}

/// Response from starting an extract job
public struct ExtractResponse: FirecrawlResponse, Sendable {
    public let success: Bool
    public let id: String?
    public let invalidURLs: [String]?

    public init(success: Bool, id: String? = nil, invalidURLs: [String]? = nil) {
        self.success = success
        self.id = id
        self.invalidURLs = invalidURLs
    }
}

/// Status response for checking extract progress
public struct ExtractStatusResponse: FirecrawlResponse, Sendable {
    public let success: Bool
    public let data: ExtractedData?
    public let status: ExtractJobStatus
    public let expiresAt: String?
    public let tokensUsed: Int?

    public init(
        success: Bool = true,
        data: ExtractedData? = nil,
        status: ExtractJobStatus,
        expiresAt: String? = nil,
        tokensUsed: Int? = nil
    ) {
        self.success = success
        self.data = data
        self.status = status
        self.expiresAt = expiresAt
        self.tokensUsed = tokensUsed
    }
}

/// Extract job status enumeration
public enum ExtractJobStatus: String, Codable, CaseIterable, Sendable {
    case completed
    case processing
    case failed
    case cancelled

    /// Whether the job is in a final state
    public var isFinal: Bool {
        switch self {
        case .completed, .failed, .cancelled:
            return true
        case .processing:
            return false
        }
    }
}

/// Extracted structured data
public struct ExtractedData: Codable, Equatable, Sendable {
    /// The extracted structured data
    public let extract: [String: JSONValue]?

    /// Sources used to extract the data (if showSources was true)
    public let sources: [ExtractSource]?

    /// Warning message if any issues occurred
    public let warning: String?

    /// Confidence score for the extraction (0.0 to 1.0)
    public let confidence: Double?

    public init(
        extract: [String: JSONValue]? = nil,
        sources: [ExtractSource]? = nil,
        warning: String? = nil,
        confidence: Double? = nil
    ) {
        self.extract = extract
        self.sources = sources
        self.warning = warning
        self.confidence = confidence
    }
}

/// Source information for extracted data
public struct ExtractSource: Codable, Equatable, Sendable {
    /// URL of the source
    public let url: String

    /// Title of the source page
    public let title: String?

    /// Description of the source page
    public let description: String?

    public init(url: String, title: String? = nil, description: String? = nil) {
        self.url = url
        self.title = title
        self.description = description
    }
}

/// Response from canceling an extract job
public struct ExtractCancelResponse: FirecrawlResponse, Sendable {
    public let success: Bool
    public let message: String?

    public init(success: Bool, message: String? = nil) {
        self.success = success
        self.message = message
    }
}
