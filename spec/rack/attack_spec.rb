require 'rack/mock'

describe Rack::Attack do
  let(:throttle) { Rack::Attack.configuration.throttles.fetch('login/user+ip') }

  before do
    Rack::Attack.reset!
  end

  after do
    Rack::Attack.reset!
  end

  def login_request(username:, password:, ip:)
    env = Rack::MockRequest.env_for(
      '/',
      method: 'POST',
      input: URI.encode_www_form(user_login: username, user_password: password)
    )
    env['REMOTE_ADDR'] = ip
    Rack::Attack::Request.new(env)
  end

  it 'throttles the sixth login attempt for the same username and IP' do
    results = Array.new(6) do
      throttle.matched_by?(
        login_request(username: 'TestUser', password: 'wrong', ip: '203.0.113.10')
      )
    end

    expect(results).to eq([false, false, false, false, false, true])
  end

  it 'does not share the limit across different IP addresses' do
    5.times do
      throttle.matched_by?(
        login_request(username: 'TestUser', password: 'wrong', ip: '203.0.113.10')
      )
    end

    result = throttle.matched_by?(
      login_request(username: 'TestUser', password: 'wrong', ip: '203.0.113.11')
    )

    expect(result).to be(false)
  end

  it 'does not share the limit across different usernames' do
    5.times do
      throttle.matched_by?(
        login_request(username: 'FirstUser', password: 'wrong', ip: '203.0.113.10')
      )
    end

    result = throttle.matched_by?(
      login_request(username: 'SecondUser', password: 'wrong', ip: '203.0.113.10')
    )

    expect(result).to be(false)
  end

  it 'does not throttle login POSTs with blank credentials' do
    result = throttle.matched_by?(
      login_request(username: '  ', password: '', ip: '203.0.113.10')
    )

    expect(result).to be(false)
  end
end
