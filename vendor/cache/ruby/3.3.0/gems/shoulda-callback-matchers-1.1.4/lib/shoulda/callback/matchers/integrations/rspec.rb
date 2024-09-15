# :enddoc:

if defined?(::ActiveRecord)
  require 'shoulda/callback/matchers/active_model'
  module RSpec::Matchers
    include Shoulda::Callback::Matchers::ActiveModel
  end
elsif defined?(::ActiveModel)
  require 'shoulda/callback/matchers/active_model'
  module RSpec::Matchers
    include Shoulda::Callback::Matchers::ActiveModel
  end
end