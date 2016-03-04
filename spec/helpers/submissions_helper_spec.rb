require 'spec_helper'

describe SubmissionsHelper do
  describe '#collect_submissions_for_section' do
    before(:each) do
      @assignment = create(:assignment)
      @errors = Array.new
      @section = create(:section, name: 's1')
      @grouping = create(:grouping)
      @grouping.group.access_repo do |repo|
        txn = repo.get_transaction('test')
        path = File.join(@assignment.repository_folder, 'file1_name')
        txn.add(path, 'file1 content', '')
        repo.commit(txn)

        # Generate submission
        submission =
          Submission.generate_new_submission(@grouping,
                                             repo.get_latest_revision)
        result = submission.get_latest_result
        result.marking_state = Result::MARKING_STATES[:complete]
        result.save
        submission.save
      end
      @section_groupings = Array.new
      @section_groupings.push(@grouping)
    end

    it 'should get an error if section doesn\'t exist' do
      expect(Section).to receive(:exists?).with(@section.id) { false }
      expect(@assignment).to_not receive(:submission_rule)
      expect(@assignment).to_not receive(:section_groupings)
      expect(SubmissionCollector).to_not receive(:instance)
      helper.collect_submissions_for_section(@section.id, @assignment, @errors)
      expect(@errors).to include(
        I18n.t('collect_submissions.could_not_find_section'))
    end

    it 'should get an error if the section due date is in the future' do
      expect(Section).to receive(:exists?).with(@section.id) { true }
      expect(@assignment).to receive_message_chain(
        :submission_rule, :can_collect_now?).with(@section) { false }
      expect(@assignment).to receive(:short_identifier) { 'a1' }
      expect(@assignment).to_not receive(:section_groupings)
      expect(SubmissionCollector).to_not receive(:instance)
      helper.collect_submissions_for_section(@section.id, @assignment, @errors)
      expect(@errors).to include(
        I18n.t('collect_submissions.could_not_collect_section',
               assignment_identifier: 'a1',
               section_name: 's1'))
    end

    it 'should return 0 if there are no groupings to collect' do
      expect(Section).to receive(:exists?).with(@section.id) { true }
      expect(@assignment).to receive_message_chain(
        :submission_rule, :can_collect_now?).with(@section) { true }
      expect(@assignment).to receive(:section_groupings)
        .with(@section) { Array.new }
      @submission_collector = SubmissionCollector.instance
      expect(SubmissionCollector)
        .to receive(:instance) { @submission_collector }
      return_val = helper.collect_submissions_for_section(@section.id,
                                                          @assignment,
                                                          @errors)
      expect(return_val).to eq 0
      expect(@errors).to be_empty
    end

    it 'should return 1 if there is one grouping to collect' do
      expect(Section).to receive(:exists?).with(@section.id) { true }
      expect(@assignment).to receive_message_chain(
        :submission_rule, :can_collect_now?).with(@section) { true }
      expect(@assignment).to receive(:section_groupings)
        .with(@section) { @section_groupings }
      @submission_collector = SubmissionCollector.instance
      expect(SubmissionCollector)
        .to receive(:instance) { @submission_collector }
      expect(@submission_collector).to receive(:push_grouping_to_priority_queue)
      return_val = helper.collect_submissions_for_section(@section.id,
                                                          @assignment,
                                                          @errors)
      expect(return_val).to eq 1
      expect(@errors).to be_empty
    end
  end
end
