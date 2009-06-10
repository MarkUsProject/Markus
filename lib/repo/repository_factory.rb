require 'lib/repo/subversion_repository'
require 'lib/repo/memory_repository'

module Repository
  def Repository.create(repo_type)
    case repo_type
      when "svn"
        return SubversionRepository
      when "memory"
        return MemoryRepository
      else
        raise "Repository implementation not found: #{repo_type}"
    end
  end
end
