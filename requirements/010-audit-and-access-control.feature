@audit @access-control
Feature: Operator identity attribution and access control
  Every database write records the identity of the operator who performed it.
  When Google OAuth is configured, operators must authenticate before running
  CLI commands or accessing the dashboard. All audit attribution uses the
  authenticated user's name rather than the OS username.

  Rule: Every database write records performed_by

    @smoke
    Scenario: CLI command attributes writes to the authenticated operator
      Given the operator is authenticated via Google OAuth as "Jane Smith"
      When the operator runs any command that writes to the database
      Then all new and updated rows include performed_by "Jane Smith"

    Scenario: CLI command falls back to OS username when OAuth is not configured
      Given no Google OAuth credentials are set in the environment
      When the operator runs any command that writes to the database
      Then all new and updated rows include performed_by set to the OS username

    Scenario: Backfill NULL performed_by values after an upgrade
      Given some existing rows have NULL in the performed_by column
      When the operator runs backfill-performed-by --operator "Lily"
      Then every NULL performed_by across all tables is set to "Lily"
      And the total number of updated rows is reported

  Rule: Google OAuth login is required when OAuth is configured

    Scenario: CLI command exits when OAuth is configured but user is not logged in
      Given Google OAuth credentials are set in the environment
      And the operator has not run the login command
      When the operator runs any CLI command
      Then the command exits with an error message
      And the message instructs the operator to run 'airtable-extractor login'

    Scenario: Operator logs in and subsequent commands succeed
      Given Google OAuth credentials are set in the environment
      When the operator runs the login command and completes the OAuth flow
      Then credentials are stored in data/auth.json
      And subsequent CLI commands resolve the operator name from stored credentials

    Scenario: Operator logs out of the CLI
      Given the operator has stored credentials in data/auth.json
      When the operator runs the logout command
      Then stored credentials are cleared from data/auth.json
      And the command confirms the logout

    Scenario: Operator checks who is currently authenticated
      Given the operator is authenticated as "Jane Smith"
      When the operator runs the whoami command
      Then the command displays the name and email of the authenticated user

    Scenario: Whoami reports system user when OAuth is not configured
      Given no Google OAuth credentials are set in the environment
      When the operator runs the whoami command
      Then the command reports that OAuth is not configured
      And displays the OS system username

  Rule: Dashboard operator identity passes through to CLI subprocess calls

    Scenario: Dashboard triggers a pipeline run attributed to the logged-in analyst
      Given an analyst is authenticated on the dashboard as "Jane Smith"
      When the analyst triggers a pipeline operation from the dashboard
      Then the CLI subprocess receives OPERATOR_OVERRIDE="Jane Smith"
      And all writes from that pipeline run record performed_by "Jane Smith"
