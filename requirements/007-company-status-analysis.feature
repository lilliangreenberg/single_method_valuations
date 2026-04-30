@status-analysis @monitoring
Feature: Multi-source company status analysis
  The system assesses whether each portfolio company is operational, likely closed,
  or uncertain. Status is derived from a weighted combination of signals: homepage
  content (copyright year, acquisition text, HTTP freshness), social media posting
  activity, recent significant news, and leadership changes. Definitive closure
  events in news can veto the weighted result and force LIKELY_CLOSED.

  Background:
    Given companies with at least one captured snapshot exist in the database

  Rule: Status is determined from confidence thresholds and indicator balance

    @smoke
    Scenario: Company is classified as operational with strong positive signals
      Given a company whose homepage has a current copyright year and was recently modified
      When the operator runs analyze-status
      Then that company's status is operational
      And the confidence is high

    Scenario: Company is classified as likely_closed with strong negative signals
      Given a company whose homepage contains "acquired by" and has a copyright year 4 years old
      When the operator runs analyze-status
      Then that company's status is likely_closed
      And the acquisition text is recorded as a negative indicator

    Scenario: Company is classified as uncertain with weak or conflicting signals
      Given a company whose homepage has no copyright year and no acquisition text
      When the operator runs analyze-status
      Then that company's status is uncertain
      And the confidence is below 0.4

    Scenario: Previous status is preserved when no new negative signals exist
      Given a company was previously classified as operational
      And the new snapshot has no negative signals
      When the operator runs analyze-status
      Then that company's status remains operational

    Scenario: Uncertain company is promoted to operational with two positive signals
      Given a company was previously classified as uncertain
      And the new snapshot has a current copyright year and a recent HTTP Last-Modified header
      When the operator runs analyze-status
      Then that company's status is upgraded to operational

  Rule: Copyright year is an indicator of site freshness

    Scenario Outline: Copyright year signal is positive, neutral, or negative
      Given a company homepage with copyright year <year>
      And the current year is 2026
      When analyze-status processes that company
      Then the copyright_year indicator has signal <signal>

      Examples:
        | year | signal   |
        | 2026 | positive |
        | 2025 | positive |
        | 2024 | neutral  |
        | 2023 | neutral  |
        | 2022 | negative |

  Rule: HTTP Last-Modified header contributes a freshness signal

    Scenario Outline: HTTP Last-Modified freshness signal
      Given a company homepage with Last-Modified <days> days ago
      When analyze-status processes that company
      Then the http_last_modified indicator has signal <signal>

      Examples:
        | days | signal   |
        |   30 | positive |
        |   90 | positive |
        |  200 | neutral  |
        |  400 | negative |

  Rule: News and leadership signals can override snapshot-based classification

    Scenario: Significant negative news forces a company to likely_closed
      Given a company with an operational snapshot
      And a verified news article stating the company filed for bankruptcy
      When the operator runs analyze-status
      Then that company's status is likely_closed
      And the news article is recorded as a veto signal

    Scenario: Critical leadership departure adds a negative indicator
      Given a company with a recent CEO_DEPARTURE change record
      When the operator runs analyze-status
      Then the leadership_departure signal is recorded as a negative indicator

  Rule: Analysts can manually override status

    Scenario: Analyst manually marks a company as likely_closed
      Given a company is currently classified as uncertain
      When an analyst sets the company status to likely_closed via the dashboard
      Then the status is stored as a manual override
      And the company is excluded from future batch snapshot capture by default

    Scenario: Analyst clears a manual status override
      Given a company has a manual status override set
      When an analyst clears the override via the dashboard
      Then the is_manual_override flag is removed
      And subsequent analyze-status runs can update the status automatically

    Scenario: Baseline signals are computed for companies without prior analysis
      Given companies exist with snapshots but no baseline signals
      When the operator runs analyze-baseline
      Then baseline positive and negative signals are computed from full page content
      And those baselines are used to contextualise future change records

    Scenario: Preview baseline analysis without writing
      Given companies exist with snapshots but no baseline signals
      When the operator runs analyze-baseline with --dry-run
      Then the command reports how many companies would be analyzed
      And no database writes occur
