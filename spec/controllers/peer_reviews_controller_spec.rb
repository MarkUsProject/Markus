require 'spec_helper'
require 'set'

describe PeerReviewsController do
  TEMP_CSV_FILE_PATH = 'files/_temp_peer_review.csv'

  before :each do
    allow(controller).to receive(:session_expired?).and_return(false)
    allow(controller).to receive(:logged_in?).and_return(true)
    allow(controller).to receive(:current_user).and_return(build(:admin))

    @assignment_with_pr = create(:assignment_with_peer_review_and_groupings_results)
    @pr_id = @assignment_with_pr.pr_assignment.id
    @selected_reviewer_group_ids = @assignment_with_pr.pr_assignment.groupings.map(&:id)
    @selected_reviewee_group_ids = @assignment_with_pr.groupings.map(&:id)

    post :assign_groups, actionString: 'random_assign', selectedReviewerGroupIds: @selected_reviewer_group_ids,
         selectedRevieweeGroupIds: @selected_reviewee_group_ids, assignment_id: @pr_id,
         numGroupsToAssign: 1
  end

  context 'peer review assignment controller' do
    it 'random assigns properly' do
      expect(PeerReview.all.size).to eq 3
      expect(PeerReview.where(result: Result.all).size).to eq 3
      PeerReview.all.each do |pr|
        expect(pr.reviewer.id).not_to eq pr.reviewee.id
        expect(pr.reviewer.does_not_share_any_students?(pr.reviewee)).to be_truthy
      end
    end

    it 'download and upload CSV properly' do
      num_peer_reviews = PeerReview.all.count
      expect(@assignment_with_pr.peer_reviews.count).to be @selected_reviewer_group_ids.count

      # Remember who was assigned to who before comparing
      pr_expected_lines = Set.new
      @assignment_with_pr.peer_reviews.each do |pr|
        pr_expected_lines.add("#{pr.reviewer.group.group_name},#{pr.reviewee.group.group_name}")
      end

      # Perform downloading via GET
      get :download_reviewer_reviewee_mapping, assignment_id: @pr_id
      downloaded_text = response.body

      # The header must be valid, and the CSV must end with \n
      found_filename = response.header['Content-Disposition'].include?('filename="peer_review_group_to_group_mapping.csv"')
      expect(found_filename).to be_truthy
      expect(downloaded_text[-1, 1]).to eql("\n")

      # Since we compress all the reviewees onto one line with the reviewer,
      # there should only be 'num reviewers' amount of lines
      lines = downloaded_text[0...-1].split("\n")
      expect(lines.count).to be @selected_reviewer_group_ids.count

      # Make sure that they all match, and that we don't have any duplicates
      # by accident (ex: having 'group1,group2,group3' repeated two times)
      uniqueness_test_set = Set.new
      lines.each do |line|
        uniqueness_test_set.add(line)
        expect(pr_expected_lines.member?(line)).to be_truthy
      end
      expect(uniqueness_test_set.count).to be num_peer_reviews

      # Now allow uploading by placing the data in a temporary file and reading
      # the data back through 'uploading' (requires a clean database)
      PeerReview.all.destroy_all
      path = File.join(self.class.fixture_path, TEMP_CSV_FILE_PATH)
      File.open(path, 'w') do |f|
        f.write(downloaded_text)
      end

      expect(File.exist?(path)).to be_truthy

      csv_upload = fixture_file_upload(TEMP_CSV_FILE_PATH, 'text/csv')
      fixture_upload = fixture_file_upload(TEMP_CSV_FILE_PATH, 'text/csv')
      allow(csv_upload).to receive(:read).and_return(File.read(fixture_upload))

      post :csv_upload_handler, assignment_id: @pr_id, peer_review_mapping: csv_upload, encoding: 'UTF-8'

      expect(Grouping.all.size).to eq 6
      expect(PeerReview.all.size).to eq 3
      expect(PeerReview.where(result: Result.all).size).to eq 3

      File.delete(path)
      expect(File.exist?(path)).to be_falsey
    end
  end
end
