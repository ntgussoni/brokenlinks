Feature: Crawler

  Scenario: Basic test
    When I run `check-links -u http://www.google.com --json --print=false`
    Then the output should pass with JSON
