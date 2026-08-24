namespace :markus do
  desc 'Build the MarkUs documentation for production.'
  task docs: :environment do
    overrides = {}
    overrides['destination'] = ENV['JEKYLL_DESTINATION'] if ENV['JEKYLL_DESTINATION']
    overrides['cache_dir'] = ENV['JEKYLL_CACHE_DIR'] if ENV['JEKYLL_CACHE_DIR']

    Dir.chdir(Rails.root.join('docs')) do
      cmd = %w[bundle exec jekyll build]
      if overrides.any?
        require 'tempfile'
        Tempfile.create(['jekyll_override', '.yml']) do |f|
          f.write(overrides.to_yaml)
          f.close
          sh({ 'JEKYLL_ENV' => 'production' }, *cmd, '--config', "_config.yml,#{f.path}")
        end
      else
        sh({ 'JEKYLL_ENV' => 'production' }, *cmd)
      end
    end
  end
end
