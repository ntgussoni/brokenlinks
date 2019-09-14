# frozen_string_literal: true

require 'broken_links'
require 'webmock/rspec'

describe BrokenLinks::Crawler do
  before do
    stub_request(:get, 'http://www.example.com/link-1')
      .to_return(status: 200, body: '')
    stub_request(:get, 'http://www.example.com/link-2')
      .to_return(status: 200, body: '')
    stub_request(:get, 'http://www.example.com/link-3')
      .to_return(status: 200, body: '')
    stub_request(:get, 'http://www.example.com/link-4')
      .to_return(status: 200, body: '')
  end

  it 'returns 5 valid links' do
    stub_request(:get, 'http://www.example.com')
      .to_return(status: 200, body: '
    <a href="/link-1" />
    <a href="/link-2" />
    <a href="/link-3" />
    <a href="/link-4" />
    ')

    res = JSON.parse(BrokenLinks::Crawler.new(url: 'http://www.example.com', print: false, json: true).start)
    puts res
    expect(res.count).to be(5)
  end
end
