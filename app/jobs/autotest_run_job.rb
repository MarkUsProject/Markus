require 'shellwords'

# Job to run autotest tests
class AutotestRunJob < AutotestJob
  def self.show_status(_status)
    I18n.t('poll_job.autotest_run_job_enqueuing')
  end

  def perform(host_with_port, role_id, assignment_id, group_ids, user: nil, collected: true)
    # create and enqueue test runs
    role = Role.find(role_id)
    test_batch = group_ids.size > 1 ? TestBatch.create(course: role.course) : nil # create 1 batch object if needed
    assignment = Assignment.find(assignment_id)

    group_ids.each_slice(Settings.autotest.max_batch_size) do |group_id_slice|
      group_id_slice.each do |group_id|
        grouping = Grouping.find_by(group_id: group_id, assignment: assignment)
        submission = grouping&.current_submission_used
        next unless submission

        rmd_files = submission.submission_files.select { |f| f.filename.end_with?('.Rmd') }
        rmd_files.each do |file|
          file_path = Rails.root.join('tmp', "#{file.id}.Rmd")
          File.write(file_path, file.download_file)
          output_path = file_path.sub_ext('.html')

          script = Rails.root.join('lib', 'tasks', 'render_rmd.sh')
          system("bash #{script} #{Shellwords.escape(file_path.to_s)} #{Shellwords.escape(output_path.to_s)}")

          if File.exist?(output_path)
            submission.feedback_files.create!(
              filename: File.basename(output_path),
              mime_type: 'text/html',
              file_content: File.open(output_path)
            )
          end
        end
      end

      run_tests(assignment, host_with_port, group_id_slice, role, collected: collected, batch: test_batch)
    end
    AutotestResultsJob.perform_later
    unless user.nil?
      TestRunsChannel.broadcast_to(user, { status: 'completed', job_class: 'AutotestRunJob' })
    end
  rescue ServiceUnavailableException => e
    status.catch_exception(e)
    status[:status] = 'service_unavailable'
    unless user.nil?
      TestRunsChannel.broadcast_to(user, { **status.to_h, job_class: 'AutotestRunJob' })
    end
  rescue StandardError => e
    status.catch_exception(e)
    unless user.nil?
      TestRunsChannel.broadcast_to(user, { **status.to_h, job_class: 'AutotestRunJob' })
    end
    raise e
  end
end
