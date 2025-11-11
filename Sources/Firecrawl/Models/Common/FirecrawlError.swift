import Foundation

/// Errors that can occur when using the Firecrawl API
public enum FirecrawlError: Error, LocalizedError, Sendable {
    /// Network-related errors
    case networkError(Error)

    /// Invalid API key or authorization failure
    case unauthorized(String?)

    /// Payment required
    case paymentRequired(String?)

    /// Rate limit exceeded
    case rateLimitExceeded(String?)

    /// Bad request with validation errors
    case badRequest(String?, [ValidationError]?)

    /// Resource not found
    case notFound(String?)

    /// Server error (5xx)
    case serverError(Int, String?)

    /// Invalid URL provided
    case invalidURL(String)

    /// Invalid response format
    case invalidResponse(String?)

    /// Decoding error when parsing API response
    case decodingError(Error)

    /// Encoding error when preparing request
    case encodingError(Error)

    /// Unknown error with status code
    case unknown(Int, String?)

    public var errorDescription: String? {
        switch self {
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .unauthorized(let message):
            return message ?? "Unauthorized: Invalid API key"
        case .paymentRequired(let message):
            return message ?? "Payment required"
        case .rateLimitExceeded(let message):
            return message ?? "Rate limit exceeded"
        case .badRequest(let message, let validationErrors):
            var description = message ?? "Bad request"
            if let errors = validationErrors, !errors.isEmpty {
                let errorMessages = errors.map { $0.message }.joined(separator: ", ")
                description += ": \(errorMessages)"
            }
            return description
        case .notFound(let message):
            return message ?? "Resource not found"
        case .serverError(let code, let message):
            return message ?? "Server error (\(code))"
        case .invalidURL(let url):
            return "Invalid URL: \(url)"
        case .invalidResponse(let message):
            return message ?? "Invalid response format"
        case .decodingError(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        case .encodingError(let error):
            return "Failed to encode request: \(error.localizedDescription)"
        case .unknown(let code, let message):
            return message ?? "Unknown error (\(code))"
        }
    }
}

/// Validation error details
public struct ValidationError: Codable, Equatable, Sendable {
    public let field: String?
    public let message: String
    public let code: String?

    public init(field: String? = nil, message: String, code: String? = nil) {
        self.field = field
        self.message = message
        self.code = code
    }
}

/// API error response structure
public struct FirecrawlErrorResponse: Codable, Sendable {
    public let success: Bool
    public let error: String?
    public let details: String?
    public let validationErrors: [ValidationError]?

    enum CodingKeys: String, CodingKey {
        case success
        case error
        case details
        case validationErrors = "validation_errors"
    }

    public init(
        success: Bool = false, error: String? = nil, details: String? = nil,
        validationErrors: [ValidationError]? = nil
    ) {
        self.success = success
        self.error = error
        self.details = details
        self.validationErrors = validationErrors
    }
}
