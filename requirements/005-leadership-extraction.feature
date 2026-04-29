@leadership-extraction
Feature: LinkedIn leadership extraction and change detection
  The system extracts CEO, founder, and executive profiles from LinkedIn using a
  persistent Chrome session, classifies title seniority, detects departures, and
  stores profiles for downstream status analysis. Critical departures (CEO,
  founder, CTO, COO) are surfaced immediately at command output.

  Rule: Operators authenticate to LinkedIn via a persistent browser session

    @smoke
    Scenario: Log in to LinkedIn manually and save the session
      Given a Chrome browser profile directory is configured
      When the operator runs linkedin-login and completes manual sign-in
      Then session cookies are persisted to the browser profile directory
      And subsequent extract-leadership commands reuse the saved session

    Scenario: LinkedIn requires authentication before profile extraction
      Given no saved LinkedIn session exists in the browser profile
      When the operator runs extract-leadership for any company
      Then the command detects the auth wall and instructs the operator to run linkedin-login first

  Rule: Leadership profiles are extracted and stored per company

    @smoke
    Scenario: Extract leadership for a single company
      Given a company with a LinkedIn company page exists
      And the operator is logged in to LinkedIn
      When the operator runs extract-leadership for that company
      Then CEO, founder, and senior executive profiles are stored in company_leadership
      And each profile includes person name, title, and LinkedIn URL
      And the discovery method is recorded as cdp_scrape

    Scenario: Kagi search is used as a fallback when LinkedIn blocks access
      Given LinkedIn is blocking the Chrome browser for a company
      And a Kagi API key is configured
      When the operator runs extract-leadership for that company
      Then leadership profiles are discovered via Kagi search instead
      And the discovery method is recorded as kagi_search

    Scenario: Extract leadership for all companies
      Given multiple companies exist in the database
      When the operator runs extract-leadership-all
      Then leadership extraction is attempted for every active company
      And a report file is written to disk

    Scenario: Re-running extraction updates the last_verified_at timestamp
      Given a company already has leadership profiles stored from a previous run
      When the operator runs extract-leadership for that company again
      Then the existing profiles have their last_verified_at timestamp updated
      And no duplicate profiles are created

  Rule: Leadership departures are detected and classified by severity

    Scenario: CEO departure is detected and flagged as critical
      Given a company has a stored CEO profile marked as current
      And that CEO's profile no longer appears on the company LinkedIn page
      When the operator runs check-leadership-changes for that company
      Then a leadership change record is created with type CEO_DEPARTURE
      And the change is flagged as critical in the command output

    Scenario Outline: Leadership departure severity by title
      Given a company has a stored leader with title <title>
      And that leader is no longer found on the company LinkedIn page
      When check-leadership-changes processes that company
      Then the change is classified with severity <severity>

      Examples:
        | title   | severity |
        | CEO     | critical |
        | Founder | critical |
        | CTO     | critical |
        | COO     | critical |
        | VP      | notable  |

  Rule: CEO and founder LinkedIn profiles are discoverable via Kagi search

    Scenario: Discover CEO LinkedIn URL via Kagi
      Given a company has a leadership mention on its homepage naming a CEO
      And a Kagi API key is configured
      When the operator runs discover-ceo-linkedin for that company
      Then a LinkedIn profile URL is found and stored in both company_leadership and social_media_links
      And the discovery method is kagi_ceo_search

    Scenario: Dry-run shows what would be discovered without writing
      Given companies with homepage leadership mentions exist
      When the operator runs discover-ceo-linkedin with --dry-run
      Then the command reports what would be discovered
      And no database writes occur

  Rule: Leadership mentions are reconciled against known profiles

    Scenario: Homepage names someone not in the leadership database
      Given a company homepage mentions a name not stored in company_leadership
      When the operator runs reconcile-leadership for that company
      Then that name is flagged as MISSING_IN_DB in the reconciliation report

    Scenario: Stored leader is no longer mentioned on the homepage
      Given a stored leader whose name no longer appears on the company homepage
      When the operator runs reconcile-leadership for that company
      Then that leader is flagged as STALE in the reconciliation report
