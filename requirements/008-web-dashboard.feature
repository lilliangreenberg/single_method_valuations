@dashboard @web-ui
Feature: Web dashboard for portfolio monitoring
  Analysts access the monitoring system through a web dashboard that surfaces
  portfolio health, recent changes, significant news, leadership data, and risk
  signals in a single view. The dashboard reads from the same SQLite database
  that the CLI populates, presenting live data without requiring CLI access.

  Rule: The dashboard launches and serves authenticated users

    @smoke
    Scenario: Launch the dashboard and open the browser
      Given the monitoring database contains company data
      When the operator runs the dashboard command
      Then a web server starts on the configured host and port
      And a browser window opens to the overview page

    Scenario: Dashboard requires Google OAuth login when OAuth is configured
      Given Google OAuth credentials are set in the environment
      And the operator has not authenticated
      When the operator navigates to the dashboard
      Then they are redirected to the login page
      And a "Sign in with Google" button is displayed

    Scenario: Operator authenticates via Google OAuth
      Given the operator clicks "Sign in with Google"
      When they complete the Google consent flow
      Then they are redirected to the dashboard overview page
      And their name is recorded as the operator for subsequent audit attribution

    Scenario: Operator logs out
      Given the operator is authenticated
      When the operator logs out
      Then their session is cleared
      And they are redirected to the login page

  Rule: The overview page shows portfolio-wide health at a glance

    @smoke
    Scenario: View the overview dashboard
      Given company data, changes, and statuses exist in the database
      When an authenticated analyst views the overview page
      Then the page displays a changes widget showing recent homepage changes
      And an alerts widget highlighting significant changes
      And a trending chart of change activity over time
      And a freshness widget showing snapshot age across the portfolio
      And a company health grid with per-company status indicators

  Rule: The companies view lists all portfolio companies with their status

    Scenario: View all companies with their current status
      Given companies with assessed statuses exist in the database
      When the analyst navigates to the companies page
      Then each company is listed with its status, last snapshot date, and homepage URL

    Scenario: Filter companies by status
      Given companies with operational and likely_closed statuses exist
      When the analyst filters the company list to show only likely_closed companies
      Then only likely_closed companies are displayed

  Rule: The changes view shows recent content changes across the portfolio

    Scenario: View recent significant changes
      Given significant change records exist from the last 30 days
      When the analyst navigates to the changes page
      Then significant changes are listed with company name, sentiment, and date

    Scenario: View the full change history for a company
      Given a company with multiple change records exists
      When the analyst navigates to that company's change detail page
      Then all change records are shown in reverse chronological order
      And related news articles are shown below the changes

  Rule: The news view shows verified news articles

    Scenario: View recent news articles across the portfolio
      Given verified news articles exist in the database
      When the analyst navigates to the news page
      Then news articles are listed with title, source, company, and significance

  Rule: The leadership view shows current executives per company

    Scenario: View leadership for a company
      Given a company with stored leadership profiles exists
      When the analyst navigates to that company's leadership page
      Then current executives are listed with their name, title, and LinkedIn URL

  Rule: The risk surface highlights cross-domain blind spots

    @smoke
    Scenario: View the risk surface page
      Given companies with statuses, news, leadership changes, and change records exist
      When the analyst navigates to the risk page
      Then status-vs-news contradictions are displayed
        (companies marked operational despite significant-negative news)
      And recent critical leadership departures are listed
      And change-frequency anomalies are shown
        (companies with spikes or droughts vs their historical baseline)

  Rule: The full monitoring pipeline can be triggered from the dashboard

    Scenario: Trigger a full scan from the dashboard
      Given the analyst is authenticated on the dashboard
      When they trigger a full scan operation
      Then the pipeline runs: snapshots, change detection, news search, status analysis
      And a summary of each stage result is returned
