@pipeline @orchestration
Feature: End-to-end monitoring pipeline
  The full monitoring pipeline executes all four data collection and analysis
  stages in a single command, sharing one database connection and accumulating
  per-stage summaries. Each stage fails gracefully so subsequent stages still
  run even when one stage encounters errors.

  Rule: The pipeline executes all stages in order

    @smoke
    Scenario: Run the full pipeline with all stages
      Given companies with homepage URLs exist in the database
      And Firecrawl, Kagi, and Anthropic API keys are configured
      When the operator runs run-full-scan
      Then stage 1 captures website snapshots in batch mode
      And stage 2 detects content changes with significance analysis
      And stage 3 searches news via Kagi for all companies
      And stage 4 recomputes company statuses from all available signals
      And a unified summary of all four stages is printed

    Scenario: A stage failure does not abort subsequent stages
      Given the Kagi API is unavailable during stage 3
      When the operator runs run-full-scan
      Then stages 1, 2, and 4 complete successfully
      And stage 3 is reported as errored in the summary
      And the pipeline does not exit early

    Scenario: Skip individual stages via flags
      Given the operator wants to rerun only the news and status stages
      When the operator runs run-full-scan with --skip-snapshots --skip-changes
      Then only stage 3 (news) and stage 4 (status) execute

  Rule: Manually-closed companies are excluded from all pipeline stages by default

    Scenario: Manually-closed companies are excluded from the pipeline
      Given some companies are marked as likely_closed by an analyst
      When the operator runs run-full-scan
      Then manually-closed companies are excluded from all four stages
      And the exclusion count is reported in the summary

  Rule: Status analysis runs last to incorporate fresh news and leadership data

    Scenario: Status analysis incorporates news found in the same run
      Given a company with no prior news records
      When the operator runs run-full-scan
      Then stage 3 stores news articles for that company
      And stage 4 reads those articles when computing status
      And the status decision reflects the newly found news
