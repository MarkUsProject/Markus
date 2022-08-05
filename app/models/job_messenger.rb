class JobMessenger < ApplicationRecord
  def message_for_user
    case status
    when 'queued'
      'Job is currently queued'
    when 'running'
      'Job is currently running'
    when 'failed'
      "Job Has Failed: #{message}"
    when 'succeeded'
      'Job has processed successfully'
    end
  end

  def failed?
    status == 'failed'
  end

  def succeeded?
    status == 'succeeded'
  end

  def queued?
    status == 'queued'
  end

  def running?
    status == 'running'
  end
end
