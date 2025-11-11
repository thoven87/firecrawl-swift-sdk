import AsyncHTTPClient
import Crypto
import Foundation
import NIOCore
import Testing

@testable import Firecrawl

@Suite("Firecrawl SDK Tests")
struct FirecrawlTests {

    let testAPIKey = "fc-test-key-123456789"
    let testURL = "https://example.com"

    @Test("ScrapeRequest serialization")
    func scrapeRequestSerialization() throws {
        let formats: [Format] = [.markdown, .html, .summary]

        let request = ScrapeRequest(
            url: testURL,
            formats: formats,
            onlyMainContent: true,
            headers: ["User-Agent": "Test"],
            mobile: true,
            timeout: 30000
        )

        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        let data = try encoder.encode(request)
        let decodedRequest = try decoder.decode(ScrapeRequest.self, from: data)

        #expect(decodedRequest.url == testURL)
        #expect(decodedRequest.formats == [Format.markdown, Format.html, Format.summary])
        #expect(decodedRequest.onlyMainContent == true)
        #expect(decodedRequest.timeout == 30000)
        #expect(decodedRequest.mobile == true)
    }

    @Test("CrawlRequest serialization")
    func crawlRequestSerialization() throws {
        let scrapeOptions = CrawlScrapeOptions(
            formats: [.markdown]
        )

        let request = CrawlRequest(
            url: testURL,
            excludePaths: ["/private/*"],
            includePaths: ["/blog/*", "/docs/*"],
            maxDiscoveryDepth: 3,
            limit: 100,
            scrapeOptions: scrapeOptions
        )

        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        let data = try encoder.encode(request)
        let decodedRequest = try decoder.decode(CrawlRequest.self, from: data)

        #expect(decodedRequest.url == testURL)
        #expect(decodedRequest.scrapeOptions?.formats?.contains(.markdown) == true)
        #expect(decodedRequest.limit == 100)
        #expect(decodedRequest.maxDiscoveryDepth == 3)
    }

    @Test("CrawlParamsPreviewRequest serialization")
    func crawlParamsPreviewRequestSerialization() throws {
        let request = CrawlParamsPreviewRequest(
            url: "https://example.com",
            prompt: "Crawl all blog posts and documentation pages"
        )

        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        let data = try encoder.encode(request)
        let decodedRequest = try decoder.decode(CrawlParamsPreviewRequest.self, from: data)

        #expect(decodedRequest.url == "https://example.com")
        #expect(decodedRequest.prompt == "Crawl all blog posts and documentation pages")
    }

    @Test("CrawlCancelResponse deserialization")
    func crawlCancelResponseDeserialization() throws {
        let jsonString = """
            {
                "status": "cancelled"
            }
            """

        let data = jsonString.data(using: .utf8)!
        let decoder = JSONDecoder()
        let response = try decoder.decode(CrawlCancelResponse.self, from: data)

        #expect(response.status == "cancelled")
    }

    @Test("CrawlErrorsResponse deserialization")
    func crawlErrorsResponseDeserialization() throws {
        let jsonString = """
            {
                "errors": [
                    {
                        "id": "error-123",
                        "timestamp": "2023-11-07T05:31:56Z",
                        "url": "https://example.com/page1",
                        "error": "Failed to load page"
                    }
                ],
                "robotsBlocked": [
                    "https://example.com/blocked-page"
                ]
            }
            """

        let data = jsonString.data(using: .utf8)!
        let decoder = JSONDecoder()
        let response = try decoder.decode(CrawlErrorsResponse.self, from: data)

        #expect(response.errors?.count == 1)
        #expect(response.errors?.first?.id == "error-123")
        #expect(response.errors?.first?.url == "https://example.com/page1")
        #expect(response.errors?.first?.error == "Failed to load page")
        #expect(response.robotsBlocked?.count == 1)
        #expect(response.robotsBlocked?.first == "https://example.com/blocked-page")
    }

