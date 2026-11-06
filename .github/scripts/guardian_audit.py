#!/usr/bin/env python3
"""
GUARDIAN_STRATEGIST Protocol — Quarterly Dependency Audit
=========================================================
Scans dormant repositories for Dependabot security alerts
and produces a structured JSON audit report.

Usage (local):
    GH_TOKEN=<pat> ORG_OR_USER=sashasmith-syber python guardian_audit.py

Usage (CI):
    Called automatically by quarterly-dependency-audit.yml
"""

import json
import os
import sys
import datetime
import requests

# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------
GH_TOKEN    = os.environ.get("GH_TOKEN", "")
ORG_OR_USER = os.environ.get("ORG_OR_USER", "sashasmith-syber")
OUTPUT_FILE = "audit-report.json"

# Repos considered "dormant" — extend this list as needed
DORMANT_REPOS = [
    "firecrawl-swift-sdk",
]

HEADERS = {
    "Authorization": f"Bearer {GH_TOKEN}",
    "Accept": "application/vnd.github+json",
    "X-GitHub-Api-Version": "2022-11-28",
}

BASE_URL = "https://api.github.com"


# ---------------------------------------------------------------------------
# GUARDIAN_STRATEGIST scan logic
# ---------------------------------------------------------------------------
class GuardianStrategist:
    """Quarterly dependency auditor for dormant repositories."""

    def __init__(self, org_or_user: str, dormant_repos: list[str]):
        self.org_or_user  = org_or_user
        self.dormant_repos = dormant_repos
        self.results: dict = {
            "audit_date": datetime.datetime.utcnow().isoformat() + "Z",
            "audited_by": "GUARDIAN_STRATEGIST",
            "org_or_user": org_or_user,
            "repos": {},
            "summary": {
                "total_repos": len(dormant_repos),
                "repos_with_alerts": 0,
                "total_critical": 0,
                "total_high": 0,
                "total_medium": 0,
                "total_low": 0,
            },
        }

    def check_dependabot_alerts(self, repo: str) -> list[dict]:
        """Fetch open Dependabot alerts for a given repo."""
        url = f"{BASE_URL}/repos/{self.org_or_user}/{repo}/dependabot/alerts"
        params = {"state": "open", "per_page": 100}
        alerts = []
        while url:
            resp = requests.get(url, headers=HEADERS, params=params, timeout=30)
            if resp.status_code == 404:
                print(f"  [WARN] {repo}: Not found or Dependabot not enabled.")
                break
            resp.raise_for_status()
            page = resp.json()
            alerts.extend(page)
            # Follow pagination
            url = resp.links.get("next", {}).get("url")
            params = {}  # params already encoded in next URL
        return alerts

    def scan_dormant_repos(self) -> None:
        """Main scan loop — mirrors the GUARDIAN_STRATEGIST protocol."""
        print(f"[GUARDIAN_STRATEGIST] Starting quarterly audit for {self.org_or_user}")
        print(f"  Scanning {len(self.dormant_repos)} dormant repo(s)...\n")

        for repo in self.dormant_repos:
            print(f"  -> {repo}")
            alerts = self.check_dependabot_alerts(repo)

            severity_counts = {"critical": 0, "high": 0, "medium": 0, "low": 0}
            alert_summaries = []

            for alert in alerts:
                sev = (
                    alert.get("security_vulnerability", {})
                         .get("severity", "unknown")
                         .lower()
                )
                if sev in severity_counts:
                    severity_counts[sev] += 1
                alert_summaries.append({
                    "number":   alert.get("number"),
                    "package":  alert.get("dependency", {}).get("package", {}).get("name"),
                    "severity": sev,
                    "summary":  alert.get("security_advisory", {}).get("summary", ""),
                    "cve":      alert.get("security_advisory", {}).get("cve_id", ""),
                    "url":      alert.get("html_url", ""),
                })

            if alerts:
                self.results["summary"]["repos_with_alerts"] += 1
            for k in severity_counts:
                self.results["summary"][f"total_{k}"] += severity_counts[k]

            self.results["repos"][repo] = {
                "total_open_alerts": len(alerts),
                "severity_breakdown": severity_counts,
                "alerts": alert_summaries,
            }

            print(f"     Found {len(alerts)} open alert(s): {severity_counts}")

        print(f"\n[GUARDIAN_STRATEGIST] Audit complete.")
        print(f"  Summary: {self.results['summary']}")

    def write_report(self, path: str = OUTPUT_FILE) -> None:
        """Persist the audit report as JSON."""
        with open(path, "w", encoding="utf-8") as fh:
            json.dump(self.results, fh, indent=2)
        print(f"  Report written to: {path}")


# ---------------------------------------------------------------------------
# Entrypoint
# ---------------------------------------------------------------------------
def main() -> None:
    if not GH_TOKEN:
        print("[ERROR] GH_TOKEN environment variable is not set.", file=sys.stderr)
        sys.exit(1)

    auditor = GuardianStrategist(
        org_or_user=ORG_OR_USER,
        dormant_repos=DORMANT_REPOS,
    )
    auditor.scan_dormant_repos()
    auditor.write_report()

    # Exit non-zero if any critical/high alerts found (fail the CI job)
    summary = auditor.results["summary"]
    if summary["total_critical"] > 0 or summary["total_high"] > 0:
        print(
            f"\n[GUARDIAN_STRATEGIST] FAIL — "
            f"{summary['total_critical']} critical, {summary['total_high']} high alerts found.",
            file=sys.stderr,
        )
        sys.exit(1)

    print("\n[GUARDIAN_STRATEGIST] PASS — No critical or high severity alerts.")


if __name__ == "__main__":
    main()
