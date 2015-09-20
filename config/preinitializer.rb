begin
  require "rubygems"
  require "bundler"
rescue LoadError
  raise "Could not load the bundler gem. Install it with `gem install bundler`."
end

if Gem::Version.new(Bundler::VERSION) <= Gem::Version.new("1.3.5")
  raise RuntimeError, "Your bundler version is too old." +
   "Run `gem install bundler` to upgrade."
end

begin
  # Set up load paths for all bundled gems
  if ENV["BUNDLE_GEMFILE"].nil?
    # Use default Gemfile
    ENV["BUNDLE_GEMFILE"] = File.expand_path("../../Gemfile", __FILE__)
  end
  Bundler.setup
rescue Bundler::GemNotFound
  raise RuntimeError, "Bundler couldn't find some gems." +
    "Did you run `bundle install`?"
end