    @Test("ActiveCrawlsResponse deserialization")
    func activeCrawlsResponseDeserialization() throws {
        let jsonString = """
            {
                "success": true,
                "crawls": [
                    {
                        "id": "3c90c3cc-0d44-4b50-8888-8dd25736052a",
                        "teamId": "team-123",
                        "url": "https://example.com",
                        "options": {
                            "scrapeOptions": {
                                "formats": ["markdown"],
                                "onlyMainContent": true
                            }
                        }
                    }
                ]
            }
            """

        let data = jsonString.data(using: .utf8)!
        let decoder = JSONDecoder()
        let response = try decoder.decode(ActiveCrawlsResponse.self, from: data)

        #expect(response.success == true)
        #expect(response.crawls?.count == 1)
        #expect(response.crawls?.first?.id == "3c90c3cc-0d44-4b50-8888-8dd25736052a")
        #expect(response.crawls?.first?.teamId == "team-123")
        #expect(response.crawls?.first?.url == "https://example.com")
    }

    @Test("CreditUsageResponse deserialization")
    func creditUsageResponseDeserialization() throws {
        let jsonString = """
            {
                "success": true,
                "data": {
                    "remainingCredits": 1000,
                    "planCredits": 500000,
                    "billingPeriodStart": "2025-01-01T00:00:00Z",
                    "billingPeriodEnd": "2025-01-31T23:59:59Z"
                }
            }
            """

        let data = jsonString.data(using: .utf8)!
        let decoder = JSONDecoder()
        let response = try decoder.decode(CreditUsageResponse.self, from: data)

        #expect(response.success == true)
        #expect(response.data?.remainingCredits == 1000)
        #expect(response.data?.planCredits == 500000)
        #expect(response.data?.billingPeriodStart == "2025-01-01T00:00:00Z")
        #expect(response.data?.billingPeriodEnd == "2025-01-31T23:59:59Z")
    }

    @Test("HistoricalCreditUsageResponse deserialization")
    func historicalCreditUsageResponseDeserialization() throws {
        let jsonString = """
            {
                "success": true,
                "periods": [
                    {
                        "startDate": "2025-01-01T00:00:00Z",
                        "endDate": "2025-01-31T23:59:59Z",
                        "apiKey": "my-api-key",
                        "totalCredits": 1000
                    },
                    {
                        "startDate": "2024-12-01T00:00:00Z",
                        "endDate": "2024-12-31T23:59:59Z",
                        "apiKey": null,
                        "totalCredits": 750
                    }
                ]
            }
            """

        let data = jsonString.data(using: .utf8)!
        let decoder = JSONDecoder()
        let response = try decoder.decode(HistoricalCreditUsageResponse.self, from: data)

        #expect(response.success == true)
        #expect(response.periods?.count == 2)
        #expect(response.periods?.first?.startDate == "2025-01-01T00:00:00Z")
        #expect(response.periods?.first?.apiKey == "my-api-key")
        #expect(response.periods?.first?.totalCredits == 1000)
        #expect(response.periods?.last?.apiKey == nil)
        #expect(response.periods?.last?.totalCredits == 750)
    }

    @Test("TokenUsageResponse deserialization")
    func tokenUsageResponseDeserialization() throws {
        let jsonString = """
            {
                "success": true,
                "data": {
                    "remainingTokens": 2000,
                    "planTokens": 1000000,
                    "billingPeriodStart": "2025-01-01T00:00:00Z",
                    "billingPeriodEnd": "2025-01-31T23:59:59Z"
                }
            }
            """

        let data = jsonString.data(using: .utf8)!
        let decoder = JSONDecoder()
        let response = try decoder.decode(TokenUsageResponse.self, from: data)

        #expect(response.success == true)
        #expect(response.data?.remainingTokens == 2000)
        #expect(response.data?.planTokens == 1_000_000)
        #expect(response.data?.billingPeriodStart == "2025-01-01T00:00:00Z")
        #expect(response.data?.billingPeriodEnd == "2025-01-31T23:59:59Z")
    }

