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

  Rule: CEO and founder LinkedIn profiles are discovered via the CDP browser

    Scenario: CEO profile is found on the LinkedIn company People tab
      Given a company with a LinkedIn company page exists
      And the operator is logged in to LinkedIn
      When the operator runs extract-leadership for that company
      Then CEO and founder profiles are discovered from the People tab
      And stored with discovery method cdp_scrape

    @wip
    Scenario: discover-ceo-linkedin command is disabled
      Given the operator attempts to run discover-ceo-linkedin
      When the command executes
      Then a warning is printed stating the command is disabled
      And the operator is directed to use extract-leadership instead
      And no discovery is performed

  Rule: Individual LinkedIn profiles can be inspected directly

    Scenario: Scrape a personal LinkedIn profile with DOM and Vision
      Given the operator is logged in to LinkedIn
      And a LinkedIn profile URL is known
      When the operator runs scrape-linkedin-profile with that URL
      Then the profile is opened in the CDP browser
      And DOM-extracted fields (name, headline, experience) are captured
      And a screenshot is saved to the output directory
      And when an Anthropic API key is configured Vision analysis adds current title and employer
      And results are written to a JSON file in the output directory

    Scenario: Auth wall detected when scraping without a saved session
      Given no saved LinkedIn session exists
      When the operator runs scrape-linkedin-profile for any URL
      Then the command detects the LinkedIn auth wall
      And instructs the operator to run linkedin-login first

  Rule: Employment status is verified by visiting individual profiles with Claude Vision

    @smoke
    Scenario: Vision confirms a leader is still employed at the company
      Given a company has a stored current CEO profile with a LinkedIn URL
      When the operator runs check-leadership-changes for that company
      Then the CEO's personal profile is visited via the CDP browser
      And a screenshot is analysed by Claude Vision
      And the result confirms current employment
      And the leader's last_verified_at timestamp is updated

    Scenario: Vision detects a leader has departed
      Given a company has a stored current CTO profile with a LinkedIn URL
      And that CTO's LinkedIn profile shows a different current employer
      When the operator runs check-leadership-changes for that company
      Then the CTO is marked as no longer current
      And a leadership change record is created

    Scenario: Vision identifies a wrong person match
      Given a stored leader whose LinkedIn profile belongs to a different person
      When employment verification processes that leader
      Then the leader is marked as not current with status wrong_person
      And the evidence is recorded in the leadership change record

    Scenario: LinkedIn blocks the profile visit during verification
      Given LinkedIn returns an access-blocked response for a profile URL
      When employment verification attempts to visit that profile
      Then the error is recorded with status error and confidence 0.0
      And the leader's current status is left unchanged

  Rule: Leadership mentions are reconciled against known profiles

    Scenario: Homepage names someone not in the leadership database
      Given a company homepage mentions a name not stored in company_leadership
      When the operator runs reconcile-leadership for that company
      Then that name is flagged as MISSING_IN_DB in the reconciliation report

    Scenario: Stored leader is no longer mentioned on the homepage
      Given a stored leader whose name no longer appears on the company homepage
      When the operator runs reconcile-leadership for that company
      Then that leader is flagged as STALE in the reconciliation report
