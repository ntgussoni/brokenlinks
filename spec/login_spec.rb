# frozen_string_literal: true

require 'broken_links'
require 'webmock/rspec'

describe BrokenLinks::Login do
  before do
    stub_request(:get, 'http://www.example.com/login')
      .to_return(status: 200, headers: { 'Set-Cookie' => 'abc;123;' }, body: '')

    stub_request(:post, 'http://www.example.com/login')
      .to_return(status: 200, headers: { 'Set-Cookie' => 'somerandomcookie;' }, body: '')
  end

  context 'when i need to login' do
    let(:cookies) { BrokenLinks::Login.new(login_url: 'http://www.example.com/login', username: 'john', password: '1234').do_login }

    it 'succeeds and gets the cookies' do
      expect(cookies).to eq('somerandomcookie;')
    end
  end
end
