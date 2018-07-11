# When subversion is used, we require the svn ruby bindings.

if MarkusConfigurator.markus_config_repository_type == 'svn'
  require 'svn/repos'
  require 'svn/client'
end
