import Foundation

// MARK: - Spark Model (v2.8.0)

/// Spark model family for /agent: Fast (instant), Mini (default, 60% lower cost), Pro (complex research).
public enum SparkModel: String, Codable, CaseIterable, Sendable {
    /// Instant retrieval (Playground); use for parallel agents.
    case fast = "spark-1-fast"
    /// Default; everyday extraction at lower cost.
    case mini = "spark-1-mini"
    /// Complex multi-domain research, maximum accuracy.
    case pro = "spark-1-pro"
}

// MARK: - Agent Webhook (v2.8.0)

/// Webhook configuration for async /agent notifications.
public struct AgentWebhook: Codable, Sendable {
    /// HTTPS endpoint to receive events.
    public let url: String
    /// Optional headers sent with webhook requests.
    public let headers: [String: String]?
    /// Optional metadata included in payloads.
    public let metadata: [String: String]?
    /// Events to receive: started, action, completed, failed, cancelled.
    public let events: [AgentWebhookEvent]?

    public init(
        url: String,
        headers: [String: String]? = nil,
        metadata: [String: String]? = nil,
        events: [AgentWebhookEvent]? = nil
    ) {
        self.url = url
        self.headers = headers
        self.metadata = metadata
        self.events = events
    }
}

public enum AgentWebhookEvent: String, Codable, CaseIterable, Sendable {
    case started
    case action
    case completed
    case failed
    case cancelled
}

// MARK: - Agent Request

/// Request body for POST /v2/agent.
public struct AgentRequest: Codable, Sendable {
    /// The prompt describing what data to extract (max 10,000 characters).
    public let prompt: String
    /// Optional URLs to constrain the agent to.
    public let urls: [String]?
    /// Optional JSON schema to structure the extracted data.
    public let schema: [String: JSONValue]?
    /// Model: spark-1-mini (default) or spark-1-pro, spark-1-fast.
    public let model: SparkModel?
    /// Maximum credits to spend; default 2500.
    public let maxCredits: Int?
    /// If true, agent only visits URLs in `urls`.
    public let strictConstrainToURLs: Bool?
    /// Webhook for async completion/progress (v2.8.0).
    public let webhook: AgentWebhook?

    public init(
        prompt: String,
        urls: [String]? = nil,
        schema: [String: JSONValue]? = nil,
        model: SparkModel? = nil,
        maxCredits: Int? = nil,
        strictConstrainToURLs: Bool? = nil,
        webhook: AgentWebhook? = nil
    ) {
        self.prompt = prompt
        self.urls = urls
        self.schema = schema
        self.model = model
        self.maxCredits = maxCredits
        self.strictConstrainToURLs = strictConstrainToURLs
        self.webhook = webhook
    }

    enum CodingKeys: String, CodingKey {
        case prompt
        case urls
        case schema
        case model
        case maxCredits
        case strictConstrainToURLs
        case webhook
    }
}

// MARK: - Agent Start Response (POST /v2/agent)

/// Response when starting an agent task (returns job id).
public struct AgentStartResponse: FirecrawlResponse, Sendable {
    public let success: Bool
    /// Job ID for polling or webhook correlation.
    public let id: String?

    public init(success: Bool, id: String? = nil) {
        self.success = success
        self.id = id
    }
}

// MARK: - Agent Status / Result (GET /v2/agent/:id)

/// Status and result of an agent job (v2.8.0 includes model in response).
public struct AgentStatusResponse: Codable, Sendable {
    public let status: JobStatus
    /// Model used for this job (e.g. spark-1-mini).
    public let model: String?
    /// Extracted data when status is completed.
    public let data: AgentResultData?
    /// Credits used.
    public let creditsUsed: Int?

    public init(
        status: JobStatus,
        model: String? = nil,
        data: AgentResultData? = nil,
        creditsUsed: Int? = nil
    ) {
        self.status = status
        self.model = model
        self.data = data
        self.creditsUsed = creditsUsed
    }

    enum CodingKeys: String, CodingKey {
        case status
        case model
        case data
        case creditsUsed
    }
}

/// Extracted result from a completed agent job.
public struct AgentResultData: Codable, Sendable {
    /// Structured extract matching optional schema.
    public let extract: [String: JSONValue]?
    /// Raw or markdown content if requested.
    public let markdown: String?
    public let html: String?

    public init(
        extract: [String: JSONValue]? = nil,
        markdown: String? = nil,
        html: String? = nil
    ) {
        self.extract = extract
        self.markdown = markdown
        self.html = html
    }
}

// MARK: - AgentResponse (convenience type for completed agent result)

/// Convenience type for a completed agent run (success + data).
public struct AgentResponse: Sendable {
    public let success: Bool
    public let jobId: String
    public let status: JobStatus
    public let model: String?
    public let data: AgentResultData?
    public let creditsUsed: Int?

    public init(
        success: Bool,
        jobId: String,
        status: JobStatus,
        model: String? = nil,
        data: AgentResultData? = nil,
        creditsUsed: Int? = nil
    ) {
        self.success = success
        self.jobId = jobId
        self.status = status
        self.model = model
        self.data = data
        self.creditsUsed = creditsUsed
    }
}
