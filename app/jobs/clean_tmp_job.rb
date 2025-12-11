# Job to clean the tmp/ folder
class CleanTmpJob < ApplicationJob
  def perform(repository_stale_limit)
    # Delete all generated zip files
    Dir.glob('tmp/*.zip').each { |f| File.delete(f) }

    # Delete all git repositories that have not been accessed within +repository_stale_limit+ seconds.
    stale_time = repository_stale_limit.seconds.ago
    Dir.glob('tmp/git_repo*').each do |d|
      stat = File::Stat.new(d)
      if stat.mtime < stale_time
        FileUtils.rm_rf(d)
      end
    end
  end
end
