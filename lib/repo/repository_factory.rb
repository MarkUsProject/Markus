require File.join(File.dirname(__FILE__),'/memory_repository')
require File.join(File.dirname(__FILE__),'/subversion_repository')

# module functions
module Repository
  
  # Returns a repository class of the requested type,
  # which implements AbstractRepository
  def Repository.get_class(repo_type)
    case repo_type
      when "svn"
        return SubversionRepository
      when "memory"
        return MemoryRepository
      else
        raise "Repository implementation not found: #{repo_type}"
    end
  end
  
end # end module
