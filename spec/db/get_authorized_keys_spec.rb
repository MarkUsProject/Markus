describe 'Check Authorized Keys Function' do
  let(:keys) do
    ActiveRecord::Base.connection.execute('SELECT get_authorized_keys()').map { |h| h['get_authorized_keys'] }
  end
  context 'no keys exist' do
    it 'returns nothing' do
      expect(keys).to be_empty
    end
  end
  context 'a key exists' do
    let!(:key_pairs) { build_list(:key_pair, 5).each { |k| k.update!(public_key: "ssh-rsa #{rand(400...50_000)}") } }
    let(:instance_name) { ENV.fetch('RAILS_RELATIVE_URL_ROOT', '/') }
    it 'returns all keys' do
      expect(keys.length).to eq 5
    end
    it 'sets the LOGIN_USER variable' do
      key_users = keys.map { |k| k.match(/(?<=LOGIN_USER=)\S+/)[0] }
      key_public_key = keys.map { |k| k.match(/ssh-rsa \d+$/)[0] }
      expect(key_users.zip(key_public_key)).to contain_exactly(*key_pairs.map { |k| [k.user.user_name, k.public_key] })
    end
    it 'sets the INSTANCE variable to the RELATIVE_URL_ROOT environment variable' do
      key_instances = keys.map { |k| k.match(/(?<=INSTANCE=)\S+/)[0] }
      expect(key_instances).to contain_exactly(*[ENV.fetch('RAILS_RELATIVE_URL_ROOT', '/')] * 5)
    end
    context 'when the relative_url_root() function has been set to something else' do
      let(:new_instance_name) { 'a_brand_new_instance_name' }
      let(:relative_root_function) do
        "CREATE OR REPLACE FUNCTION relative_url_root()
         RETURNS text AS $$SELECT text '%s'$$
         LANGUAGE sql IMMUTABLE PARALLEL SAFE;"
      end
      before { ActiveRecord::Base.connection.execute(format(relative_root_function, new_instance_name)) }
      after { ActiveRecord::Base.connection.execute(format(relative_root_function, instance_name)) }
      it 'sets the INSTANCE variable to the new instance name' do
        key_instances = keys.map { |k| k.match(/(?<=INSTANCE=)\S+/)[0] }
        expect(key_instances).to contain_exactly(*[new_instance_name] * 5)
      end
    end
    it 'sets the command' do
      expect(keys.map { |k| k.match(/command="[^"]+\s(\S+)"/)[1] }).to contain_exactly(*['markus-git-shell.sh'] * 5)
    end
    it 'sets the right flags' do
      flags = 'no-port-forwarding,no-X11-forwarding,no-agent-forwarding,no-pty'
      expect(keys.all? { |k| k.include?(flags) }).to be_truthy
    end
  end
end
