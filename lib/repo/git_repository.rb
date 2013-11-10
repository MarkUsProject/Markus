require "rugged"
require "gitolite"
require "digest/md5"
require File.join(File.dirname(__FILE__),'repository') # load repository module

module Repository

	# Implements AbstractRepository for Git repositories
  # It implements the following paradigm:
  #   1. Repositories are created by using ???
  #   2. Existing repositories are opened by using either ???
  class GitRepository < Repository::AbstractRepository


  end

end