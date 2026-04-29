@news-monitoring
Feature: News monitoring with Kagi search
  The system searches for news articles mentioning portfolio companies, verifies
  each article is genuinely about the company (not a name collision), and
  classifies the business significance of verified articles. Results enrich the
  company change history view and status analysis.

  Background:
    Given a valid Kagi API key is configured
    And companies exist in the local database

  Rule: News articles are fetched and verified before storage

    @smoke
    Scenario: Search news for a single company
      Given a company named "Modal Labs" exists in the database
      When the operator runs search-news --company-name "Modal Labs"
      Then Kagi is queried for recent articles mentioning "Modal Labs"
      And verified articles are stored in the news_articles table
      And the summary reports how many articles were found and stored

    Scenario: Search news for a company by ID
      Given a company with ID 42 exists in the database
      When the operator runs search-news --company-id 42
      Then news articles are fetched and stored for that company

    Scenario: Search news for all companies in parallel
      Given multiple companies exist in the database
      When the operator runs search-news-all
      Then news is searched for every company using parallel Kagi API calls
      And a report file is written to disk

    Scenario: Skip manually-closed companies in batch news search
      Given some companies are marked as likely_closed
      When the operator runs search-news-all without --include-manually-closed
      Then manually-closed companies are excluded from the search

    Scenario: Kagi API key not configured
      Given no KAGI_API_KEY is set in the environment
      When the operator runs search-news
      Then the command exits with an error indicating the missing API key

  Rule: Articles are verified as genuinely about the company before storage

    Scenario: Article is verified via logo similarity
      Given a news article whose thumbnail matches the company's stored logo
      When the news monitor processes that article
      Then the article is stored with high match confidence
      And logo_matched is recorded as a verification signal

    Scenario: Article is rejected due to low company match confidence
      Given a news article that only shares a common word with the company name
      When the news monitor processes that article
      Then the article is not stored in the database

    Scenario: Duplicate article URL is not stored twice
      Given an article URL already stored for a company
      When the same URL is returned by a subsequent Kagi search
      Then the duplicate is silently ignored and no new record is created

  Rule: Verified articles are classified by business significance

    Scenario: News article is classified as significant with negative signal
      Given a verified news article mentioning "bankruptcy" and "shutdown"
      When significance analysis runs on that article
      Then the article is classified as significant with negative sentiment

    Scenario: News article is classified as insignificant
      Given a verified news article about a minor product update with no keywords
      When significance analysis runs on that article
      Then the article is classified as insignificant

  Rule: News integrates with the company change history view

    Scenario: Related news appears in company change history
      Given a company with stored news articles
      When the operator runs show-changes for that company
      Then up to 10 recent news articles are displayed below the change records
