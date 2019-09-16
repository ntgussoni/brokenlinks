# frozen_string_literal: true

require 'broken_links'
require 'webmock/rspec'

describe BrokenLinks::Crawler do
  before do
    stub_request(:get, 'http://www.example.com/login')
      .to_return(status: 200, headers: { 'Cookie' => 'somerandomcookie;' }, body: '')

    stub_request(:get, 'http://www.example.com/link-1')
      .to_return(status: 200, body: '')
    stub_request(:get, 'http://www.example.com/link-2')
      .to_return(status: 200, body: '')
    stub_request(:get, 'http://www.example.com/link-3')
      .to_return(status: 200, body: '')
    stub_request(:get, 'http://www.example.com/link-4')
      .to_return(status: 200, body: '')
    stub_request(:get, 'http://www.example.com/nested-link-1')
      .to_return(status: 200, body: '')
    stub_request(:get, 'http://www.example.com/nested-link-2')
      .to_return(status: 200, body: '')
    stub_request(:get, 'http://www.example.com/nested-link-3')
      .to_return(status: 200, body: '')
    stub_request(:get, 'http://www.example.com/absolute-link')
      .to_return(status: 200, body: '')

    stub_request(:get, 'http://www.example.com/invalid')
      .to_return(status: 404, body: '')
  end

  let(:res) { JSON.parse(BrokenLinks::Crawler.new(url: 'http://www.example.com', print: false, json: true).start) }

  def find(url, status = nil)
    res.find do |x|
      is_same = x['url'] == "http://www.example.com/#{url}"
      return (is_same && (x['status'] == status)) unless status.nil?

      is_same
    end
  end

  context 'when an external site is found' do
    before do
      stub_request(:get, 'http://www.example.com')
        .to_return(status: 200, body: '
        <a href="http://www.some-external-site.com/" />
        ')

      stub_request(:get, 'http://www.some-external-site.com')
        .to_return(status: 200, body: '
          <a href="/external-link" />
          ')
    end

    it 'returns 2 links' do
      expect(res.count).to be(2)
    end

    it 'no external link are crawled' do
      expect(find('external-link')).to be_nil
    end
  end

  context 'When checking a site with nonrepeated links' do
    before do
      stub_request(:get, 'http://www.example.com')
        .to_return(status: 200, body: '
        <a href="/link-1" />
        <a href="/link-2" />
        <a href="/link-3" />
        <a href="/link-4" />
        <a href="http://www.example.com/absolute-link" />
        ')

      stub_request(:get, 'http://www.example.com/link-1')
        .to_return(status: 200, body: '
          <a href="/nested-link-1" />
          <a href="/nested-link-2" />
          <a href="/nested-link-3" />
          ')
    end

    it 'returns 9 links (start and children)' do
      expect(res.count).to be(9)
    end

    it 'link-1 found in http://www.example.com' do
      link = find('link-1')
      expect(link['found_in'].include?('http://www.example.com')).to be true
    end

    it 'link-2 found in http://www.example.com' do
      link = find('link-2')
      expect(link['found_in'].include?('http://www.example.com')).to be true
    end

    it 'link-3 found in http://www.example.com' do
      link = find('link-3')
      expect(link['found_in'].include?('http://www.example.com')).to be true
    end

    it 'link-4 found in http://www.example.com' do
      link = find('link-4')
      expect(link['found_in'].include?('http://www.example.com')).to be true
    end

    it 'nested-link-1 found in http://www.example.com/link-1' do
      link = find('nested-link-1')
      expect(link['found_in'].include?('http://www.example.com/link-1')).to be true
    end

    it 'nested-link-1nested-link-1 in http://www.example.com/link-1' do
      link = find('nested-link-1')
      expect(link['found_in'].include?('http://www.example.com/link-1')).to be true
    end

    it 'nested-link-1nested-link-1 in http://www.example.com/link-1' do
      link = find('nested-link-1')
      expect(link['found_in'].include?('http://www.example.com/link-1')).to be true
    end

    it 'absolute-link found in http://www.example.com' do
      link = find('absolute-link')
      expect(link['found_in'].include?('http://www.example.com')).to be true
    end
  end

  context 'When checking a site with repeated links' do
    before do
      stub_request(:get, 'http://www.example.com')
        .to_return(status: 200, body: '
        <a href="/link-1" />
        <a href="/link-2" />
        <a href="/link-3" />
        <a href="/link-4" />
        <a href="http://www.example.com/absolute-link" />
        ')

      stub_request(:get, 'http://www.example.com/link-1')
        .to_return(status: 200, body: '
          <a href="/nested-link-1" />
          <a href="/link-3" />
          <a href="/nested-link-3" />
          <a href="http://www.example.com/absolute-link" />
          ')
    end

    it 'returns 8 links' do
      expect(res.count).to be(8)
    end

    it 'link-3 found in http://www.example.com and http://www.example/link-1 ' do
      link = find('link-3')
      found = link['found_in'].include?('http://www.example.com') && link['found_in'].include?('http://www.example.com/link-1')
      expect(found).to be true
    end

    it 'absolute-link found in http://www.example.com and http://www.example/link-1 ' do
      link = find('absolute-link')
      found = link['found_in'].include?('http://www.example.com') && link['found_in'].include?('http://www.example.com/link-1')
      expect(found).to be true
    end
  end

  context 'When checking a site with both valid and invalid relative links' do
    before do
      stub_request(:get, 'http://www.example.com')
        .to_return(status: 200, body: '
      <a href="/link-1" />
      <a href="/link-2" />
      <a href="/invalid" />
      <a href="/link-4" />
      ')
    end

    it 'has http://www.example.com/invalid with status == error' do
      result = find('invalid', 'error')
      expect(result).not_to be_nil
    end

    it 'has http://www.example.com/link-1 with status == ok' do
      result = find('link-1', 'ok')
      expect(result).not_to be_nil
    end

    it 'has http://www.example.com/link-2 with status == ok' do
      result = find('link-2', 'ok')
      expect(result).not_to be_nil
    end

    it 'has http://www.example.com/link-4 with status == ok' do
      result = find('link-4', 'ok')
      expect(result).not_to be_nil
    end
  end

  context 'When checking links with valid redirections' do
    before do
      stub_request(:get, 'http://www.example.com')
        .to_return(status: 200, body: '
      <a href="/link-1" />
      <a href="/link-2" />
      <a href="/redirect" />
      <a href="/redirect-full" />
      <a href="/link-4" />
      ')

      stub_request(:get, 'http://www.example.com/redirected-to')
        .to_return(status: 200, body: '')

      stub_request(:get, 'http://www.example.com/redirect').to_return(status: 301, headers: { location: '/redirected-to' })
      stub_request(:get, 'http://www.example.com/redirect-full').to_return(status: 301, headers: { location: 'http://www.example.com/redirected-to' })
    end

    it 'has http://www.example.com/redirect with status == ok' do
      result = find('redirect', 'ok')
      expect(result).not_to be_nil
    end

    it 'has http://www.example.com/redirect-full with status == ok' do
      result = find('redirect-full', 'ok')
      expect(result).not_to be_nil
    end
  end

  context 'When checking links with invalid redirections' do
    before do
      stub_request(:get, 'http://www.example.com')
        .to_return(status: 200, body: '
      <a href="/link-1" />
      <a href="/link-2" />
      <a href="/redirect" />
      <a href="/redirect-full" />
      <a href="/link-4" />
      ')

      stub_request(:get, 'http://www.example.com/redirected-to')
        .to_return(status: 404, body: '')

      stub_request(:get, 'http://www.example.com/redirect').to_return(status: 301, headers: { location: '/redirected-to' })
      stub_request(:get, 'http://www.example.com/redirect-full').to_return(status: 301, headers: { location: 'http://www.example.com/redirected-to' })
    end

    it 'has http://www.example.com/redirect with status == error' do
      result = find('redirect', 'error')
      expect(result).not_to be_nil
    end

    it 'has http://www.example.com/redirect-full with status == error' do
      result = find('redirect-full', 'error')
      expect(result).not_to be_nil
    end
  end
end