    @Test("HistoricalTokenUsageResponse deserialization")
    func historicalTokenUsageResponseDeserialization() throws {
        let jsonString = """
            {
                "success": true,
                "periods": [
                    {
                        "startDate": "2025-01-01T00:00:00Z",
                        "endDate": "2025-01-31T23:59:59Z",
                        "apiKey": "my-token-key",
                        "totalTokens": 5000
                    },
                    {
                        "startDate": "2024-12-01T00:00:00Z",
                        "endDate": "2024-12-31T23:59:59Z",
                        "apiKey": null,
                        "totalTokens": 3200
                    }
                ]
            }
            """

        let data = jsonString.data(using: .utf8)!
        let decoder = JSONDecoder()
        let response = try decoder.decode(HistoricalTokenUsageResponse.self, from: data)

        #expect(response.success == true)
        #expect(response.periods?.count == 2)
        #expect(response.periods?.first?.startDate == "2025-01-01T00:00:00Z")
        #expect(response.periods?.first?.apiKey == "my-token-key")
        #expect(response.periods?.first?.totalTokens == 5000)
        #expect(response.periods?.last?.apiKey == nil)
        #expect(response.periods?.last?.totalTokens == 3200)
    }

    @Test("QueueStatusResponse deserialization")
    func queueStatusResponseDeserialization() throws {
        let jsonString = """
            {
                "success": true,
                "jobsInQueue": 15,
                "activeJobsInQueue": 3,
                "waitingJobsInQueue": 12,
                "maxConcurrency": 5,
                "mostRecentSuccess": "2023-11-07T05:31:56Z"
            }
            """

        let data = jsonString.data(using: .utf8)!
        let decoder = JSONDecoder()
        let response = try decoder.decode(QueueStatusResponse.self, from: data)

        #expect(response.success == true)
        #expect(response.jobsInQueue == 15)
        #expect(response.activeJobsInQueue == 3)
        #expect(response.waitingJobsInQueue == 12)
        #expect(response.maxConcurrency == 5)
        #expect(response.mostRecentSuccess == "2023-11-07T05:31:56Z")
    }

    @Test("Webhook signature verification - valid signature")
    func webhookSignatureVerificationValid() throws {
        let payload = """
            {"test": "data"}
            """
        let secret = "test_secret"

        // Generate proper signature for this test
        let key = SymmetricKey(data: Data(secret.utf8))
        let payloadData = Data(payload.utf8)
        let computedHash = HMAC<SHA256>.authenticationCode(for: payloadData, using: key)
        let expectedHash = Data(computedHash).map { String(format: "%02hhx", $0) }.joined()
        let signature = "sha256=\(expectedHash)"

        // Test with ByteBuffer (primary method)
        let buffer = ByteBuffer(string: payload)
        try FirecrawlClient.verifyWebhookSignature(
            payload: buffer,
            signature: signature,
            secret: secret
        )

        // Test with String (convenience method)
        try FirecrawlClient.verifyWebhookSignature(
            payload: payload,
            signature: signature,
            secret: secret
        )
    }

    @Test("Webhook signature verification - invalid signature format")
    func webhookSignatureVerificationInvalidFormat() throws {
        let payload = "{\"test\": \"data\"}"
        let secret = "test_secret"

        // Test missing algorithm
        #expect(throws: FirecrawlClient.WebhookSignatureError.invalidSignatureFormat) {
            try FirecrawlClient.verifyWebhookSignature(
                payload: payload,
                signature: "invalid_signature",
                secret: secret
            )
        }

