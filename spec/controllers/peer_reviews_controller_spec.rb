describe PeerReviewsController do
  # TODO: add 'role is from a different course' shared tests to each route test below
  let(:course) { @assignment_with_pr.course }

  before do
    stub_const('TEMP_CSV_FILE_PATH', '_temp_peer_review'.freeze)

    @assignment_with_pr = create(:assignment_with_peer_review_and_groupings_results)
    @pr_id = @assignment_with_pr.pr_assignment.id
    @selected_reviewer_group_ids = @assignment_with_pr.pr_assignment.groupings.ids
    @selected_reviewee_group_ids = @assignment_with_pr.groupings.ids
  end

  describe '#peer_review_mapping & #upload' do
    let(:instructor) { create(:instructor) }

    describe '#peer_review_mapping' do
      before do
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
        get_as instructor, :peer_review_mapping, params: { course_id: course.id, assignment_id: @pr_id }
        @downloaded_text = response.body
        @found_filename =
          response.header['Content-Disposition']
                  .include?(
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
          expect(@pr_expected_lines).to be_member(line)
        end
        expect(uniqueness_test_set.count).to eq @num_peer_reviews
      end
    end

    describe '#upload' do
      it_behaves_like 'a controller supporting upload' do
        let(:params) { { course_id: course.id, assignment_id: @pr_id, model: PeerReview } }
      end
      ['.csv', '', '.pdf'].each do |extension|
        ext_string = extension.empty? ? 'none' : extension
        context "with a valid upload file and extension '#{ext_string}'" do
          before do
            post_as instructor,
                    :assign_groups,
                    params: { actionString: 'random_assign',
                              selectedReviewerGroupIds: @selected_reviewer_group_ids,
                              selectedRevieweeGroupIds: @selected_reviewee_group_ids,
                              assignment_id: @pr_id,
                              course_id: course.id,
                              numGroupsToAssign: 1 }
            get_as instructor, :peer_review_mapping, params: { course_id: course.id, assignment_id: @pr_id }
            @downloaded_text = response.body
            PeerReview.destroy_all
            @path = File.join(self.class.file_fixture_path, "#{TEMP_CSV_FILE_PATH}#{extension}")
            # Now allow uploading by placing the data in a temporary file and reading
            # the data back through 'uploading' (requires a clean database)
            File.write(@path, @downloaded_text)
            csv_upload = fixture_file_upload("#{TEMP_CSV_FILE_PATH}#{extension}", 'text/csv')

            post_as instructor, :upload,
                    params: { course_id: course.id, assignment_id: @pr_id, upload_file: csv_upload, encoding: 'UTF-8' }
          end

          after do
            File.delete(@path)
          end

          it 'has the correct number of peer reviews' do
            expect(@assignment_with_pr.peer_reviews.count).to eq 3
          end
        end
      end
    end
  end

  shared_examples 'An authorized instructor or grader' do
    describe '#index' do
      before { get_as role, :index, params: { course_id: course.id, assignment_id: @pr_id } }

      it('should respond with 200') { expect(response).to have_http_status :ok }
    end

    describe '#populate' do
      before do
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

        get_as role, :populate, params: { course_id: course.id, assignment_id: @pr_id }
        @response = response.parsed_body
      end

      it 'returns the correct reviewee_to_reviewers_map' do
        expected = { @selected_reviewee_group_ids[0].to_s => [@selected_reviewer_group_ids[2]],
                     @selected_reviewee_group_ids[1].to_s => [@selected_reviewer_group_ids[0]],
                     @selected_reviewee_group_ids[2].to_s => [@selected_reviewer_group_ids[1]] }
        expect(@response['reviewee_to_reviewers_map']).to eq(expected)
      end

      it 'returns the correct id_to_group_names_map' do
        expected = {}
        @assignment_with_pr.groupings.or(@assignment_with_pr.pr_assignment.groupings)
                           .includes(:group).find_each do |grouping|
          expected[grouping.id.to_s] = grouping.group.group_name
        end
        expect(@response['id_to_group_names_map']).to eq(expected)
      end

      it 'returns the correct num_reviews_map' do
        expected = { @selected_reviewer_group_ids[0].to_s => 1,
                     @selected_reviewer_group_ids[1].to_s => 1,
                     @selected_reviewer_group_ids[2].to_s => 1 }
        expect(@response['num_reviews_map']).to eq(expected)
      end
    end

    context 'random assign' do
      before do
        post_as role, :assign_groups,
                params: { actionString: 'random_assign',
                          selectedReviewerGroupIds: @selected_reviewer_group_ids,
                          selectedRevieweeGroupIds: @selected_reviewee_group_ids,
                          assignment_id: @pr_id,
                          course_id: course.id,
                          numGroupsToAssign: 1 }
      end

      it 'creates the correct number of peer reviews' do
        expect(@assignment_with_pr.peer_reviews.count).to eq 3
      end

      it 'does not assign a reviewee group to review their own submission' do
        PeerReview.find_each do |pr|
          expect(pr.reviewer.id).not_to eq pr.reviewee.id
        end
      end

      it 'does not assign a student to review their own submission' do
        PeerReview.find_each do |pr|
          expect(pr.reviewer).to be_does_not_share_any_students(pr.reviewee)
        end
      end

      it 'assigns all selected reviewer groups' do
        expect(@assignment_with_pr.peer_reviews.count).to be @selected_reviewer_group_ids.count
      end
    end

    context 'assign' do
      before do
        post_as role, :assign_groups,
                params: { actionString: 'assign',
                          course_id: course.id,
                          selectedReviewerGroupIds: @selected_reviewer_group_ids,
                          selectedRevieweeGroupIds: @selected_reviewee_group_ids,
                          assignment_id: @pr_id }
      end

      it 'creates the correct number of peer reviews' do
        expect(@assignment_with_pr.peer_reviews.count)
          .to eq(@selected_reviewee_group_ids.size * @selected_reviewer_group_ids.size)
      end

      it 'does not assign a reviewee group to review their own submission' do
        PeerReview.find_each do |pr|
          expect(pr.reviewer.id).not_to eq pr.reviewee.id
        end
      end

      it 'does not assign a student to review their own submission' do
        PeerReview.find_each do |pr|
          expect(pr.reviewer).to be_does_not_share_any_students(pr.reviewee)
        end
      end
    end

    context 'unassign' do
      before do
        post_as role, :assign_groups,
                params: { actionString: 'assign',
                          selectedReviewerGroupIds: @selected_reviewer_group_ids,
                          selectedRevieweeGroupIds: @selected_reviewee_group_ids,
                          assignment_id: @pr_id,
                          course_id: course.id }
        @num_peer_reviews = @assignment_with_pr.peer_reviews.count
      end

      context 'all reviewers for selected reviewees' do
        before do
          reviewers_to_remove_from_reviewees_map = {}
          reviewers_to_remove_from_reviewees_map[@selected_reviewee_group_ids[0]] =
            @selected_reviewer_group_ids.index_with { true }
          post_as role, :assign_groups,
                  params: { actionString: 'unassign',
                            selectedReviewerInRevieweeGroups: reviewers_to_remove_from_reviewees_map,
                            assignment_id: @pr_id,
                            course_id: course.id }
        end

        it 'deletes the correct number of peer reviews' do
          expect(@assignment_with_pr.peer_reviews.count).to eq @num_peer_reviews - @selected_reviewer_group_ids.size
        end
      end

      context 'selected reviewer for selected reviewees' do
        before do
          @reviewer = Grouping.find_by(id: @selected_reviewer_group_ids[0])
          @reviewee = Grouping.find_by(id: @selected_reviewee_group_ids[1])
          selected_group = {}
          selected_group[@reviewer.id] = true
          selected = {}
          selected[@reviewee.id] = selected_group
          post_as role, :assign_groups,
                  params: { actionString: 'unassign',
                            selectedReviewerInRevieweeGroups: selected,
                            assignment_id: @pr_id,
                            course_id: course.id }
        end

        it 'deletes the correct number of peer reviews' do
          expect(@assignment_with_pr.peer_reviews.count).to eq @num_peer_reviews - 1
        end

        it 'flashes the correct message' do
          expect(flash[:success]).to have_message(I18n.t('peer_reviews.unassigned_reviewers_successfully',
                                                         deleted_count: 1.to_s))
        end

        it 'removes selected reviewer as reviewer for selected reviewee' do
          expect(PeerReview.review_exists_between?(@reviewer, @reviewee)).to be false
        end

        context 'when row(s) of reviewee(s) are selected' do
          before do
            @reviewers_to_remove_from_reviewees_map = {} # no individual checkboxes are selected
          end

          context 'when applicable reviewers are selected' do
            before do
              reviewer_ids = PeerReview.joins(:reviewee).where(groupings: { id: @selected_reviewee_group_ids })
                                       .pluck(:reviewer_id)
              @selected_reviewer_group_ids = reviewer_ids
              post_as role, :assign_groups,
                      params: { actionString: 'unassign',
                                selectedRevieweeGroupIds: @selected_reviewee_group_ids,
                                selectedReviewerGroupIds: @selected_reviewer_group_ids,
                                selectedReviewerInRevieweeGroups: @reviewers_to_remove_from_reviewees_map,
                                assignment_id: @pr_id,
                                course_id: course.id }
            end

            it 'deletes the correct number of peer reviews' do
              expect(@assignment_with_pr.peer_reviews.count).to eq 0
            end

            it 'flashes the correct message' do
              expect(flash[:success]).to have_message(I18n.t('peer_reviews.unassigned_reviewers_successfully',
                                                             deleted_count: 8.to_s))
            end
          end
        end
      end

      context 'selected reviews have marks or annotations' do
        before do
          @assignment_with_pr.peer_reviews.each do |review|
            result = review.result
            result.update(marking_state: Result::MARKING_STATES[:complete])
          end

          @reviewers_to_remove_from_reviewees_map = {}
          @selected_reviewee_group_ids.each do |reviewee_id|
            @reviewers_to_remove_from_reviewees_map[reviewee_id] =
              @selected_reviewer_group_ids.index_with do |_reviewer_id|
                true
              end
          end
        end

        context 'when no reviewers are unassigned' do
          before do
            post_as role, :assign_groups,
                    params: { actionString: 'unassign',
                              selectedRevieweeGroupIds: @selected_reviewee_group_ids,
                              selectedReviewerInRevieweeGroups: @reviewers_to_remove_from_reviewees_map,
                              assignment_id: @pr_id,
                              course_id: course.id }
          end

          it 'flashes the correct message' do
            expect(flash[:error]).to have_message(I18n.t('peer_reviews.errors.cannot_unassign_any_reviewers'))
          end

          it 'does not delete any peer reviews' do
            expect(@assignment_with_pr.peer_reviews.count).to eq @num_peer_reviews
          end
        end

        context 'when row(s) of reviewee(s) who cannot be unassigned are selected' do
          before do
            @reviewers_to_remove_from_reviewees_map = {} # no individual checkboxes are selected
          end

          context 'when all applicable reviewers are selected' do
            before do
              @selected_reviewer_group_ids = PeerReview.joins(:reviewee)
                                                       .where(groupings: { id: @selected_reviewee_group_ids })
                                                       .pluck(:reviewer_id)
              post_as role, :assign_groups,
                      params: { actionString: 'unassign',
                                selectedRevieweeGroupIds: @selected_reviewee_group_ids,
                                selectedReviewerGroupIds: @selected_reviewer_group_ids,
                                selectedReviewerInRevieweeGroups: @reviewers_to_remove_from_reviewees_map,
                                assignment_id: @pr_id,
                                course_id: course.id }
            end

            it 'flashes the correct message' do
              expect(flash[:error]).to have_message(I18n.t('peer_reviews.errors.cannot_unassign_any_reviewers'))
            end

            it 'does not delete any peer reviews' do
              expect(@assignment_with_pr.peer_reviews.count).to eq @num_peer_reviews
            end
          end
        end

        context 'when some reviewers are unassigned, but more than 5 are not' do
          before do
            @assignment_with_pr.peer_reviews.first.result.update(marking_state: Result::MARKING_STATES[:incomplete])
            post_as role, :assign_groups,
                    params: { actionString: 'unassign',
                              selectedRevieweeGroupIds: @selected_reviewee_group_ids,
                              selectedReviewerInRevieweeGroups: @reviewers_to_remove_from_reviewees_map,
                              assignment_id: @pr_id,
                              course_id: course.id }
          end

          it 'flashes the correct message' do
            undeleted_reviews = @assignment_with_pr.peer_reviews.map do |review|
              I18n.t('activerecord.models.peer_review.cannot_unassign_all_reviewers',
                     reviewer_group_name: review.reviewer.group.group_name,
                     reviewee_group_name: review.result.grouping.group.group_name)
            end
            expect(flash[:error]).to contain_message('Successfully unassigned 1 peer reviewer(s)')
            expect(flash[:error]).to contain_message(I18n.t('additional_not_shown',
                                                            count: undeleted_reviews.length - 6))
          end

          it 'deletes the correct number of peer reviews' do
            expect(@assignment_with_pr.peer_reviews.count).to eq @num_peer_reviews - 1
          end
        end

        context 'when some rows of reviewees are selected and some reviewers are unassigned' do
          before do
            @assignment_with_pr.peer_reviews.first.result.update(marking_state: Result::MARKING_STATES[:incomplete])
            @reviewers_to_remove_from_reviewees_map = {}
          end

          context 'when all applicable reviewers are selected' do
            before do
              @selected_reviewer_group_ids = PeerReview.joins(:reviewee)
                                                       .where(groupings: { id: @selected_reviewee_group_ids })
                                                       .pluck(:reviewer_id)
              post_as role, :assign_groups,
                      params: { actionString: 'unassign',
                                selectedRevieweeGroupIds: @selected_reviewee_group_ids,
                                selectedReviewerGroupIds: @selected_reviewer_group_ids,
                                selectedReviewerInRevieweeGroups: @reviewers_to_remove_from_reviewees_map,
                                assignment_id: @pr_id,
                                course_id: course.id }
            end

            it 'flashes the correct message' do
              undeleted_reviews = @assignment_with_pr.peer_reviews.map do |review|
                I18n.t('activerecord.models.peer_review.cannot_unassign_all_reviewers',
                       reviewer_group_name: review.reviewer.group.group_name,
                       reviewee_group_name: review.result.grouping.group.group_name)
              end

              expect(flash[:error]).to contain_message('Successfully unassigned 1 peer reviewer(s)')
              expect(flash[:error]).to contain_message(I18n.t('additional_not_shown',
                                                              count: undeleted_reviews.length - 6))
            end

            it 'deletes the correct number of peer reviews' do
              expect(@assignment_with_pr.peer_reviews.count).to eq @num_peer_reviews - 1
            end
          end
        end

        context 'when some reviewers are unassigned, but less than 5 are not' do
          before do
            (1..6).each do |i|
              @assignment_with_pr.peer_reviews[i].result.update(marking_state: Result::MARKING_STATES[:incomplete])
            end
            post_as role, :assign_groups,
                    params: { actionString: 'unassign',
                              selectedRevieweeGroupIds: @selected_reviewee_group_ids,
                              selectedReviewerInRevieweeGroups: @reviewers_to_remove_from_reviewees_map,
                              assignment_id: @pr_id,
                              course_id: course.id }
          end

          it 'flashes the correct message' do
            expect(flash[:error]).to contain_message('Successfully unassigned 6 peer reviewer(s)')
          end

          it 'deletes the correct number of peer reviews' do
            expect(@assignment_with_pr.peer_reviews.count).to eq @num_peer_reviews - 6
          end
        end

        context 'when some rows of reviewees and some individual reviewers are selected' do
          before do
            [0, 2].each do |i| # mark 1st and 3rd peer reviews as unassign-able
              @assignment_with_pr.peer_reviews[i].result.update(marking_state: Result::MARKING_STATES[:incomplete])
            end
            @selected_reviewee_group_ids.last(2).each do |reviewee_id| # individually select 2nd and 3rd reviewers
              @reviewers_to_remove_from_reviewees_map[reviewee_id] = @selected_reviewer_group_ids.index_with { true }
            end
            @selected_reviewer_group_ids = PeerReview.joins(:reviewee)
                                                     .where(groupings: { id: @selected_reviewee_group_ids })
                                                     .pluck(:reviewer_id)[0] # select the 1st reviewee row
            row_reviewee = @selected_reviewee_group_ids[0]
            row_reviewer = @selected_reviewer_group_ids
            @reviewers_to_remove_from_reviewees_map[row_reviewee][row_reviewer] = false
            # ensure row is not individually checked

            post_as role, :assign_groups,
                    params: { actionString: 'unassign',
                              selectedRevieweeGroupIds: @selected_reviewee_group_ids,
                              selectedReviewerGroupIds: @selected_reviewer_group_ids,
                              selectedReviewerInRevieweeGroups: @reviewers_to_remove_from_reviewees_map,
                              assignment_id: @pr_id,
                              course_id: course.id }
          end

          it 'flashes the correct message' do
            expect(flash[:error]).to contain_message(
              'Successfully unassigned 2 peer reviewer(s), but could not unassign the ' \
              'following due to existing marks or annotations: '
            )
          end

          it 'deletes the correct number of peer reviews' do
            expect(@assignment_with_pr.peer_reviews.count).to eq @num_peer_reviews - 2
          end
        end
      end
    end
  end

  describe 'When role is an authenticated instructor' do
    let(:role) { create(:instructor) }

    it_behaves_like 'An authorized instructor or grader'
  end

  describe 'When role is grader and allowed to manage reviewers' do
    let(:role) { create(:ta, manage_assessments: true) }

    it_behaves_like 'An authorized instructor or grader'
  end

  describe 'When the role is grader and not allowed to manage reviewers' do
    # By default all the grader permissions are set to false
    let(:grader) { create(:ta) }

    describe '#random assign' do
      it 'should return 403 response' do
        post_as grader, :assign_groups,
                params: { actionString: 'assign',
                          selectedReviewerGroupIds: @selected_reviewer_group_ids,
                          selectedRevieweeGroupIds: @selected_reviewee_group_ids,
                          assignment_id: @pr_id,
                          course_id: course.id }
        expect(response).to have_http_status(:forbidden)
      end
    end

    describe '#index' do
      before { get_as grader, :index, params: { course_id: course.id, assignment_id: @pr_id } }

      it('should respond with 403') { expect(response).to have_http_status :forbidden }
    end

    describe '#populate' do
      before { get_as grader, :populate, params: { course_id: course.id, assignment_id: @pr_id } }

      it('should respond with 403') { expect(response).to have_http_status :forbidden }
    end
  end

  describe 'When listing peer reviews in Peer Reviews tab' do
    let(:instructor) { create(:instructor) }
    let(:max_mark) { 3 }

    before do
      PeerReview.create(reviewer_id: @selected_reviewer_group_ids[0],
                        result_id: Grouping.find(@selected_reviewee_group_ids[1]).current_result.id)
      PeerReview.create(reviewer_id: @selected_reviewer_group_ids[1],
                        result_id: Grouping.find(@selected_reviewee_group_ids[2]).current_result.id)
      PeerReview.create(reviewer_id: @selected_reviewer_group_ids[2],
                        result_id: Grouping.find(@selected_reviewee_group_ids[0]).current_result.id)
    end

    it 'should list out total marks for each peer review' do
      create_list(:flexible_criterion, 1, assignment: @assignment_with_pr.pr_assignment)
      @assignment_with_pr.pr_assignment.criteria.first.update(peer_visible: true)
      @assignment_with_pr.pr_assignment.criteria.first.update(max_mark: max_mark)

      @assignment_with_pr.pr_assignment.groupings.each do |grouping|
        result = grouping.peer_reviews_to_others.first.result
        @assignment_with_pr.pr_assignment.criteria.each do |c|
          mark = c.marks.find_or_create_by(result_id: result.id)
          mark.update(mark: max_mark)
        end
        result.update(marking_state: Result::MARKING_STATES[:complete])
      end

      response = get_as instructor, :populate_table,
                        params: { course_id: @assignment_with_pr.pr_assignment.course.id, assignment_id: @pr_id }
      response_hash = JSON.parse(response.body)
      final_grades = response_hash.pluck('final_grade')
      expect(final_grades).to all eq(max_mark)
    end
  end
end
