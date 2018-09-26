# Generic helpers common to all specs.
module Helpers
  # Assigns all TAs in +tas+ to all +grouping+ without updating counts (e.g.,
  # the criteria coverage count) so that tests can verify the counts are
  # updated independently.
  def create_ta_memberships(groupings, tas)
    Array(groupings).each do |grouping|
      Array(tas).each do |ta|
        create(:ta_membership, grouping: grouping, user: ta)
      end
    end
  end

  # Reset the repos to empty
  def destroy_repos
    Repository.get_class.purge_all
  end

  # Strip all html content and normalize whitespace in a string.
  # This is useful when comparing flash message contentents to
  # internationalized strings
  def extract_text(string)
    Nokogiri::HTML(string).text.strip.gsub(/\s+/, ' ')
  end

  def submit_files_before_due_date
    pretend_now_is(Time.parse('July 20 2009 5:00PM')) do
      # expect(Time.now).to be < @assignment.due_date
      # expect(Time.now).to be < @assignment.submission_rule.calculate_collection_time
      # expect(Time.now).to be < @assignment.submission_rule.calculate_grouping_collection_time(@membership.grouping)

      @group.access_repo do |repo|
        txn = repo.get_transaction('test')
        txn = add_file_helper(@assignment, txn, 'TestFile.java', 'Some contents for TestFile.java')
        txn = add_file_helper(@assignment, txn, 'Test.java', 'Some contents for Test.java')
        txn = add_file_helper(@assignment, txn, 'Driver.java', 'Some contents for Driver.java')
        repo.commit(txn)
      end
    end
  end

  def submit_file_at_time(time, filename, text)
    pretend_now_is(Time.parse(time)) do
      # expect(Time.now).to be > @assignment.due_date
      # expect(Time.now).to be < @assignment.submission_rule.calculate_collection_time

      @group.access_repo do |repo|
        txn = repo.get_transaction('test')
        txn = add_file_helper(@assignment, txn, filename, text)
        repo.commit(txn)
      end
    end
  end

  # Submit files after the due date of the past assignment but before its collection time
  def submit_files_for_assignment_after_due_before_collection(time, filename, text)
    pretend_now_is(Time.parse(time)) do
      # expect(Time.now).to be > @assignment.due_date
      # expect(Time.now).to be < @assignment.submission_rule.calculate_collection_time

      @group.access_repo do |repo|
        txn = repo.get_transaction('test1')
        txn = add_file_helper(@assignment2, txn, filename, text)
        repo.commit(txn)
      end
    end
  end

  def add_file_helper(assignment, txn, file_name, file_contents)
    path = File.join(assignment.repository_folder, file_name)
    txn.add(path, file_contents, '')
    txn
  end

  def add_period_helper(submission_rule, hours)
    period = Period.new
    period.submission_rule = submission_rule
    period.hours = hours
    period.save
  end
end
