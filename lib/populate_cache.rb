class PopulateCache

  def self.populate_for_job(object, job_id)
    Rails.cache.delete (job_id) if Rails.cache.fetch(job_id)
    Rails.cache.fetch(job_id) do
      object = object
    end
  end

end