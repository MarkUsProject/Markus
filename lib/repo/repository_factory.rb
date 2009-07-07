require File.join(File.dirname(__FILE__),'/memory_repository')
require File.join(File.dirname(__FILE__),'/subversion_repository')

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
