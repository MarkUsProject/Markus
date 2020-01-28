describe PeerReviewsController do
  TEMP_CSV_FILE_PATH = 'files/_temp_peer_review.csv'

  before :each do
    allow(controller).to receive(:session_expired?).and_return(false)
    allow(controller).to receive(:logged_in?).and_return(true)
    allow(controller).to receive(:current_user).and_return(build(:admin))

    @assignment_with_pr = create(:assignment_with_peer_review_and_groupings_results)
    @pr_id = @assignment_with_pr.pr_assignment.id
    @selected_reviewer_group_ids = @assignment_with_pr.pr_assignment.groupings.pluck(:id)
    @selected_reviewee_group_ids = @assignment_with_pr.groupings.pluck(:id)
  end

  describe '#peer_review_mapping' do
    before :each do
      PeerReview.create(reviewer_id: @selected_reviewer_group_ids[0],
                        result_id: Grouping.find(@selected_reviewee_group_ids[1]).current_result.id)
      PeerReview.create(reviewer_id: @selected_reviewer_group_ids[1],
                        result_id: Grouping.find(@selected_reviewee_group_ids[2]).current_result.id)
      PeerReview.create(reviewer_id: @selected_reviewer_group_ids[2],
                        result_id: Grouping.find(@selected_reviewee_group_ids[0]).current_result.id)
      @num_peer_reviews = @assignment_with_pr.peer_reviews.count

      # Remember who was assigned to who before comparing
      @pr_expected_lines = Set.new
      @assignment_with_pr.peer_reviews.each do |pr|
        @pr_expected_lines.add("#{pr.reviewee.group.group_name},#{pr.reviewer.group.group_name}")
      end

      # Perform peer_review_mapping via GET
      get :peer_review_mapping, params: { assignment_id: @pr_id }
      @downloaded_text = response.body
      @found_filename = response.header['Content-Disposition'].include?(
        "filename=\"#{@assignment_with_pr.pr_assignment.short_identifier}_peer_review_mapping.csv\""
      )
      @lines = @downloaded_text[0...-1].split("\n")
    end

    it 'has valid header' do
      expect(@found_filename).to be_truthy
    end

    it 'has the correct number of lines' do
      # Since we compress all the reviewees onto one line with the reviewer,
      # there should only be 'num reviewers' amount of lines
      expect(@lines.count).to be @selected_reviewer_group_ids.count
    end

    it 'all lines match with no duplicates' do
      # Make sure that they all match, and that we don't have any duplicates
      # by accident (ex: having 'group1,group2,group3' repeated two times)
      uniqueness_test_set = Set.new
      @lines.each do |line|
        uniqueness_test_set.add(line)
        expect(@pr_expected_lines.member?(line)).to be_truthy
      end
      expect(uniqueness_test_set.count).to eq @num_peer_reviews
    end
  end

  describe '#populate' do
    before :each do
      PeerReview.create(reviewer_id: @selected_reviewer_group_ids[0],
                        result_id: Grouping.find(@selected_reviewee_group_ids[1]).current_result.id)
      PeerReview.create(reviewer_id: @selected_reviewer_group_ids[1],
                        result_id: Grouping.find(@selected_reviewee_group_ids[2]).current_result.id)
      PeerReview.create(reviewer_id: @selected_reviewer_group_ids[2],
                        result_id: Grouping.find(@selected_reviewee_group_ids[0]).current_result.id)
      @num_peer_reviews = @assignment_with_pr.peer_reviews.count

      # Remember who was assigned to who before comparing
      @pr_expected_lines = Set.new
      @assignment_with_pr.peer_reviews.each do |pr|
        @pr_expected_lines.add("#{pr.reviewee.group.group_name},#{pr.reviewer.group.group_name}")
      end

      get :populate, params: { assignment_id: @pr_id }
      @response = JSON.parse(response.body)
    end

    it 'returns the correct reviewee_to_reviewers_map' do
      expected = {
        @selected_reviewee_group_ids[0].to_s => [@selected_reviewer_group_ids[2]],
        @selected_reviewee_group_ids[1].to_s => [@selected_reviewer_group_ids[0]],
        @selected_reviewee_group_ids[2].to_s => [@selected_reviewer_group_ids[1]]
      }
      expect(@response['reviewee_to_reviewers_map']).to eq(expected)
    end
    it 'returns the correct id_to_group_names_map' do
      expected = {}
      @assignment_with_pr.groupings.or(@assignment_with_pr.pr_assignment.groupings).includes(:group).each do |grouping|
        expected[grouping.id.to_s] = grouping.group.group_name
      end
      expect(@response['id_to_group_names_map']).to eq(expected)
    end
    it 'returns the correct num_reviews_map' do
      expected = {
        @selected_reviewer_group_ids[0].to_s => 1,
        @selected_reviewer_group_ids[1].to_s => 1,
        @selected_reviewer_group_ids[2].to_s => 1
      }
      expect(@response['num_reviews_map']).to eq(expected)
    end
  end

  describe '#upload' do
    include_examples 'a controller supporting upload' do
      let(:params) { { assignment_id: @pr_id, model: PeerReview } }
    end

    context 'with a valid upload file' do
      before :each do
        post :assign_groups,
             params: { actionString: 'random_assign',
                       selectedReviewerGroupIds: @selected_reviewer_group_ids,
                       selectedRevieweeGroupIds: @selected_reviewee_group_ids,
                       assignment_id: @pr_id,
                       numGroupsToAssign: 1
                     }
        get :peer_review_mapping, params: { assignment_id: @pr_id }
        @downloaded_text = response.body
        PeerReview.all.destroy_all
        @path = File.join(self.class.fixture_path, TEMP_CSV_FILE_PATH)
        # Now allow uploading by placing the data in a temporary file and reading
        # the data back through 'uploading' (requires a clean database)
        File.open(@path, 'w') do |f|
          f.write(@downloaded_text)
        end
        csv_upload = fixture_file_upload(TEMP_CSV_FILE_PATH, 'text/csv')
        fixture_upload = fixture_file_upload(TEMP_CSV_FILE_PATH, 'text/csv')
        allow(csv_upload).to receive(:read).and_return(File.read(fixture_upload))

        post :upload, params: { assignment_id: @pr_id, upload_file: csv_upload, encoding: 'UTF-8' }
      end

      after :each do
        File.delete(@path)
      end

      it 'has the correct number of peer reviews' do
        expect(@assignment_with_pr.peer_reviews.count).to eq 3
      end
    end
  end

  context 'random assign' do
    before :each do
      post :assign_groups,
           params: { actionString: 'random_assign',
                     selectedReviewerGroupIds: @selected_reviewer_group_ids,
                     selectedRevieweeGroupIds: @selected_reviewee_group_ids,
                     assignment_id: @pr_id,
                     numGroupsToAssign: 1
           }
    end

    it 'creates the correct number of peer reviews' do
      expect(@assignment_with_pr.peer_reviews.count).to eq 3
    end

    it 'does not assign a reviewee group to review their own submission' do
      PeerReview.all.each do |pr|
        expect(pr.reviewer.id).not_to eq pr.reviewee.id
      end
    end

    it 'does not assign a student to review their own submission' do
      PeerReview.all.each do |pr|
        expect(pr.reviewer.does_not_share_any_students?(pr.reviewee)).to be_truthy
      end
    end

    it 'assigns all selected reviewer groups' do
      expect(@assignment_with_pr.peer_reviews.count).to be @selected_reviewer_group_ids.count
    end
  end

  context 'assign' do
    before :each do
      post :assign_groups,
           params: { actionString: 'assign',
                     selectedReviewerGroupIds: @selected_reviewer_group_ids,
                     selectedRevieweeGroupIds: @selected_reviewee_group_ids,
                     assignment_id: @pr_id,
           }
    end

    it 'creates the correct number of peer reviews' do
      expect(@assignment_with_pr.peer_reviews.count).to eq(
        @selected_reviewee_group_ids.size * @selected_reviewer_group_ids.size
      )
    end

    it 'does not assign a reviewee group to review their own submission' do
      PeerReview.all.each do |pr|
        expect(pr.reviewer.id).not_to eq pr.reviewee.id
      end
    end

    it 'does not assign a student to review their own submission' do
      PeerReview.all.each do |pr|
        expect(pr.reviewer.does_not_share_any_students?(pr.reviewee)).to be_truthy
      end
    end
  end

  context 'unassign' do
    before :each do
      post :assign_groups,
           params: { actionString: 'assign',
                     selectedReviewerGroupIds: @selected_reviewer_group_ids,
                     selectedRevieweeGroupIds: @selected_reviewee_group_ids,
                     assignment_id: @pr_id,
           }
      @num_peer_reviews = @assignment_with_pr.peer_reviews.count
    end

    context 'all reviewers for selected reviewees' do
      before :each do
        post :assign_groups,
             params: { actionString: 'unassign',
                       selectedRevieweeGroupIds: @selected_reviewee_group_ids[0],
                       assignment_id: @pr_id,
             }
      end
      it 'deletes the correct number of peer reviews' do
        expect(@assignment_with_pr.peer_reviews.count).to eq @num_peer_reviews - @selected_reviewer_group_ids.size
      end
    end

    context 'selected reviewer for selected reviewees' do
      before :each do
        @reviewer = Grouping.find_by_id(@selected_reviewer_group_ids[0])
        @reviewee = Grouping.find_by_id(@selected_reviewee_group_ids[1])
        selected_group = {}
        selected_group[@reviewer.id] = true
        selected = {}
        selected[@reviewee.id] = selected_group
        post :assign_groups,
             params: { actionString: 'unassign',
                       selectedReviewerInRevieweeGroups: selected,
                       assignment_id: @pr_id,
             }
      end

      it 'deletes the correct number of peer reviews' do
        expect(@assignment_with_pr.peer_reviews.count).to eq @num_peer_reviews - 1
      end

      it 'removes selected reviewer as reviewer for selected reviewee' do
        expect(PeerReview.review_exists_between?(@reviewer, @reviewee)).to be false
      end
    end
  end
end
