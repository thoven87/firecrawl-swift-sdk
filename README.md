# Firecrawl Swift SDK

A comprehensive Swift SDK for the [Firecrawl API v2](https://firecrawl.dev) - scrape, crawl, search, extract, and map websites with ease. Built for server-side Swift with full async/await support and Swift 6 compatibility.

[![Swift 6.0+](https://img.shields.io/badge/Swift-6.0+-orange.svg)](https://swift.org)
[![Platforms](https://img.shields.io/badge/Platforms-macOS%20%7C%20Linux-lightgray.svg)](https://swift.org)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

## Features

- 🔥 **Scrape** - Extract content from any webpage in markdown, HTML, or structured formats
- 🕷️ **Crawl** - Crawl entire websites with smart filtering, webhooks, and natural language prompts
- 🗺️ **Map** - Get a complete list of URLs from any website quickly and reliably
- 🔍 **Search** - Search the web with multi-source support (web, images, news) and advanced filtering
- 🤖 **Extract** - Extract structured data using natural language prompts or JSON schemas
- 👥 **Team Management** - Monitor usage, credits, tokens, and queue status
- 🚀 **Async/Await** - Full Swift concurrency support
- 🛡️ **Type Safe** - Comprehensive Swift types for all API responses
- ⚡ **Performance** - Built on AsyncHTTPClient with optimized ByteBuffer decoding
- 🔧 **Sendable** - Thread-safe types compatible with Swift 6

## Installation

### Swift Package Manager

Add the following to your `Package.swift` file:

```swift
dependencies: [
    .package(url: "https://github.com/thoven87/firecrawl-swift-sdk.git", from: "2.0.0")
]
```

Then add it to your target:

```swift
targets: [
    .target(
        name: "YourTarget",
        dependencies: [
            .product(name: "Firecrawl", package: "firecrawl-swift-sdk")
        ]
    )
]
```

## Quick Start

```swift
import Firecrawl

// Initialize the client
let firecrawl = FirecrawlClient(apiKey: "fc-your-api-key")

// Scrape a webpage
let response = try await firecrawl.scrape(url: "https://example.com")
if response.success {
    print("Content:", response.data?.markdown ?? "")
}
```

## Authentication

Get your API key from [firecrawl.dev](https://firecrawl.dev) and initialize the client:

```swift
let firecrawl = FirecrawlClient(apiKey: "fc-your-api-key")

// Or with custom configuration
let firecrawl = FirecrawlClient(
    apiKey: "fc-your-api-key",
    baseURL: "https://api.firecrawl.dev", // Optional: custom base URL
    httpClient: myHTTPClient,             // Optional: custom HTTP client
    logger: myLogger                      // Optional: custom logger
)
```

## API Reference

### 🔥 Scraping

Extract content from a single webpage:

```swift
// Simple scrape
let response = try await firecrawl.scrape(url: "https://example.com")

// Advanced scrape with options
let request = ScrapeRequest(
    url: "https://example.com",
    formats: [.markdown, .html, .screenshot],
    onlyMainContent: true,
    includeTags: ["article", "main", "content"],
    excludeTags: ["nav", "footer", "aside"],
    waitFor: 2000,
    mobile: false,
    actions: [
        .wait(milliseconds: 3000, selector: ".content"),
        .click(selector: ".load-more"),
        .screenshot(fullPage: true)
    ]
)

let response = try await firecrawl.scrape(request)
print("Markdown:", response.data?.markdown ?? "")
print("Screenshot:", response.data?.screenshot ?? "")
```

### 🕷️ Crawling

Crawl entire websites with comprehensive options:

```swift
// Simple crawl
let response = try await firecrawl.crawl(url: "https://example.com", limit: 50)

// Advanced crawl with natural language prompt
let scrapeOptions = CrawlScrapeOptions(
    formats: [.markdown, .html],
    onlyMainContent: true,
    removeBase64Images: true
)

let request = CrawlRequest(
    url: "https://example.com",
    prompt: "Crawl all blog posts and documentation pages",
    excludePaths: ["/admin/*", "/private/*"],
    includePaths: ["/blog/*", "/docs/*"],
    maxDiscoveryDepth: 3,
    limit: 100,
    crawlEntireDomain: false,
    allowExternalLinks: false,
    delay: 1.0,
    webhook: WebhookConfig(
        url: "https://your-server.com/webhook",
        events: [.completed, .failed]
    ),
    scrapeOptions: scrapeOptions
)

let crawlResponse = try await firecrawl.startCrawl(request)

if let jobId = crawlResponse.id {
    // Wait for completion
    let result = try await firecrawl.waitForCrawlCompletion(jobId)

    if result.status == .completed {
        print("Crawled \(result.data?.count ?? 0) pages")
        for page in result.data ?? [] {
            print("URL: \(page.metadata?.sourceURL ?? "")")
            print("Title: \(page.metadata?.title?.stringValue ?? "")")
        }
    }
}
```

### 🗺️ Website Mapping

Get all URLs from a website:

```swift
let response = try await firecrawl.map(url: "https://example.com", limit: 200)

if response.success {
    print("Found \(response.links?.count ?? 0) URLs")
    response.links?.forEach { print($0) }
}

// Advanced mapping
let request = MapRequest(
    url: "https://example.com",
    search: "documentation",
    sitemap: .include,
    includeSubdomains: false,
    limit: 500
)

let response = try await firecrawl.map(request)
```

### 🔍 Web Search

Search the web with multi-source support and advanced filtering:

```swift
// Simple search
let response = try await firecrawl.search(query: "Swift programming language")

// Advanced multi-source search
let scrapeOptions = SearchScrapeOptions(
    formats: [.markdown, .html],
    onlyMainContent: true,
    waitFor: 2000
)

let request = SearchRequest(
    query: "machine learning research papers",
    limit: 20,
    sources: [
        .web(tbs: "qdr:m", location: "San Francisco"),  // Past month, SF location
        .news,
        .images
    ],
    categories: [.research, .pdf, .github],
    location: "San Francisco,California,United States",
    country: "US",
    timeout: 60000,
    scrapeOptions: scrapeOptions
)

let response = try await firecrawl.search(request)

// Access different result types
if let webResults = response.data?.web {
    for result in webResults {
        print("Web: \(result.title ?? "") - \(result.url ?? "")")
    }
}

if let newsResults = response.data?.news {
    for article in newsResults {
        print("News: \(article.title ?? "") (\(article.date ?? ""))")
    }
}

if let imageResults = response.data?.images {
    for image in imageResults {
        print("Image: \(image.title ?? "") - \(image.imageUrl ?? "")")
    }
}
```

### 🤖 Data Extraction

Extract structured data using natural language or JSON schemas:

```swift
// Extract with natural language prompt
let response = try await firecrawl.extract(
    urls: ["https://example-store.com/product/123"],
    prompt: "Extract the product name, price, description, and availability"
)

// Extract with JSON schema
let schema = ExtractionSchema(
    properties: [
        "productName": .string(
            description: "The name of the product"
        ),
        "price": .number(
            description: "Product price in USD",
            minimum: 0
        ),
        "inStock": .boolean(
            description: "Whether the product is in stock"
        ),
        "categories": .array(
            description: "Product categories",
            items: .string(description: "Category name")
        )
    ],
    required: ["productName", "price"]
)

let request = ExtractRequest(
    urls: ["https://example-store.com/product/123"],
    schema: schema,
    enableWebSearch: false
)

let extractResponse = try await firecrawl.startExtract(request)

if let jobId = extractResponse.id {
    let result = try await firecrawl.waitForExtractCompletion(jobId)

    if let extractedData = result.data?.first?.extract {
        print("Extracted data:", extractedData)
    }
}
```

### 👥 Team Management

Monitor your usage, credits, and tokens:

```swift
// Current credit usage
let creditUsage = try await firecrawl.getCreditUsage()
print("Remaining credits:", creditUsage.data?.remainingCredits ?? 0)

// Historical credit usage
let history = try await firecrawl.getHistoricalCreditUsage(byApiKey: true)
for period in history.periods ?? [] {
    print("\(period.apiKey ?? "Total"): \(period.totalCredits) credits")
}

// Current token usage
let tokenUsage = try await firecrawl.getTokenUsage()
print("Remaining tokens:", tokenUsage.data?.remainingTokens ?? 0)

// Queue status
let queueStatus = try await firecrawl.getQueueStatus()
print("Active jobs:", queueStatus.activeJobsInQueue ?? 0)
print("Waiting jobs:", queueStatus.waitingJobsInQueue ?? 0)
```

### 📊 Crawl Management

Monitor and manage your crawls:

```swift
// Get active crawls
let activeCrawls = try await firecrawl.getActiveCrawls()
for crawl in activeCrawls.crawls ?? [] {
    print("Crawl ID:", crawl.id)
    print("URL:", crawl.url)
}

// Get crawl errors
let errors = try await firecrawl.getCrawlErrors("job-id")
print("Errors:", errors.errors?.count ?? 0)
print("Robots blocked:", errors.robotsBlocked?.count ?? 0)

// Cancel crawl
let cancelResponse = try await firecrawl.cancelCrawl("job-id")
print("Status:", cancelResponse.status)

// Generate crawl parameters from natural language
let previewRequest = CrawlParamsPreviewRequest(
    url: "https://example.com",
    prompt: "I want to crawl all the blog posts and product pages but skip the admin sections"
)

let preview = try await firecrawl.getCrawlParamsPreview(previewRequest)
if let data = preview.data {
    print("Generated exclude paths:", data.excludePaths ?? [])
    print("Generated include paths:", data.includePaths ?? [])
}
```

## Supported Formats

The SDK supports multiple content formats:

```swift
public enum Format: String, CaseIterable {
    case markdown      // Clean markdown content (default)
    case summary       // AI-generated summary
    case html         // Structured HTML
    case rawHtml      // Raw HTML as received
    case links        // Extracted links
    case images       // Extracted images
    case screenshot   // Page screenshot
    case json         // Structured JSON data
    case changeTracking // Change detection
    case branding     // Branding information
}

let response = try await firecrawl.scrape(
    url: "https://example.com",
    formats: [.markdown, .html, .screenshot, .links]
)

if let data = response.data {
    print("Markdown:", data.markdown ?? "")
    print("HTML:", data.html ?? "")
    print("Screenshot:", data.screenshot ?? "")
    print("Links:", data.links ?? [])
}
```

## Advanced Features

### Actions & Browser Automation

Perform actions before scraping:

```swift
let request = ScrapeRequest(
    url: "https://example.com",
    actions: [
        .wait(milliseconds: 3000, selector: ".content"),
        .click(selector: ".load-more"),
        .scroll(direction: .down, selector: ".container"),
        .executeJavascript(script: "window.scrollTo(0, document.body.scrollHeight);"),
        .screenshot(fullPage: true, quality: 90),
        .write(text: "search query"),
        .press(key: "Enter")
    ]
)
```

### Webhooks

Get real-time notifications:

```swift
let webhook = WebhookConfig(
    url: "https://your-server.com/webhook",
    headers: ["Authorization": "Bearer your-token"],
    metadata: ["project": "my-project"],
    events: [.started, .page, .completed, .failed]
)

let request = CrawlRequest(
    url: "https://example.com",
    webhook: webhook
)
```

### Complete Webhook Example

Here's a complete example using Hummingbird to handle Firecrawl webhooks:

```swift
import Hummingbird
import Firecrawl
import Logging

// Build webhook handler
func buildWebhookHandler() -> some HTTPResponder {
    let router = Router()

    // Webhook endpoint
    router.post("/webhook/firecrawl", handleFirecrawlWebhook)

    return router.buildResponder()
}

@Sendable
private func handleFirecrawlWebhook(_ request: Request, context: Context) async throws -> HTTPResponse.Status {
    // Get signature from headers
    guard let signature = request.headers.first(where: {
        $0.name.rawName.lowercased() == "x-firecrawl-signature"
    })?.value else {
        context.logger.error(
            "Failed to find X-Firecrawl-Signature header",
            metadata: [
                "error": "Perhaps the request was not originated from Firecrawl",
                "headers": "\(request.headers)",
            ]
        )
        throw HTTPError(.badRequest, message: "Invalid Signature")
    }

    // Get webhook secret from environment
    guard let webhookSecret = Environment.get("FIRECRAWL_WEBHOOK_SECRET") else {
        context.logger.error("Missing FIRECRAWL_WEBHOOK_SECRET environment variable")
        throw HTTPError(.internalServerError, message: "Server configuration error")
    }

    // Get raw body as ByteBuffer for verification
    let bodyBuffer = try await request.body.collect(upTo: 1024 * 1024) // 1MB limit

    // Verify signature using ByteBuffer directly
    do {
        try FirecrawlClient.verifyWebhookSignature(
            payload: bodyBuffer,
            signature: signature,
            secret: webhookSecret
        )
    } catch FirecrawlClient.WebhookSignatureError.invalidSignature {
        context.logger.error("Webhook signature verification failed")
        throw HTTPError(.unauthorized, message: "Invalid webhook signature")
    } catch {
        context.logger.error("Webhook verification error: \(error)")
        throw HTTPError(.badRequest, message: "Signature verification failed")
    }

    // Parse the verified webhook payload
    let webhook: CrawlWebhookPayload
    do {
        webhook = try JSONDecoder().decode(CrawlWebhookPayload.self, from: bodyBuffer)
    } catch {
        context.logger.error("Failed to decode webhook payload: \(error)")
        throw HTTPError(.badRequest, message: "Invalid webhook payload")
    }

    // Process different event types
    switch webhook.type {
    case .crawlStarted:
        context.logger.info("Crawl started: \(webhook.data.jobId)")
        await handleCrawlStarted(webhook.data, context: context)

    case .crawlPage:
        context.logger.info("Page crawled: \(webhook.data.url ?? "unknown")")
        await handleCrawlPage(webhook.data, context: context)

    case .crawlCompleted:
        context.logger.info("Crawl completed: \(webhook.data.jobId)")
        await handleCrawlCompleted(webhook.data, context: context)

    case .crawlFailed:
        context.logger.error("Crawl failed: \(webhook.data.jobId)")
        await handleCrawlFailed(webhook.data, context: context)

    default:
        context.logger.warning("Unknown webhook type: \(webhook.type)")
    }

    return .ok
}

// Event handlers
@Sendable
private func handleCrawlStarted(_ data: CrawlWebhookData, context: Context) async {
    // Initialize crawl tracking in your database
    context.logger.info("Initializing crawl job: \(data.jobId)")
}

@Sendable
private func handleCrawlPage(_ data: CrawlWebhookData, context: Context) async {
    if let markdown = data.markdown, let url = data.url {
        // Process the page content
        context.logger.info("Processing content from: \(url)")
        await processPageContent(markdown, url: url, context: context)
    }
}

@Sendable
private func handleCrawlCompleted(_ data: CrawlWebhookData, context: Context) async {
    // Update database status
    await updateCrawlStatus(data.jobId, status: "completed", context: context)

    // Send notifications, trigger downstream processes, etc.
    context.logger.info("Crawl \(data.jobId) completed with \(data.completed ?? 0)/\(data.total ?? 0) pages")
}

@Sendable
private func handleCrawlFailed(_ data: CrawlWebhookData, context: Context) async {
    await updateCrawlStatus(data.jobId, status: "failed", context: context)

    if let error = data.error {
        context.logger.error("Crawl failed with error: \(error)")
    }
}

// Helper functions
@Sendable
private func processPageContent(_ markdown: String, url: String, context: Context) async {
    // Your business logic here
    context.logger.info("Content length: \(markdown.count) characters")

    // Example: Extract and store data
    // await saveToDatabase(url: url, content: markdown)
    // await indexForSearch(url: url, content: markdown)
    // await triggerAnalytics(url: url, wordCount: markdown.split(separator: " ").count)
}

@Sendable
private func updateCrawlStatus(_ jobId: String, status: String, context: Context) async {
    // Update your database
    context.logger.info("Updating job \(jobId) to status: \(status)")

    // Example database update
    // await database.update("crawl_jobs")
    //     .set("status", to: status)
    //     .set("updated_at", to: Date())
    //     .where("job_id", equals: jobId)
    //     .execute()
}
```

### Proxy & Location Support

Use different proxy types and locations:

```swift
let request = ScrapeRequest(
    url: "https://example.com",
    proxy: .stealth,  // .basic, .stealth, .auto
    location: LocationSettings(
        country: "US",
        languages: ["en-US", "en"]
    )
)
```

## Error Handling

The SDK provides comprehensive error handling:

```swift
do {
    let response = try await firecrawl.scrape(url: "https://example.com")
    // Handle success
} catch let error as FirecrawlError {
    switch error {
    case .unauthorized(let message):
        print("Authentication failed:", message ?? "Invalid API key")
    case .paymentRequired(let message):
        print("Payment required:", message ?? "")
    case .rateLimitExceeded(let message):
        print("Rate limit exceeded:", message ?? "")
    case .badRequest(let message, let validationErrors):
        print("Bad request:", message ?? "")
        validationErrors?.forEach { error in
            print("- \(error.field ?? ""): \(error.message)")
        }
    case .notFound(let message):
        print("Not found:", message ?? "")
    case .serverError(let code, let message):
        print("Server error \(code):", message ?? "")
    case .networkError(let underlyingError):
        print("Network error:", underlyingError.localizedDescription)
    default:
        print("Other error:", error.localizedDescription)
    }
}
```

## Webhook Security

Firecrawl signs every webhook request with HMAC-SHA256 to ensure authenticity. Always verify webhook signatures to prevent unauthorized requests.

### Getting Your Webhook Secret

Your webhook secret is available in the [Advanced tab](https://www.firecrawl.dev/app/settings?tab=advanced) of your Firecrawl account settings.

### Signature Verification

```swift
import Hummingbird
import Firecrawl

// In your webhook handler
@Sendable
private func handleWebhook(_ request: Request, context: Context) async throws -> HTTPResponse.Status {
    // Get the signature from headers
    guard let signature = request.headers.first(where: {
        $0.name.rawName.lowercased() == "x-firecrawl-signature"
    })?.value else {
        throw HTTPError(.unauthorized, message: "Missing signature header")
    }

    // Get the raw request body as ByteBuffer (more efficient)
    let bodyBuffer = try await request.body.collect(upTo: 1024 * 1024)

    // Your webhook secret from Firecrawl dashboard
    guard let webhookSecret = Environment.get("FIRECRAWL_WEBHOOK_SECRET") else {
        throw HTTPError(.internalServerError, message: "Missing webhook secret")
    }

    // Verify the signature - ByteBuffer is primary method
    do {
        try FirecrawlClient.verifyWebhookSignature(
            payload: bodyBuffer,  // ByteBuffer (primary method)
            signature: signature,
            secret: webhookSecret
        )
    } catch {
        // Signature verification failed
        throw HTTPError(.unauthorized, message: "Invalid webhook signature")
    }

    // Parse the verified webhook
    let webhook = try JSONDecoder().decode(CrawlWebhookPayload.self, from: bodyBuffer)

    // Process your webhook safely
    await processWebhook(webhook, context: context)

    return .ok
}
```

### Error Handling

```swift
do {
    try FirecrawlClient.verifyWebhookSignature(
        payload: bodyBuffer,  // ByteBuffer (primary) or String (convenience)
        signature: signature,
        secret: webhookSecret
    )
} catch FirecrawlClient.WebhookSignatureError.missingSignatureHeader {
    // Handle missing signature header
    context.logger.error("Missing X-Firecrawl-Signature header")
    throw HTTPError(.unauthorized, message: "Missing signature")
} catch FirecrawlClient.WebhookSignatureError.invalidSignatureFormat {
    // Handle invalid signature format (not sha256=<hash>)
    context.logger.error("Invalid signature format")
    throw HTTPError(.badRequest, message: "Invalid signature format")
} catch FirecrawlClient.WebhookSignatureError.invalidSignature {
    // Handle signature verification failure
    context.logger.error("Webhook signature verification failed")
    throw HTTPError(.unauthorized, message: "Invalid signature")
} catch {
    // Handle other errors
    context.logger.error("Webhook verification error: \(error)")
    throw HTTPError(.internalServerError, message: "Verification failed")
}
```

### Security Best Practices

1. **Always verify signatures** - Never process unverified webhook requests
2. **Use HTTPS endpoints** - Webhook URLs must use HTTPS for security
3. **Store secrets securely** - Keep your webhook secret in environment variables
4. **Use ByteBuffer for efficiency** - ByteBuffer is the primary method for best performance
5. **Implement timeouts** - Process webhooks quickly and return `2xx` status codes
6. **Respond fast** - Return within 30 seconds to avoid retries
7. **Log security events** - Log failed signature verifications for monitoring

## Advanced Configuration

### Custom HTTP Client

```swift
import AsyncHTTPClient

let httpClient = HTTPClient(
    eventLoopGroupProvider: .singleton,
    configuration: .init(
        timeout: .init(connect: .seconds(10), read: .seconds(60))
    )
)

let firecrawl = FirecrawlClient(
    apiKey: "fc-your-api-key",
    httpClient: httpClient
)

// Don't forget to shutdown
try await httpClient.shutdown()
```

### Custom Logging

```swift
import Logging

var logger = Logger(label: "firecrawl-client")
logger.logLevel = .debug

let firecrawl = FirecrawlClient(
    apiKey: "fc-your-api-key",
    logger: logger
)
```

### Batch Operations

Process multiple URLs efficiently:

```swift
let request = BatchScrapeRequest(
    urls: [
        "https://example.com/page1",
        "https://example.com/page2",
        "https://example.com/page3"
    ],
    maxConcurrency: 5,
    formats: [.markdown]
)

let batchResponse = try await firecrawl.startBatchScrape(request)

if let jobId = batchResponse.id {
    let result = try await firecrawl.waitForBatchScrapeCompletion(jobId)

    for item in result.data ?? [] {
        print("Content:", item.markdown ?? "")
    }
}
```

## Requirements

- Swift 6.0+
- macOS 14.0+ / Linux (Ubuntu 22.04+)
- Server-side Swift environment

## Dependencies

- [AsyncHTTPClient](https://github.com/swift-server/async-http-client) - High-performance HTTP client
- [swift-log](https://github.com/apple/swift-log) - Structured logging

## Testing

Run the comprehensive test suite:

```bash
swift test
```

The tests cover:
- Model serialization/deserialization for all endpoints
- Request/response validation
- Error handling scenarios
- Performance benchmarks
- API compliance verification

## Rate Limits

The Firecrawl API has rate limits to ensure service stability. When you exceed the rate limit, you'll receive a `429` response. The SDK automatically handles this with proper error types.

## Contributing

We welcome contributions! Please:

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Write tests for your changes
4. Commit your changes (`git commit -m 'Add amazing feature'`)
5. Push to the branch (`git push origin feature/amazing-feature`)
6. Open a Pull Request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Support & Resources

- 📖 [Official API Documentation](https://docs.firecrawl.dev)
- 🐛 [Report Issues](https://github.com/thoven87/firecrawl-swift-sdk/issues)
- 💬 [Discord Community]()
- 📧 [Email Support](mailto:help@firecrawl.dev)
- 🐦 [Follow us on Twitter](https://twitter.com/firecrawl_dev)

## Changelog

### v2.0.0 - Latest
- ✅ Complete Firecrawl API v2 support
- 🆕 Advanced search with multi-source support (web, images, news)
- 🆕 Comprehensive crawl options with natural language prompts
- 🆕 Team management endpoints (credits, tokens, queue status)
- 🆕 Webhook support for real-time notifications
- 🆕 Browser actions and automation
- 🆕 Batch operations for multiple URLs
- ⚡ Optimized performance with ByteBuffer decoding
- 🛡️ Swift 6 compatibility with Sendable types
- 🧪 100% test coverage with 28 test cases
- 📚 Complete API compliance verification

Built with ❤️ for the Swift community.