        // Test wrong algorithm
        #expect(throws: FirecrawlClient.WebhookSignatureError.invalidSignatureFormat) {
            try FirecrawlClient.verifyWebhookSignature(
                payload: payload,
                signature: "md5=abc123",
                secret: secret
            )
        }
    }

    @Test("Webhook signature verification - invalid signature")
    func webhookSignatureVerificationInvalidSignature() throws {
        let payload = "{\"test\": \"data\"}"
        let secret = "test_secret"
        let wrongSignature = "sha256=wrong_hash_value"

        #expect(throws: FirecrawlClient.WebhookSignatureError.invalidSignature) {
            try FirecrawlClient.verifyWebhookSignature(
                payload: payload,
                signature: wrongSignature,
                secret: secret
            )
        }
    }

    @Test("Webhook signature verification - ByteBuffer primary")
    func webhookSignatureVerificationByteBufferPrimary() throws {
        let payloadString = "{\"event\": \"test\"}"
        let secret = "my_secret"

        // Generate a proper signature for testing
        let key = SymmetricKey(data: Data(secret.utf8))
        let payloadData = Data(payloadString.utf8)
        let computedHash = HMAC<SHA256>.authenticationCode(for: payloadData, using: key)
        let expectedHash = Data(computedHash).map { String(format: "%02hhx", $0) }.joined()
        let signature = "sha256=\(expectedHash)"

        // Test ByteBuffer (primary method)
        let buffer = ByteBuffer(data: payloadData)
        try FirecrawlClient.verifyWebhookSignature(
            payload: buffer,
            signature: signature,
            secret: secret
        )
    }

    @Test("Webhook signature verification - real world example")
    func webhookSignatureVerificationRealWorld() throws {
        // Simulate a real webhook payload from Firecrawl
        let payload = """
            {
                "type": "crawl.page",
                "data": {
                    "jobId": "crawl_12345",
                    "url": "https://example.com/page1",
                    "markdown": "# Page Title\\n\\nContent here...",
                    "metadata": {
                        "title": "Example Page",
                        "statusCode": 200
                    }
                },
                "metadata": {
                    "project": "my-project"
                }
            }
            """

        let secret = "wh_secret_abc123def456"

        // Generate proper signature
        let key = SymmetricKey(data: Data(secret.utf8))
        let payloadData = Data(payload.utf8)
        let computedHash = HMAC<SHA256>.authenticationCode(for: payloadData, using: key)
        let expectedHash = Data(computedHash).map { String(format: "%02hhx", $0) }.joined()
        let signature = "sha256=\(expectedHash)"

        // Verification should succeed
        try FirecrawlClient.verifyWebhookSignature(
            payload: payload,
            signature: signature,
            secret: secret
        )
    }

    @Test("Webhook signature verification - String convenience")
    func webhookSignatureVerificationString() throws {
        let payloadString = "{\"event\": \"test\", \"data\": {\"jobId\": \"123\"}}"
        let secret = "test_secret_key"

        // Generate proper signature
        let key = SymmetricKey(data: Data(secret.utf8))
        let payloadData = Data(payloadString.utf8)
        let computedHash = HMAC<SHA256>.authenticationCode(for: payloadData, using: key)
        let expectedHash = Data(computedHash).map { String(format: "%02hhx", $0) }.joined()
        let signature = "sha256=\(expectedHash)"

        // Test String convenience method
        try FirecrawlClient.verifyWebhookSignature(
            payload: payloadString,
            signature: signature,
            secret: secret
        )
    }

    @Test("Webhook signature error descriptions")
    func webhookSignatureErrorDescriptions() throws {
        let missingHeader = FirecrawlClient.WebhookSignatureError.missingSignatureHeader
        let invalidFormat = FirecrawlClient.WebhookSignatureError.invalidSignatureFormat
        let invalidSignature = FirecrawlClient.WebhookSignatureError.invalidSignature

        #expect(missingHeader.errorDescription == "Missing X-Firecrawl-Signature header")
        #expect(
            invalidFormat.errorDescription
                == "Invalid signature format. Expected format: sha256=<hash>")
        #expect(invalidSignature.errorDescription == "Webhook signature verification failed")
    }

    @Test("SearchRequest serialization")
    func searchRequestSerialization() throws {
        let scrapeOptions = SearchScrapeOptions(
            formats: [.markdown, .html],
            onlyMainContent: true
        )

        let request = SearchRequest(
            query: "test query",
            limit: 10,
            sources: [.web(), .images],
            categories: [.github, .research],
            tbs: "qdr:w",
            location: "San Francisco,California,United States",
            country: "US",
            timeout: 60000,
            ignoreInvalidURLs: false,
            scrapeOptions: scrapeOptions
        )

        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        let data = try encoder.encode(request)
        let decodedRequest = try decoder.decode(SearchRequest.self, from: data)

        #expect(decodedRequest.query == "test query")
        #expect(decodedRequest.limit == 10)
        #expect(decodedRequest.sources?.count == 2)
        #expect(decodedRequest.categories?.count == 2)
        #expect(decodedRequest.tbs == "qdr:w")
        #expect(decodedRequest.location == "San Francisco,California,United States")
        #expect(decodedRequest.country == "US")
        #expect(decodedRequest.timeout == 60000)
        #expect(decodedRequest.ignoreInvalidURLs == false)
        #expect(decodedRequest.scrapeOptions?.formats?.contains(.markdown) == true)
        #expect(decodedRequest.scrapeOptions?.onlyMainContent == true)
    }

    @Test("ExtractRequest serialization")
    func extractRequestSerialization() throws {
        let schema = ExtractionSchema(
            properties: [
                "title": .string(
                    description: "Page title", enumValues: nil, format: nil, example: nil),
                "price": .number(
                    description: "Product price", minimum: 0, maximum: nil, example: nil),
                "inStock": .boolean(description: "Whether item is in stock", example: nil),
                "tags": .array(
                    description: "Product tags",
                    items: .string(description: nil, enumValues: nil, format: nil, example: nil)),
            ],
            required: ["title"]
        )

        let scrapeOptions = ExtractScrapeOptions(
            formats: [.markdown],
            onlyMainContent: true,
            mobile: false
        )

        let request = ExtractRequest(
            urls: [testURL, "https://example.com/page2"],
            prompt: "Extract product information",
            schema: schema,
            enableWebSearch: false,
            includeSubdomains: true,
            showSources: true,
            scrapeOptions: scrapeOptions
        )

        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        let data = try encoder.encode(request)
        let decodedRequest = try decoder.decode(ExtractRequest.self, from: data)

        #expect(decodedRequest.urls == [testURL, "https://example.com/page2"])
        #expect(decodedRequest.prompt == "Extract product information")
        #expect(decodedRequest.schema?.required == ["title"])
        #expect(decodedRequest.enableWebSearch == false)
        #expect(decodedRequest.includeSubdomains == true)
        #expect(decodedRequest.showSources == true)
        #expect(decodedRequest.scrapeOptions?.onlyMainContent == true)
        #expect(decodedRequest.scrapeOptions?.mobile == false)
    }

    @Test("MapRequest serialization")
    func mapRequestSerialization() throws {
        let request = MapRequest(
            url: testURL,
            search: "blog",
            sitemap: .include,
            includeSubdomains: false,
            ignoreQueryParameters: true,
            limit: 1000,
            timeout: 30000
        )

        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        let data = try encoder.encode(request)
        let decodedRequest = try decoder.decode(MapRequest.self, from: data)

        #expect(decodedRequest.url == testURL)
        #expect(decodedRequest.search == "blog")
        #expect(decodedRequest.sitemap == .include)
        #expect(decodedRequest.includeSubdomains == false)
        #expect(decodedRequest.ignoreQueryParameters == true)
        #expect(decodedRequest.limit == 1000)
        #expect(decodedRequest.timeout == 30000)
    }

    @Test("ScrapeResponse deserialization")
    func scrapeResponseDeserialization() throws {
        let jsonString = """
            {
                "success": true,
                "data": {
                    "markdown": "# Test Page\\n\\nThis is a test page.",
                    "html": "<h1>Test Page</h1><p>This is a test page.</p>",
                    "summary": "This is a test page.",
                    "metadata": {
                        "title": "Test Page",
                        "description": "A test page for unit testing",
                        "statusCode": 200,
                        "sourceURL": "https://example.com"
                    }
                }
            }
            """

        let data = jsonString.data(using: .utf8)!
        let decoder = JSONDecoder()
        let response = try decoder.decode(ScrapeResponse.self, from: data)

        #expect(response.success == true)
        #expect(response.data != nil)
        #expect(response.data?.markdown == "# Test Page\n\nThis is a test page.")
        #expect(response.data?.html == "<h1>Test Page</h1><p>This is a test page.</p>")
        #expect(response.data?.summary == "This is a test page.")
    }

    @Test("CrawlStatusResponse deserialization")
    func crawlStatusResponseDeserialization() throws {
        let jsonString = """
            {
                "status": "completed",
                "total": 5,
                "completed": 5,
                "creditsUsed": 10,
                "data": [
                    {
                        "markdown": "# Page 1",
                        "metadata": {
                            "title": "Page 1",
                            "sourceURL": "https://example.com/page1"
                        }
                    }
                ]
            }
            """

        let data = jsonString.data(using: .utf8)!
        let decoder = JSONDecoder()
        let response = try decoder.decode(CrawlStatusResponse.self, from: data)

        #expect(response.status == .completed)
        #expect(response.total == 5)
        #expect(response.completed == 5)
        #expect(response.creditsUsed == 10)
        #expect(response.data?.count == 1)
        #expect(response.data?.first?.markdown == "# Page 1")
    }

    @Test("SearchResponse deserialization")
    func searchResponseDeserialization() throws {
        let jsonString = """
            {
                "success": true,
                "data": {
                    "web": [
                        {
                            "title": "Result 1",
                            "description": "First search result",
                            "url": "https://example.com/result1",
                            "markdown": "# Search Result 1",
                            "metadata": {
                                "title": "Result 1",
                                "description": "First search result",
                                "sourceURL": "https://example.com/result1",
                                "statusCode": 200
                            }
                        }
                    ]
                }
            }
            """

        let data = jsonString.data(using: .utf8)!
        let decoder = JSONDecoder()
        let response = try decoder.decode(SearchResponse.self, from: data)

        #expect(response.success == true)
        #expect(response.data?.web?.count == 1)
        #expect(response.data?.web?.first?.url == "https://example.com/result1")
        #expect(response.data?.web?.first?.title == "Result 1")
        #expect(response.data?.web?.first?.markdown == "# Search Result 1")
    }

    @Test("FirecrawlError deserialization")
    func firecrawlErrorDeserialization() throws {
        let jsonString = """
            {
                "success": false,
                "error": "Invalid URL provided",
                "details": "The URL must be a valid HTTP or HTTPS URL",
                "validation_errors": [
                    {
                        "field": "url",
                        "message": "Invalid URL format",
                        "code": "INVALID_URL"
                    }
                ]
            }
            """

        let data = jsonString.data(using: .utf8)!
        let decoder = JSONDecoder()
        let errorResponse = try decoder.decode(FirecrawlErrorResponse.self, from: data)

        #expect(errorResponse.success == false)
        #expect(errorResponse.error == "Invalid URL provided")
        #expect(errorResponse.details == "The URL must be a valid HTTP or HTTPS URL")
        #expect(errorResponse.validationErrors?.count == 1)
        #expect(errorResponse.validationErrors?.first?.field == "url")
        #expect(errorResponse.validationErrors?.first?.code == "INVALID_URL")
    }

    @Test("Format enum")
    func formatEnum() {
        #expect(Format.markdown.rawValue == "markdown")
        #expect(Format.html.rawValue == "html")
        #expect(Format.rawHtml.rawValue == "rawHtml")
        #expect(Format.screenshot.rawValue == "screenshot")
        #expect(Format.links.rawValue == "links")

        let allFormats = Format.allFormatsString
        #expect(allFormats.contains("markdown"))
        #expect(allFormats.contains("html"))
        #expect(allFormats.contains("summary"))
    }

    @Test("JobStatus")
    func jobStatus() {
        #expect(JobStatus.scraping.isFinal == false)
        #expect(JobStatus.completed.isFinal == true)
        #expect(JobStatus.failed.isFinal == true)
        #expect(JobStatus.cancelled.isFinal == true)
    }

    @Test("SchemaProperty helpers")
    func schemaPropertyHelpers() throws {
        let stringProp = SchemaProperty.string(
            description: "Test string", enumValues: nil, format: nil, example: "example")

        // Test encoding/decoding to verify structure
        let encoder = JSONEncoder()
        let data = try encoder.encode(stringProp)
        let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]

        #expect(json["type"] as? String == "string")
        #expect(json["description"] as? String == "Test string")
        #expect(json["example"] as? String == "example")

        let numberProp = SchemaProperty.number(
            description: "Test number", minimum: 0, maximum: 100, example: nil)
        let numberData = try encoder.encode(numberProp)
        let numberJson = try JSONSerialization.jsonObject(with: numberData) as! [String: Any]

        #expect(numberJson["type"] as? String == "number")
        #expect(numberJson["minimum"] as? Double == 0)
        #expect(numberJson["maximum"] as? Double == 100)

        let boolProp = SchemaProperty.boolean(description: "Test boolean", example: nil)
        let boolData = try encoder.encode(boolProp)
        let boolJson = try JSONSerialization.jsonObject(with: boolData) as! [String: Any]

        #expect(boolJson["type"] as? String == "boolean")

        let arrayProp = SchemaProperty.array(description: "Test array", items: stringProp)
        let arrayData = try encoder.encode(arrayProp)
        let arrayJson = try JSONSerialization.jsonObject(with: arrayData) as! [String: Any]

        #expect(arrayJson["type"] as? String == "array")
        #expect(arrayJson["items"] != nil)

        let objectProp = SchemaProperty.object(
            description: "Test object",
            properties: ["name": stringProp],
            required: nil
        )
        let objectData = try encoder.encode(objectProp)
        let objectJson = try JSONSerialization.jsonObject(with: objectData) as! [String: Any]

        #expect(objectJson["type"] as? String == "object")
        #expect(objectJson["properties"] != nil)
    }

    @Test("JSONValue serialization")
    func jsonValueSerialization() throws {
        let stringValue = JSONValue.string("test")
        let numberValue = JSONValue.number(42.0)
        let boolValue = JSONValue.boolean(true)
        let _ = JSONValue.null

        let arrayValue = JSONValue.array([stringValue, numberValue])
        let objectValue = JSONValue.object(["key": stringValue, "count": numberValue])

        let encoder = JSONEncoder()

        let stringData = try encoder.encode(stringValue)
        let stringResult =
            try JSONSerialization.jsonObject(with: stringData, options: .fragmentsAllowed)
            as! String
        #expect(stringResult == "test")

        let numberData = try encoder.encode(numberValue)
        let numberResult =
            try JSONSerialization.jsonObject(with: numberData, options: .fragmentsAllowed)
            as! Double
        #expect(numberResult == 42.0)

        let boolData = try encoder.encode(boolValue)
        let boolResult =
            try JSONSerialization.jsonObject(with: boolData, options: .fragmentsAllowed) as! Bool
        #expect(boolResult == true)

        let arrayData = try encoder.encode(arrayValue)
        let arrayResult = try JSONSerialization.jsonObject(with: arrayData) as! [Any]
        #expect(arrayResult.count == 2)

        let objectData = try encoder.encode(objectValue)
        let objectResult = try JSONSerialization.jsonObject(with: objectData) as! [String: Any]
        #expect(objectResult.count == 2)
    }

    @Test("Performance - model serialization", .timeLimit(.minutes(1)))
    func performanceModelSerialization() throws {
        let request = ScrapeRequest(
            url: testURL,
            formats: [.markdown, .html, .summary, .screenshot, .links],
            onlyMainContent: true,
            includeTags: ["div", "p", "h1", "h2", "h3"],
            excludeTags: ["script", "style"],
            headers: ["User-Agent": "Test"],
            mobile: true,
            timeout: 30000
        )

        let encoder = JSONEncoder()

        for _ in 0..<1000 {
            _ = try encoder.encode(request)
        }
    }

    @Test("Performance - model deserialization", .timeLimit(.minutes(1)))
    func performanceModelDeserialization() throws {
        let jsonString = """
            {
                "success": true,
                "data": {
                    "markdown": "# Test Page\\n\\nThis is a test page with lots of content.",
                    "html": "<h1>Test Page</h1><p>This is a test page with lots of content.</p>",
                    "summary": "This is a test page with lots of content."
                },
                "metadata": {
                    "title": "Test Page",
                    "description": "A test page for performance testing",
                    "statusCode": 200,
                    "sourceURL": "https://example.com"
                }
            }
            """

        let data = jsonString.data(using: .utf8)!
        let decoder = JSONDecoder()

        for _ in 0..<1000 {
            _ = try decoder.decode(ScrapeResponse.self, from: data)
        }
    }

    @Test("BatchScrapeRequest serialization")
    func batchScrapeRequestSerialization() throws {
        let webhook = BatchWebhook(
            url: "https://webhook.example.com",
            headers: ["Authorization": "Bearer token"],
            events: [.started, .completed]
        )

        let request = BatchScrapeRequest(
            urls: ["https://example.com/1", "https://example.com/2"],
            webhook: webhook,
            maxConcurrency: 5,
            ignoreInvalidURLs: true,
            formats: [.markdown, .html],
            onlyMainContent: true,
            mobile: false
        )

        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        let data = try encoder.encode(request)
        let decodedRequest = try decoder.decode(BatchScrapeRequest.self, from: data)

        #expect(decodedRequest.urls == ["https://example.com/1", "https://example.com/2"])
        #expect(decodedRequest.webhook?.url == "https://webhook.example.com")
        #expect(decodedRequest.maxConcurrency == 5)
        #expect(decodedRequest.ignoreInvalidURLs == true)
        #expect(decodedRequest.formats == [Format.markdown, Format.html])
        #expect(decodedRequest.onlyMainContent == true)
        #expect(decodedRequest.mobile == false)
    }

    @Test("BatchScrapeStatusResponse deserialization")
    func batchScrapeStatusResponseDeserialization() throws {
        let jsonString = """
            {
                "success": true,
                "status": "completed",
                "total": 10,
                "completed": 8,
                "creditsUsed": 16,
                "expiresAt": "2024-01-01T12:00:00Z",
                "data": [
                    {
                        "markdown": "# Page 1 Content",
                        "html": "<h1>Page 1 Content</h1>",
                        "metadata": {
                            "title": "Page 1",
                            "sourceURL": "https://example.com/1",
                            "statusCode": 200
                        }
                    },
                    {
                        "markdown": "# Page 2 Content",
                        "metadata": {
                            "title": "Page 2",
                            "sourceURL": "https://example.com/2",
                            "statusCode": 200
                        }
                    }
                ]
            }
            """

        let data = jsonString.data(using: .utf8)!
        let decoder = JSONDecoder()
        let response = try decoder.decode(BatchScrapeStatusResponse.self, from: data)

        #expect(response.success == true)
        #expect(response.status == .completed)
        #expect(response.total == 10)
        #expect(response.completed == 8)
        #expect(response.creditsUsed == 16)
        #expect(response.data?.count == 2)
        #expect(response.data?.first?.markdown == "# Page 1 Content")
        #expect(response.data?.first?.html == "<h1>Page 1 Content</h1>")
    }
}

