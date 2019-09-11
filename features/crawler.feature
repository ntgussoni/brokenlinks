Feature: Crawler

  Scenario: Basic test
    When I run `check-links find -u http://www.google.com`
    Then the output should contain "pass!"
