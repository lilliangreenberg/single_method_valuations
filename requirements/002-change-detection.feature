@change-detection @monitoring
Feature: Website change detection and business significance classification
  The system compares consecutive website snapshots to detect content changes
  and classifies whether each change is business-significant. Results feed the
  company status assessment and provide analysts with an auditable change log.

  Background:
    Given at least two snapshots exist for one or more companies

  Rule: Content changes are detected by checksum comparison

    @smoke
    Scenario: Detect a content change between two snapshots
      Given a company whose homepage content has changed since the last snapshot
      When the operator runs detect-changes
      Then a change record is created with has_changed set to true
      And the change record includes old and new checksums
      And a report file is written to disk

    Scenario: No change detected when content is identical
      Given a company whose homepage content has not changed since the last snapshot
      When the operator runs detect-changes
      Then a change record is created with has_changed set to false
      And no significance classification is applied

    Scenario: Detect changes for specific companies only
      Given multiple companies exist in the database
      When the operator runs detect-changes with one or more --company-id flags
      Then only the specified companies are processed

  Rule: Change magnitude is derived from the proportion of content that changed

    Scenario Outline: Change magnitude is calculated from content size difference
      Given a snapshot with <old_size> characters of content
      And a new snapshot with <new_size> characters of content
      When the operator runs detect-changes
      Then the change record has magnitude <magnitude>

      Examples:
        | old_size | new_size | magnitude |
        |     1000 |     1080 |     minor |
        |     1000 |     1400 |  moderate |
        |     1000 |     3000 |     major |

  Rule: Significance is classified using keyword matching and optional LLM validation

    @smoke
    Scenario: Classify a change as SIGNIFICANT with negative keywords
      Given a snapshot change whose new content mentions "shutdown" and "layoffs"
      When the operator runs detect-changes
      Then the change record is classified as significant
      And the sentiment is negative
      And the matched keywords are recorded

    Scenario: Classify a change as INSIGNIFICANT when only CSS or copyright changes
      Given a snapshot change whose content differences are limited to CSS class names
      When the operator runs detect-changes
      Then the change record is classified as insignificant

    Scenario: Classify a change as UNCERTAIN when evidence is ambiguous
      Given a snapshot change with one keyword match and minor magnitude
      When the operator runs detect-changes
      Then the change record is classified as uncertain
      And the confidence score is below 0.6

    Scenario: Backfill significance for existing change records
      Given change records exist without significance classifications
      When the operator runs backfill-significance
      Then significance is computed and stored for each unclassified record

    Scenario: Preview backfill without writing
      Given change records exist without significance classifications
      When the operator runs backfill-significance with --dry-run
      Then the command reports how many records would be updated
      And no database writes occur

  Rule: Analysts can query and filter the change log

    Scenario: List significant changes within a time window
      Given significant change records exist within the last 180 days
      When the operator runs list-significant-changes --days 180
      Then the companies and their sentiment are displayed

    Scenario: Filter significant changes by sentiment
      Given significant change records with both positive and negative sentiment exist
      When the operator runs list-significant-changes --sentiment negative
      Then only negative-sentiment records are displayed

    Scenario: List changes requiring manual review
      Given uncertain change records exist
      When the operator runs list-uncertain-changes
      Then each uncertain record is listed with its confidence score and notes

    Scenario: View change history for a specific company
      Given a company with recorded homepage and social media changes
      When the operator runs show-changes for that company
      Then all change records are displayed in reverse chronological order
      And related news articles are shown below the change history

    Scenario: View current status for a specific company
      Given a company with a recorded status assessment
      When the operator runs show-status for that company
      Then the status, confidence score, last-checked date, and indicators are displayed

    Scenario: List companies with recent activity
      Given some companies have content changes in the last 180 days
      When the operator runs list-active --days 180
      Then only companies with recent changes are listed

    Scenario: List companies with no recent activity
      Given some companies have not changed in the last 180 days
      When the operator runs list-inactive --days 180
      Then only inactive companies are listed

  Rule: Analyst notes guide LLM classification

    Scenario: Set analyst notes on a company
      Given a company exists in the database
      When the operator runs set-company-notes with --notes
      Then the notes are stored and returned in subsequent LLM classification prompts

    Scenario: Clear analyst notes on a company
      Given a company has existing analyst notes
      When the operator runs set-company-notes with empty --notes
      Then the notes are removed from the database
