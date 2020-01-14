# When subversion is used, we require the svn ruby bindings.
if Rails.configuration.x.repository.type == 'svn'
  require 'svn/repos'
  require 'svn/client'
end
