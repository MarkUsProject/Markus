# When subversion is used, we require the svn ruby bindings.
if Settings.repository.type == 'svn'
  require 'svn/repos'
  require 'svn/client'
end