@Suite("Schema Property Tests")
struct SchemaPropertyTests {

    @Test("String schema property round-trip")
    func stringSchemaRoundTrip() throws {
        let original = SchemaProperty.string(
            description: "A test string",
            enumValues: ["option1", "option2"],
            format: "email",
            example: "test@example.com"
        )

        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        let data = try encoder.encode(original)
        let _ = try decoder.decode(SchemaProperty.self, from: data)

        // Verify the decoded values match
        let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        #expect(json["type"] as? String == "string")
        #expect(json["description"] as? String == "A test string")
        #expect(json["format"] as? String == "email")
        #expect(json["example"] as? String == "test@example.com")
    }

    @Test("Object schema property round-trip")
    func objectSchemaRoundTrip() throws {
        let stringProp = SchemaProperty.string(
            description: "Name field", enumValues: nil, format: nil, example: nil)
        let numberProp = SchemaProperty.number(
            description: "Age field", minimum: 0, maximum: nil, example: nil)

        let original = SchemaProperty.object(
            description: "Person object",
            properties: [
                "name": stringProp,
                "age": numberProp,
            ],
            required: ["name"]
        )

        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        let data = try encoder.encode(original)
        let _ = try decoder.decode(SchemaProperty.self, from: data)

        let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        #expect(json["type"] as? String == "object")
        #expect(json["description"] as? String == "Person object")

        let properties = json["properties"] as! [String: Any]
        #expect(properties.count == 2)

        let required = json["required"] as! [String]
        #expect(required == ["name"])
    }
}
