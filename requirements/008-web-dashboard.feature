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

  Rule: The companies view lists all portfolio companies with rich filtering

    Scenario: View all companies with their current status
      Given companies with assessed statuses exist in the database
      When the analyst navigates to the companies page
      Then each company is listed with its status, last snapshot date, and homepage URL

    Scenario: Filter companies by status
      Given companies with operational and likely_closed statuses exist
      When the analyst filters the company list to show only likely_closed companies
      Then only likely_closed companies are displayed

    Scenario: Search companies by name
      Given companies exist in the database
      When the analyst types a partial name into the search field
      Then only companies whose names contain that substring are shown

    Scenario: Filter companies by source sheet
      Given companies from multiple Airtable source sheets exist
      When the analyst filters by a specific source sheet
      Then only companies from that sheet are listed

    Scenario: Filter companies with a manual status override
      Given some companies have manual status overrides set
      When the analyst filters by manual_override = yes
      Then only manually-overridden companies are displayed

    Scenario: Sort companies by last snapshot date
      Given companies with different last snapshot dates exist
      When the analyst sorts by last snapshot date descending
      Then companies are ordered from most recently snapshotted to oldest

    Scenario: Paginate through a large company list
      Given more than one page of companies exist
      When the analyst navigates to page 2
      Then the second page of companies is displayed
      And the total count and page number are shown

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

  Rule: Analysts can perform per-company actions from the company detail page

    Scenario: Rescrape a single company from its detail page
      Given a company detail page is open in the dashboard
      When the analyst triggers a rescrape action for that company
      Then a capture-snapshots task is started for that company ID in the background
      And the analyst can see the task progress on the page

    Scenario: Run detect-changes for a single company from its detail page
      Given a company detail page is open in the dashboard
      When the analyst triggers a detect-changes action for that company
      Then a detect-changes task is started for that company ID in the background

    Scenario: Edit analyst notes from the company detail page
      Given a company detail page is open
      When the analyst submits updated notes in the notes form
      Then the notes are saved and the updated text is displayed

    Scenario: Clear a manual status override from the company detail page
      Given a company has a manual status override set
      When the analyst clicks the clear override control on the detail page
      Then the is_manual_override flag is removed
      And subsequent analyze-status runs can update the status automatically

    Scenario: Delete a change record entry from the company detail page
      Given a company has change records displayed on its detail page
      When the analyst deletes a specific change record entry
      Then that record is removed from the database
      And the deletion is logged with the analyst's identity as performed_by

    Scenario: Delete a news article entry from the company detail page
      Given a company has news articles displayed on its detail page
      When the analyst deletes a specific news article entry
      Then that article is removed from the database
      And the deletion is logged with the analyst's identity as performed_by

  Rule: The operations panel runs CLI commands with real-time output streaming

    @smoke
    Scenario: Run the full scan from the operations panel
      Given the analyst is authenticated on the dashboard
      When they submit the run-full-scan command from the operations panel
      Then a background task is created and its ID is returned
      And the analyst can poll for status updates

    Scenario: Stream real-time CLI output for a running task
      Given a background task has been started from the operations panel
      When the analyst connects to the task stream endpoint
      Then CLI output lines are delivered via SSE as the task runs
      And a completion event is sent when the task finishes

    Scenario: Cancel a running task from the operations panel
      Given a background task is in progress
      When the analyst submits a cancel request for that task
      Then the task is terminated
      And the task status changes to cancelled

    Scenario: View task history in the operations panel
      Given previous tasks have been run from the operations panel
      When the analyst views the operations page
      Then up to 20 recent tasks are listed with their status and timestamps

    Scenario: Concurrent task limit is enforced
      Given the maximum number of concurrent tasks are already running
      When the analyst attempts to start another task
      Then an error message is displayed
      And no new task is created
