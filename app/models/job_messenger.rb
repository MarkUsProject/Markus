# rubocop:disable Layout/LineLength, Lint/RedundantCopDisableDirective
# == Schema Information
#
# Table name: job_messengers
#
#  id         :integer          not null, primary key
#  message    :string
#  status     :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  job_id     :string
#
# Indexes
#
#  index_job_messengers_on_job_id  (job_id)
#
# rubocop:enable Layout/LineLength, Lint/RedundantCopDisableDirective
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
