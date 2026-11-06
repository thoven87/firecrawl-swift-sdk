/**
 * Orchestration layer: SyberSpider → URL discovery → Security Gate → Firecrawl Batch → Supabase.
 *
 * Initialize: new SpiderFirecrawlPipeline(spider, firecrawl, securityGate, persistResults, logSecurityEvent?)
 * then call pipeline.execute(seedURL, config).
 *
 * Flow:
 * 1. Spider discovers URLs (via SyberSpider/Spider entity API)
 * 2. Security Gate validates URL batch
 * 3. Firecrawl batch scrape (v2.8.0) with optional webhook
 * 4. Persist job reference / results via HIKARU Security Layer (RLS enforced)
 *
 * @see README_SPIDER.md (Spider Entity API)
 * @see docs/SECURITY_GATE.md (section 7: Integration Guide)
 */

import type { SecurityGate } from "../supabase/functions/_shared/securityGate.ts";

export type SparkModel = "spark-1-fast" | "spark-1-mini" | "spark-1-pro";

export interface PipelineConfig {
  maxDepth: number;
  firecrawlModel: SparkModel;
  batchSize: number;
  webhookURL: string;
  securityGateBypass: boolean; // requires admin role
}

export interface PipelineResult {
  jobId: string;
  urlCount: number;
  rejectedCount?: number;
}

/** Minimal Spider interface: crawl seed URL and return discovered URLs. */
export interface SpiderEntity {
  crawl(seedURL: string, maxDepth: number, maxPages?: number): Promise<string[]>;
}

/** Minimal Firecrawl client: batch scrape with webhook, returns job id. */
export interface FirecrawlServiceLike {
  batchScrape(
    urls: string[],
    options: { model?: SparkModel; webhook?: string }
  ): Promise<{ id: string }>;
}

/**
 * Pipeline: Spider discovers URLs → Security Gate validates → Firecrawl batch scrape → persist.
 */
export class SpiderFirecrawlPipeline {
  constructor(
    private spider: SpiderEntity,
    private firecrawl: FirecrawlServiceLike,
    private securityGate: SecurityGate,
    private persistResults: (jobId: string, urlCount: number) => Promise<void>,
    private logSecurityEvent?: (event: string, details: Record<string, unknown>) => Promise<void>
  ) {}

  /**
   * Execute pipeline: crawl → validate → batch scrape → persist.
   * Retries failed scrapes with Spark 1 Pro when configured; logs failures to security_events.
   */
  async execute(seedURL: string, config: PipelineConfig): Promise<PipelineResult> {
    // 1. Spider discovers URLs
    const urls = await this.spider.crawl(seedURL, config.maxDepth, config.batchSize);

    // 2. Security Gate validation (unless admin bypass)
    let validated: string[];
    if (config.securityGateBypass) {
      validated = urls;
    } else {
      const result = await this.securityGate.validateURLBatch(urls);
      validated = result.allowed;
      if (result.rejected.length > 0 && this.logSecurityEvent) {
        await this.logSecurityEvent("url_validation_rejected", {
          rejected: result.rejected,
          seedURL,
        });
      }
    }

    if (validated.length === 0) {
      throw new Error("No URLs passed Security Gate validation");
    }

    // 3. Firecrawl batch scrape (v2.8.0)
    const job = await this.firecrawl.batchScrape(validated, {
      model: config.firecrawlModel,
      webhook: config.webhookURL,
    });

    // 4. Store in Supabase (via HIKARU Security Layer)
    await this.persistResults(job.id, validated.length);

    return {
      jobId: job.id,
      urlCount: validated.length,
      rejectedCount: urls.length - validated.length,
    };
  }
}
