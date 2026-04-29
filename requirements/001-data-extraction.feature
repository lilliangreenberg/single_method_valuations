@data-extraction
Feature: Portfolio company data extraction and snapshot capture
  Analysts need an accurate local copy of the portfolio company list and their
  website content to support all downstream monitoring workflows. This feature
  covers pulling company records from Airtable and capturing point-in-time
  website snapshots via Firecrawl.

  Background:
    Given valid Airtable and Firecrawl API credentials are configured
    And the local SQLite database has been initialised

  Rule: Company extraction mirrors Airtable

    @smoke
    Scenario: Extract all companies from Airtable
      Given companies exist in the Airtable base
      When the operator runs the extract-companies command
      Then all companies are stored in the local database
      And the summary reports how many companies were extracted

    Scenario: Airtable is unreachable during extraction
      Given the Airtable API is unavailable
      When the operator runs the extract-companies command
      Then the command exits with an error message
      And no partial records are written

    Scenario: Import social media and blog URLs from Airtable
      Given companies have social media and blog URLs recorded in Airtable
      When the operator runs the import-urls command
      Then those URLs are stored in the local social_media_links table

  Rule: Website snapshots are captured and stored with checksums

    @smoke
    Scenario: Capture snapshots for all companies sequentially
      Given at least one company with a homepage URL exists in the database
      When the operator runs capture-snapshots in sequential mode
      Then a markdown snapshot is stored for each company
      And each snapshot includes an MD5 checksum
      And a report file is written to disk

    Scenario: Capture snapshots using the batch API
      Given multiple companies with homepage URLs exist in the database
      When the operator runs capture-snapshots with the --use-batch-api flag
      Then snapshots are captured in parallel batches
      And the batch summary reports successful and failed captures

    Scenario: Capture a snapshot for a single company
      Given a company with a known ID exists in the database
      When the operator runs capture-snapshots with --company-id
      Then only that company's snapshot is captured and stored

    Scenario: Skip companies that already have a recent snapshot
      Given some companies have snapshots captured after a given date
      When the operator runs capture-snapshots with --skip-if-snapshot-since
      Then companies with recent snapshots are excluded from capture
      And the summary reports how many companies were skipped

    Scenario: Skip manually-closed companies by default
      Given some companies are marked as likely_closed by an analyst
      When the operator runs capture-snapshots without --include-manually-closed
      Then manually-closed companies are excluded from the batch
      And the summary reports how many companies were excluded

    Scenario: Company not found for single-company capture
      Given no company exists with the requested ID
      When the operator runs capture-snapshots with that --company-id
      Then the command exits with an error message indicating the company was not found
