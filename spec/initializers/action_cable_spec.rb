describe 'ActionCable Redis connector' do
  subject(:connection) { ActionCable::SubscriptionAdapter::Redis.redis_connector.call(config) }

  let(:config) do
    { adapter: 'redis', url: 'redis://localhost:6379/1', channel_prefix: 'markus_test', reconnect_attempts: [1, 2, 5] }
  end

  it 'builds publishing connections with a single immediate reconnect attempt' do
    expect(Redis).to receive(:new).with(hash_including(reconnect_attempts: 1)).and_call_original
    connection
  end

  it 'passes the rest of the cable config through to the connection' do
    expect(Redis).to receive(:new).with(hash_excluding(:adapter, :channel_prefix)).and_call_original
    expect(connection._client.config).to have_attributes(host: 'localhost', port: 6379, db: 1)
  end
end
