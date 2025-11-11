import Foundation

/// Response from the credit usage endpoint
public struct CreditUsageResponse: FirecrawlResponse, Sendable {
    public let success: Bool
    public let data: CreditUsageData?

    public init(success: Bool, data: CreditUsageData? = nil) {
        self.success = success
        self.data = data
    }
}

/// Credit usage data
public struct CreditUsageData: Codable, Sendable {
    /// Number of credits remaining for the team
    public let remainingCredits: Double

    /// Number of credits in the plan (excludes coupon credits, credit packs, auto recharge)
    public let planCredits: Double

    /// Start date of the billing period (null if using free plan)
    public let billingPeriodStart: String?

    /// End date of the billing period (null if using free plan)
    public let billingPeriodEnd: String?

    public init(
        remainingCredits: Double,
        planCredits: Double,
        billingPeriodStart: String? = nil,
        billingPeriodEnd: String? = nil
    ) {
        self.remainingCredits = remainingCredits
        self.planCredits = planCredits
        self.billingPeriodStart = billingPeriodStart
        self.billingPeriodEnd = billingPeriodEnd
    }
}

/// Response from the historical credit usage endpoint
public struct HistoricalCreditUsageResponse: FirecrawlResponse, Sendable {
    public let success: Bool
    public let periods: [CreditUsagePeriod]?

    public init(success: Bool, periods: [CreditUsagePeriod]? = nil) {
        self.success = success
        self.periods = periods
    }
}

/// Credit usage period data
public struct CreditUsagePeriod: Codable, Sendable {
    /// Start date of the billing period
    public let startDate: String

    /// End date of the billing period
    public let endDate: String

    /// Name of the API key used (null if byApiKey is false)
    public let apiKey: String?

    /// Total number of credits used in the billing period
    public let totalCredits: Int

    public init(
        startDate: String,
        endDate: String,
        apiKey: String? = nil,
        totalCredits: Int
    ) {
        self.startDate = startDate
        self.endDate = endDate
        self.apiKey = apiKey
        self.totalCredits = totalCredits
    }
}

/// Response from the token usage endpoint
public struct TokenUsageResponse: FirecrawlResponse, Sendable {
    public let success: Bool
    public let data: TokenUsageData?

    public init(success: Bool, data: TokenUsageData? = nil) {
        self.success = success
        self.data = data
    }
}

/// Token usage data
public struct TokenUsageData: Codable, Sendable {
    /// Number of tokens remaining for the team
    public let remainingTokens: Double

    /// Number of tokens in the plan (excludes coupon tokens)
    public let planTokens: Double

    /// Start date of the billing period (null if using free plan)
    public let billingPeriodStart: String?

    /// End date of the billing period (null if using free plan)
    public let billingPeriodEnd: String?

    public init(
        remainingTokens: Double,
        planTokens: Double,
        billingPeriodStart: String? = nil,
        billingPeriodEnd: String? = nil
    ) {
        self.remainingTokens = remainingTokens
        self.planTokens = planTokens
        self.billingPeriodStart = billingPeriodStart
        self.billingPeriodEnd = billingPeriodEnd
    }
}

/// Response from the historical token usage endpoint
public struct HistoricalTokenUsageResponse: FirecrawlResponse, Sendable {
    public let success: Bool
    public let periods: [TokenUsagePeriod]?

    public init(success: Bool, periods: [TokenUsagePeriod]? = nil) {
        self.success = success
        self.periods = periods
    }
}

/// Token usage period data
public struct TokenUsagePeriod: Codable, Sendable {
    /// Start date of the billing period
    public let startDate: String

    /// End date of the billing period
    public let endDate: String

    /// Name of the API key used (null if byApiKey is false)
    public let apiKey: String?

    /// Total number of tokens used in the billing period
    public let totalTokens: Int

    public init(
        startDate: String,
        endDate: String,
        apiKey: String? = nil,
        totalTokens: Int
    ) {
        self.startDate = startDate
        self.endDate = endDate
        self.apiKey = apiKey
        self.totalTokens = totalTokens
    }
}

/// Response from the queue status endpoint
public struct QueueStatusResponse: FirecrawlResponse, Sendable {
    public let success: Bool
    public let jobsInQueue: Double?
    public let activeJobsInQueue: Double?
    public let waitingJobsInQueue: Double?
    public let maxConcurrency: Double?
    public let mostRecentSuccess: String?

    public init(
        success: Bool,
        jobsInQueue: Double? = nil,
        activeJobsInQueue: Double? = nil,
        waitingJobsInQueue: Double? = nil,
        maxConcurrency: Double? = nil,
        mostRecentSuccess: String? = nil
    ) {
        self.success = success
        self.jobsInQueue = jobsInQueue
        self.activeJobsInQueue = activeJobsInQueue
        self.waitingJobsInQueue = waitingJobsInQueue
        self.maxConcurrency = maxConcurrency
        self.mostRecentSuccess = mostRecentSuccess
    }
}
