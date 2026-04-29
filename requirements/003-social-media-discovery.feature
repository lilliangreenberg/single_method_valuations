@social-media-discovery @discovery
Feature: Social media and blog link discovery
  The system discovers company social media profiles and blog URLs by scraping
  homepage content, where footer and header regions contain 90% of social links.
  Discovered links are stored with platform classification and verification status
  to enable downstream social media content monitoring.

  Background:
    Given companies with homepage URLs exist in the database
    And a valid Firecrawl API key is configured

  Rule: Social links are extracted from homepage content via batch scraping

    @smoke
    Scenario: Discover social media links for all companies
      Given multiple companies have homepage URLs
      When the operator runs discover-social-media
      Then social media links are extracted and stored for each company
      And each link is classified by platform (LinkedIn, Twitter, GitHub, etc.)
      And a report file is written to disk

    Scenario: Discover social media links with a custom batch size
      Given more than 50 companies have homepage URLs
      When the operator runs discover-social-media with --batch-size 100
      Then companies are processed in batches of 100 URLs per Firecrawl call

    Scenario: Discover social media links for a single company
      Given a company with a known ID exists in the database
      When the operator runs discover-social-media with --company-id
      Then only that company is processed

    Scenario: Skip manually-closed companies during discovery
      Given some companies are marked as likely_closed
      When the operator runs discover-social-media without --include-manually-closed
      Then manually-closed companies are excluded from scraping

  Rule: Full-site crawl finds additional links beyond the homepage

    Scenario: Run a full-site crawl for a single company
      Given a company with a homepage URL exists in the database
      When the operator runs discover-social-full-site for that company
      Then social media links are extracted from all crawled pages
      And the discovery method is recorded as full_site_crawl

    Scenario: Limit crawl depth and page count
      Given a company with a multi-page website exists
      When the operator runs discover-social-full-site with --max-depth 2 --max-pages 20
      Then the crawl stops after 20 pages or depth 2, whichever comes first

  Rule: Discovered links carry platform and account type metadata

    Scenario Outline: Platform is detected from profile URL
      Given a homepage containing a link to <url>
      When discover-social-media processes that homepage
      Then the stored link has platform <platform>

      Examples:
        | url                              | platform  |
        | https://twitter.com/acme         | twitter   |
        | https://github.com/acme          | github    |
        | https://linkedin.com/company/acme | linkedin |
        | https://medium.com/@acme         | medium    |
        | https://youtube.com/@acme        | youtube   |

    Scenario: Company account is distinguished from a personal account
      Given a homepage linking to a LinkedIn company page
      When discover-social-media processes that homepage
      Then the stored link has account_type company

  Rule: Company logos are extracted and stored for link verification

    Scenario: Refresh logos for all companies
      Given companies with homepage URLs exist
      When the operator runs refresh-logos
      Then logo images are extracted and stored for each company
      And stale logos older than the staleness threshold are updated

    Scenario: Force-refresh all logos regardless of age
      Given companies with recently extracted logos exist
      When the operator runs refresh-logos with --force
      Then all logos are re-extracted even if not stale

  Rule: Discovered links can be viewed per company

    Scenario: View social links and blogs for a company
      Given a company with discovered social media links and blogs
      When the operator runs show-social-links for that company
      Then all social links are displayed with platform and verification status
      And all blog URLs are displayed with their type
