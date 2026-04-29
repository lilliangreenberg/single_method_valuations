@social-media-monitoring @monitoring
Feature: Social media content monitoring
  The system captures snapshots of company Medium and blog pages and detects
  content changes over time. Posting inactivity (more than 365 days since the
  last post) is treated as a negative health signal that enriches status analysis.

  Background:
    Given companies with discovered Medium or blog URLs exist in the database
    And a valid Firecrawl API key is configured

  Rule: Social media snapshots are captured for Medium and blog pages

    @smoke
    Scenario: Capture social media snapshots for all companies
      Given companies have discovered Medium or blog URLs
      When the operator runs capture-social-snapshots
      Then a snapshot is stored for each discovered Medium and blog URL
      And a report file is written to disk

    Scenario: Capture social snapshots with a custom batch size
      Given many companies have social media URLs
      When the operator runs capture-social-snapshots with --batch-size 100
      Then URLs are processed in batches of 100

    Scenario: Capture social snapshots for a single company
      Given a company with known social media URLs exists
      When the operator runs capture-social-snapshots with --company-id
      Then only that company's social URLs are snapshotted

    Scenario: Skip manually-closed companies during social snapshot capture
      Given some companies are marked as likely_closed
      When the operator runs capture-social-snapshots without --include-manually-closed
      Then manually-closed companies are excluded

  Rule: Changes in social media content are detected and classified

    @smoke
    Scenario: Detect a content change in a Medium blog
      Given a company's Medium page has new content since the last snapshot
      When the operator runs detect-social-changes
      Then a social change record is created with has_changed set to true
      And the change magnitude and significance are recorded
      And a report file is written to disk

    Scenario: No change detected when social content is identical
      Given a company's Medium page has not changed since the last snapshot
      When the operator runs detect-social-changes
      Then a social change record is created with has_changed set to false

  Rule: Posting inactivity is treated as a negative health signal

    Scenario: Company has not posted in over 365 days
      Given a company's social media snapshot shows the most recent post is over 365 days old
      When detect-social-changes processes that company
      Then posting_inactivity is recorded as a negative indicator
      And the inactivity signal is available to the status analyser

    Scenario: Company has posted recently
      Given a company's social media snapshot shows a post within the last 30 days
      When detect-social-changes processes that company
      Then no posting inactivity signal is recorded

  Rule: Social media signals enrich homepage change detection and status analysis

    Scenario: Social context enriches LLM significance prompts
      Given a company has recent social media snapshots with posting activity
      When the operator runs detect-changes with --include-social
      Then the LLM classification prompt includes social media posting context

    Scenario: Social signals are visible in company change history
      Given a company has recorded social media change records
      When the operator runs show-changes for that company
      Then social media change records appear interleaved with homepage changes
      And each record shows its source type (MEDIUM or BLOG)
