Before do
  Fixtures.reset_cache
  fixtures_folder = File.join(::Rails.root.to_s, 'test', 'fixtures')
  fixtures = Dir[File.join(fixtures_folder, '*.yml')].map {|f| File.basename(f, '.yml') }
  Fixtures.create_fixtures(fixtures_folder, fixtures)
end
