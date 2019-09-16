# BrokenLinks

This gem provides a command-line tool to crawl a site and search for broken links

## Requirements

- Bundler
- Ruby v2.6.X

## Installation

Since this gem is not published you have to clone and build it first

    git clone https://github.com/ntgussoni/brokenlinks.git
    cd brokenlinks/

There's a ./build file provided

    chmod +x ./build
    ./build

or

    rake build
    gem install pkg/broken_links-0.2.0.gem

After installing there will be a check-links command available

## Usage

    check-links -u URL [--print] [--json] [--help] [--login-url] LOGIN_URL [--username] USERNAME [--password] PASWORD

#### URL

A fully formed URI _(example: http://example.com)_

#### --print

Prints colorized output to screen _(Default: true)_

#### --json

Prints output in JSON format _(Default: false)_

#### --help

Prints CLI help

## Login

#### --login-url

Login URL _(Default: "")_

#### --username

Login username _(Default: "")_

#### --password

Login password _(Default: "")_

## Development

After checking out the repo, run `bundle install` to install dependencies. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/ntgussoni/brokenlinks.
