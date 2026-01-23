describe GradersController do
  # TODO: add 'role is from a different course' shared tests to each route test below
  context 'An authenticated and authorized student doing a' do
    let(:assignment) { create(:assignment) }
    let(:course) { assignment.course }

    before do
      @student = create(:student)
    end

    it 'GET on :index' do
      get_as @student, :index, params: { course_id: course.id, assignment_id: assignment.id }
      expect(response).to have_http_status(:forbidden)
    end

    it 'GET on :upload' do
      get_as @student, :upload, params: { course_id: course.id, assignment_id: assignment.id }
      expect(response).to have_http_status(:forbidden)
    end

    it 'GET on :global_actions' do
      get_as @student, :global_actions, params: { course_id: course.id, assignment_id: assignment.id }
      expect(response).to have_http_status(:forbidden)
    end

    it 'POST on :upload' do
      post_as @student, :upload, params: { course_id: course.id, assignment_id: assignment.id }
      expect(response).to have_http_status(:forbidden)
    end

    it 'POST on :global_actions' do
      post_as @student, :global_actions, params: { course_id: course.id, assignment_id: assignment.id }
      expect(response).to have_http_status(:forbidden)
    end
  end

  context 'An authenticated and authorized instructor' do
    let(:course) { @assignment.course }

    before do
      @instructor = create(:instructor)
      @assignment = create(:assignment)
    end

    it 'doing a GET on :index(graders_controller)' do
      get_as @instructor, :index, params: { course_id: course.id, assignment_id: @assignment.id }
      expect(response).to have_http_status(:ok)
      expect(assigns(:assignment)).not_to be_nil
    end

    context 'doing a POST on :upload (assigning to groups)' do
      it_behaves_like 'a controller supporting upload' do
        let(:params) { { course_id: course.id, assignment_id: @assignment.id, model: TaMembership, groupings: true } }
      end

      before do
        # Contents: test_group,g9browni,g9younas
        #           second_test_group,g9browni
        #           Group 3,c7benjam
        @group_grader_map_file = fixture_file_upload('group_csvs/group_grader_map.csv')
      end

      ['.csv', '.pdf', ''].each do |extension|
        ext_string = extension.empty? ? 'none' : extension
        it "and all graders and groups are valid in a file with extension '#{ext_string}'" do
          file = fixture_file_upload("group_csvs/group_grader_map#{extension}", 'text/csv')
          @ta1 = create(:ta, user: create(:end_user, user_name: 'g9browni'))
          @ta2 = create(:ta, user: create(:end_user, user_name: 'g9younas'))
          @ta3 = create(:ta, user: create(:end_user, user_name: 'c7benjam'))
          @grouping1 = create(:grouping,
                              assignment: @assignment,
                              group: create(:group, course: @assignment.course, group_name: 'test_group'))
          @grouping2 = create(:grouping,
                              assignment: @assignment,
                              group: create(:group, course: @assignment.course, group_name: 'second_test_group'))
          @grouping3 = create(:grouping,
                              assignment: @assignment,
                              group: create(:group, course: @assignment.course, group_name: 'Group 3'))
          @grouping4 = create(:grouping,
                              assignment: @assignment,
                              group: create(:group, course: @assignment.course, group_name: 'Group 4'))
          @grouping4.tas << @ta1
          post_as @instructor,
                  :upload,
                  params: { course_id: course.id, assignment_id: @assignment.id,
                            upload_file: file, groupings: true }

          expect(response).to be_redirect
          expect(@grouping1.tas.count).to eq 2
          expect(@grouping1.tas).to include(@ta1)
          expect(@grouping1.tas).to include(@ta2)
          expect(@grouping2.tas.count).to eq 1
          expect(@grouping2.tas).to include(@ta1)
          expect(@grouping3.tas.count).to eq 1
          expect(@grouping3.tas).to include(@ta3)
          expect(@grouping4.tas.count).to eq 1 # Didn't delete existing mappings
        end
      end

      it 'and a successful call updates repository permissions exactly once' do
        expect(UpdateRepoPermissionsJob).to receive(:perform_later)
        post_as @instructor,
                :upload,
                params: { course_id: course.id, assignment_id: @assignment.id,
                          upload_file: @group_grader_map_file, groupings: true }
      end

      it 'and some graders are invalid' do
        @ta1 = create(:ta, user: create(:end_user, user_name: 'g9browni'))
        @ta2 = create(:ta, user: create(:end_user, user_name: 'g9younas'))
        @ta3 = create(:ta, user: create(:end_user, user_name: 'c0curtis'))
        @grouping1 = create(:grouping,
                            assignment: @assignment,
                            group: create(:group, course: @assignment.course, group_name: 'test_group'))
        @grouping2 = create(:grouping,
                            assignment: @assignment,
                            group: create(:group, course: @assignment.course, group_name: 'second_test_group'))
        @grouping3 = create(:grouping,
                            assignment: @assignment,
                            group: create(:group, course: @assignment.course, group_name: 'Group 3'))
        post_as @instructor,
                :upload,
                params: { course_id: course.id, assignment_id: @assignment.id,
                          upload_file: @group_grader_map_file, groupings: true }

        expect(response).to be_redirect
        assert @grouping1.tas.count == 2
        assert @grouping1.tas.include? @ta1
        assert @grouping1.tas.include? @ta2
        assert @grouping2.tas.one?
        assert @grouping2.tas.include? @ta1
        assert @grouping3.tas.none?
      end

      it 'and some groupings are invalid' do
        @ta1 = create(:ta, user: create(:end_user, user_name: 'g9browni'))
        @ta2 = create(:ta, user: create(:end_user, user_name: 'g9younas'))
        @ta3 = create(:ta, user: create(:end_user, user_name: 'c7benjam'))
        @grouping1 = create(:grouping,
                            assignment: @assignment,
                            group: create(:group, course: @assignment.course, group_name: 'Group of 7'))
        @grouping2 = create(:grouping,
                            assignment: @assignment,
                            group: create(:group, course: @assignment.course, group_name: 'second_test_group'))
        @grouping3 = create(:grouping,
                            assignment: @assignment,
                            group: create(:group, course: @assignment.course, group_name: 'Group 3'))
        post_as @instructor,
                :upload,
                params: { course_id: course.id, assignment_id: @assignment.id,
                          upload_file: @group_grader_map_file, groupings: true }

        expect(response).to be_redirect
        expect(@grouping1.tas.count).to eq 0
        expect(@grouping2.tas.count).to eq 1
        expect(@grouping2.tas).to include(@ta1)
        expect(@grouping3.tas.count).to eq 1
        expect(@grouping3.tas).to include(@ta3)
      end

      it 'and the request removes existing mappings' do
        @ta1 = create(:ta, user: create(:end_user, user_name: 'g9browni'))
        @ta2 = create(:ta, user: create(:end_user, user_name: 'g9younas'))
        @ta3 = create(:ta, user: create(:end_user, user_name: 'c7benjam'))
        @grouping1 = create(:grouping,
                            assignment: @assignment,
                            group: create(:group, course: @assignment.course, group_name: 'test_group'))
        @grouping2 = create(:grouping,
                            assignment: @assignment,
                            group: create(:group, course: @assignment.course, group_name: 'second_test_group'))
        @grouping3 = create(:grouping,
                            assignment: @assignment,
                            group: create(:group, course: @assignment.course, group_name: 'Group 3'))
        @grouping4 = create(:grouping,
                            assignment: @assignment,
                            group: create(:group, course: @assignment.course, group_name: 'Group 4'))
        @grouping4.tas << @ta1
        post_as @instructor,
                :upload,
                params: { course_id: course.id, assignment_id: @assignment.id, upload_file: @group_grader_map_file,
                          groupings: true, remove_existing_mappings: false }

        expect(response).to be_redirect
        expect(@grouping4.tas.count).to eq 0
      end

      it 'and uploading the same mappings twice does not create duplicates' do
        @ta1 = create(:ta, user: create(:end_user, user_name: 'g9browni'))
        @ta2 = create(:ta, user: create(:end_user, user_name: 'g9younas'))
        @ta3 = create(:ta, user: create(:end_user, user_name: 'c7benjam'))
        @grouping1 = create(:grouping,
                            assignment: @assignment,
                            group: create(:group, course: @assignment.course, group_name: 'test_group'))
        @grouping2 = create(:grouping,
                            assignment: @assignment,
                            group: create(:group, course: @assignment.course, group_name: 'second_test_group'))
        @grouping3 = create(:grouping,
                            assignment: @assignment,
                            group: create(:group, course: @assignment.course, group_name: 'Group 3'))

        # First upload
        post_as @instructor,
                :upload,
                params: { course_id: course.id, assignment_id: @assignment.id,
                          upload_file: @group_grader_map_file, groupings: true }

        expect(response).to be_redirect
        expect(@grouping1.tas.count).to eq 2

        # Second upload of the same file without removing existing mappings
        post_as @instructor,
                :upload,
                params: { course_id: course.id, assignment_id: @assignment.id,
                          upload_file: @group_grader_map_file, groupings: true }

        expect(response).to be_redirect
        # Should still have the same count, no duplicates
        expect(@grouping1.tas.count).to eq 2
        expect(@grouping1.tas).to include(@ta1)
        expect(@grouping1.tas).to include(@ta2)
        expect(@grouping2.tas.count).to eq 1
        expect(@grouping2.tas).to include(@ta1)
        expect(@grouping3.tas.count).to eq 1
        expect(@grouping3.tas).to include(@ta3)
      end
    end

    context 'doing a POST on :upload (assigning to criteria)' do
      it_behaves_like 'a controller supporting upload' do
        let(:params) { { course_id: course.id, assignment_id: @assignment.id, model: TaMembership, criteria: true } }
      end

      before do
        # Contents: correctness,g9browni,g9younas
        #           style,g9browni
        #           class design,c7benjam
        @criteria_grader_map_file = fixture_file_upload('group_csvs/criteria_grader_map.csv')
      end

      context 'with rubric criteria' do
        before do
          @assignment = create(:assignment, assignment_properties_attributes: { assign_graders_to_criteria: true })
        end

        it 'and all graders and criteria are valid' do
          @ta1 = create(:ta, user: create(:end_user, user_name: 'g9browni'))
          @ta2 = create(:ta, user: create(:end_user, user_name: 'g9younas'))
          @ta3 = create(:ta, user: create(:end_user, user_name: 'c7benjam'))
          @criterion1 = create(:rubric_criterion, assignment: @assignment, name: 'correctness')
          @criterion2 = create(:rubric_criterion, assignment: @assignment, name: 'style')
          @criterion3 = create(:rubric_criterion, assignment: @assignment, name: 'class design')
          post_as @instructor,
                  :upload,
                  params: { course_id: course.id, assignment_id: @assignment.id,
                            upload_file: @criteria_grader_map_file, criteria: true }

          expect(response).to be_redirect
          expect(@criterion1.tas.count).to eq 2
          expect(@criterion1.tas).to include(@ta1)
          expect(@criterion1.tas).to include(@ta2)
          expect(@criterion2.tas.count).to eq 1
          expect(@criterion2.tas).to include(@ta1)
          expect(@criterion3.tas.count).to eq 1
          expect(@criterion3.tas).to include(@ta3)
        end

        it 'and some graders are invalid' do
          @ta1 = create(:ta, user: create(:end_user, user_name: 'g9browni'))
          @ta2 = create(:ta, user: create(:end_user, user_name: 'reid'))
          @ta3 = create(:ta, user: create(:end_user, user_name: 'c7benjam'))
          @criterion1 = create(:rubric_criterion, assignment: @assignment, name: 'correctness')
          @criterion2 = create(:rubric_criterion, assignment: @assignment, name: 'style')
          @criterion3 = create(:rubric_criterion, assignment: @assignment, name: 'class design')
          post_as @instructor,
                  :upload,
                  params: { course_id: course.id, assignment_id: @assignment.id,
                            upload_file: @criteria_grader_map_file, criteria: true }

          expect(response).to be_redirect
          expect(@criterion1.tas.count).to eq 0 # entire row is ignored
          expect(@criterion2.tas.count).to eq 1
          expect(@criterion2.tas).to include(@ta1)
          expect(@criterion3.tas.count).to eq 1
          expect(@criterion3.tas).to include(@ta3)
        end

        it 'and some criteria are invalid' do
          @ta1 = create(:ta, user: create(:end_user, user_name: 'g9browni'))
          @ta2 = create(:ta, user: create(:end_user, user_name: 'g9younas'))
          @ta3 = create(:ta, user: create(:end_user, user_name: 'c7benjam'))
          @criterion1 = create(:rubric_criterion, assignment: @assignment, name: 'correctness')
          @criterion2 = create(:rubric_criterion, assignment: @assignment, name: "professor's whim")
          @criterion3 = create(:rubric_criterion, assignment: @assignment, name: 'class design')
          post_as @instructor,
                  :upload,
                  params: { course_id: course.id, assignment_id: @assignment.id,
                            upload_file: @criteria_grader_map_file, criteria: true }

          expect(response).to be_redirect
          expect(@criterion1.tas.count).to eq 2
          expect(@criterion1.tas).to include(@ta1)
          expect(@criterion2.tas.count).to eq 0
          expect(@criterion3.tas.count).to eq 1
          expect(@criterion3.tas).to include(@ta3)
        end
      end

      context 'with flexible criteria' do
        before do
          @assignemnt = create(:assignment, assignment_properties_attributes: { assign_graders_to_criteria: true })
        end

        it 'and all graders and criteria are valid' do
          @ta1 = create(:ta, user: create(:end_user, user_name: 'g9browni'))
          @ta2 = create(:ta, user: create(:end_user, user_name: 'g9younas'))
          @ta3 = create(:ta, user: create(:end_user, user_name: 'c7benjam'))
          @criterion1 = create(:flexible_criterion, assignment: @assignment, name: 'correctness')
          @criterion2 = create(:flexible_criterion, assignment: @assignment, name: 'style')
          @criterion3 = create(:flexible_criterion, assignment: @assignment, name: 'class design')
          post_as @instructor,
                  :upload,
                  params: { course_id: course.id, assignment_id: @assignment.id,
                            upload_file: @criteria_grader_map_file, criteria: true }

          expect(response).to be_redirect
          @criterion1.reload
          @criterion2.reload
          @criterion3.reload
          expect(@criterion1.tas.count).to eq 2
          expect(@criterion1.tas).to include(@ta1)
          expect(@criterion1.tas).to include(@ta2)
          expect(@criterion2.tas.count).to eq 1
          expect(@criterion2.tas).to include(@ta1)
          expect(@criterion3.tas.count).to eq 1
          expect(@criterion3.tas).to include(@ta3)
        end

        it 'and some graders are invalid' do
          @ta1 = create(:ta, user: create(:end_user, user_name: 'g9browni'))
          @ta2 = create(:ta, user: create(:end_user, user_name: 'reid'))
          @ta3 = create(:ta, user: create(:end_user, user_name: 'c7benjam'))
          @criterion1 = create(:flexible_criterion, assignment: @assignment, name: 'correctness')
          @criterion2 = create(:flexible_criterion, assignment: @assignment, name: 'style')
          @criterion3 = create(:flexible_criterion, assignment: @assignment, name: 'class design')
          post_as @instructor,
                  :upload,
                  params: { course_id: course.id, assignment_id: @assignment.id,
                            upload_file: @criteria_grader_map_file, criteria: true }

          expect(response).to be_redirect
          @criterion1.reload
          @criterion2.reload
          @criterion3.reload
          expect(@criterion1.tas.count).to eq 0 # entire row is ignored
          expect(@criterion2.tas.count).to eq 1
          expect(@criterion2.tas).to include(@ta1)
          expect(@criterion3.tas.count).to eq 1
          expect(@criterion3.tas).to include(@ta3)
        end

        it 'and some criteria are invalid' do
          @ta1 = create(:ta, user: create(:end_user, user_name: 'g9browni'))
          @ta2 = create(:ta, user: create(:end_user, user_name: 'g9younas'))
          @ta3 = create(:ta, user: create(:end_user, user_name: 'c7benjam'))
          @criterion1 = create(:flexible_criterion, assignment: @assignment, name: 'correctness')
          @criterion2 = create(:flexible_criterion, assignment: @assignment, name: "professor's whim")
          @criterion3 = create(:flexible_criterion, assignment: @assignment, name: 'class design')
          post_as @instructor,
                  :upload,
                  params: { course_id: course.id, assignment_id: @assignment.id,
                            upload_file: @criteria_grader_map_file, criteria: true }

          expect(response).to be_redirect
          @criterion1.reload
          @criterion2.reload
          @criterion3.reload
          expect(@criterion1.tas.count).to eq 2
          expect(@criterion1.tas).to include(@ta1)
          expect(@criterion2.tas.count).to eq 0
          expect(@criterion3.tas.count).to eq 1
          expect(@criterion3.tas).to include(@ta3)
        end
      end
    end

    context 'with groups table selected doing a' do
      context 'POST on :global_actions on random_assign' do
        before do
          @grouping1 = create(:grouping, assignment: @assignment)
          @grouping2 = create(:grouping, assignment: @assignment)
          @grouping3 = create(:grouping, assignment: @assignment)
          @ta1 = create(:ta)
          @ta2 = create(:ta)
          @ta3 = create(:ta)

          # Making two new TA's that are 'inactive', to test additional functionality
          @ta4 = create(:ta, hidden: true)
          @ta5 = create(:ta, hidden: true)
        end

        it 'and no graders selected' do
          post_as @instructor,
                  :global_actions,
                  params: { course_id: course.id, assignment_id: @assignment.id, global_actions: 'random_assign',
                            current_table: 'groups_table' }
          expect(response).to have_http_status(:bad_request)
          @assignment.groupings.each do |grouping|
            expect(grouping.tas).to eq []
          end
        end

        it 'and no groups selected, at least one grader' do
          post_as @instructor,
                  :global_actions,
                  params: { course_id: course.id, assignment_id: @assignment.id,
                            global_actions: 'random_assign', graders: [@ta1.id], current_table: 'groups_table' }
          expect(response).to have_http_status(:bad_request)
          @assignment.groupings.each do |grouping|
            expect(grouping.tas).to eq []
          end
        end

        it 'and no graders are selected, at least one grouping' do
          post_as @instructor,
                  :global_actions,
                  params: { course_id: course.id, assignment_id: @assignment.id,
                            global_actions: 'random_assign', groupings: [@grouping1.id], current_table: 'groups_table' }
          expect(response).to have_http_status(:bad_request)
          @assignment.groupings.each do |grouping|
            expect(grouping.tas).to eq []
          end
        end

        it 'and one grader and one grouping is selected' do
          post_as @instructor,
                  :global_actions,
                  params: { course_id: course.id, assignment_id: @assignment.id,
                            global_actions: 'random_assign', groupings: [@grouping1.id], weightings: [1],
                            graders: [@ta1.id], current_table: 'groups_table' }
          expect(response).to have_http_status(:ok)
          expect(@grouping1.tas[0].id).to eq @ta1.id
          expect(@grouping2.tas).to eq []
          expect(@grouping3.tas).to eq []
        end

        it 'and one grader and multiple groupings are selected' do
          post_as @instructor,
                  :global_actions,
                  params: { course_id: course.id, assignment_id: @assignment.id, global_actions: 'random_assign',
                            groupings: [@grouping1.id, @grouping2.id], graders: [@ta1.id],
                            weightings: [1], current_table: 'groups_table' }
          expect(response).to have_http_status(:ok)
          expect(@grouping1.tas[0].id).to eq @ta1.id
          expect(@grouping2.tas[0].id).to eq @ta1.id
          expect(@grouping3.tas).to eq []
        end

        it 'and two graders and one grouping is selected' do
          post_as @instructor,
                  :global_actions,
                  params: { course_id: course.id, assignment_id: @assignment.id, global_actions: 'random_assign',
                            groupings: [@grouping1.id], graders: [@ta1.id, @ta2.id],
                            weightings: [1, 1], current_table: 'groups_table' }
          expect(response).to have_http_status(:ok)
          expect(@grouping1.tas[0].id).to eq(@ta1.id).or eq(@ta2.id)
          expect(@grouping2.tas).to eq []
          expect(@grouping3.tas).to eq []
        end

        it 'and two graders and two groupings are selected' do
          post_as @instructor,
                  :global_actions,
                  params: { course_id: course.id, assignment_id: @assignment.id, global_actions: 'random_assign',
                            groupings: [@grouping1.id, @grouping2.id], graders: [@ta1.id, @ta2.id],
                            weightings: [1, 1], current_table: 'groups_table' }
          expect(response).to have_http_status(:ok)
          expect(@grouping1.tas[0].id).to eq(@ta1.id).or eq(@ta2.id)
          expect(@grouping2.tas[0].id).to eq(@ta1.id).or eq(@ta2.id)
          expect(@grouping1.tas[0].id).not_to eq @grouping2.tas[0].id
          expect(@grouping3.tas).to eq []
        end

        it 'and two graders and two groupings are selected with one having a weight of 0' do
          post_as @instructor,
                  :global_actions,
                  params: { course_id: course.id, assignment_id: @assignment.id, global_actions: 'random_assign',
                            groupings: [@grouping1.id, @grouping2.id], graders: [@ta1.id, @ta2.id],
                            weightings: [1, 0], current_table: 'groups_table' }
          expect(response).to have_http_status(:ok)
          expect(@grouping1.tas[0].id).to eq(@ta1.id)
          expect(@grouping2.tas[0].id).to eq(@ta1.id)
          expect(@grouping3.tas).to eq []
        end

        it 'and two graders and three groupings are selected with one having a weight of 2' do
          post_as @instructor,
                  :global_actions,
                  params: { course_id: course.id, assignment_id: @assignment.id, global_actions: 'random_assign',
                            groupings: [@grouping1.id, @grouping2.id, @grouping3.id], graders: [@ta1.id, @ta2.id],
                            weightings: [2, 1], current_table: 'groups_table' }
          expect(response).to have_http_status(:ok)
          expect(@grouping1.tas[0].id).to eq(@ta1.id).or eq(@ta2.id)
          expect(@grouping2.tas[0].id).to eq(@ta1.id).or eq(@ta2.id)
          expect(@grouping3.tas[0].id).to eq(@ta1.id).or eq(@ta2.id)
          expect(@ta1.groupings.length > @ta2.groupings.length).to be true
        end

        it 'and multiple graders and multiple groupings are selected' do
          @ta3 = create(:ta)
          post_as @instructor,
                  :global_actions,
                  params: { course_id: course.id, assignment_id: @assignment.id, global_actions: 'random_assign',
                            groupings: [@grouping1.id, @grouping2.id, @grouping3.id],
                            graders: [@ta1.id, @ta2.id, @ta3.id],
                            weightings: [1, 1, 1], current_table: 'groups_table' }
          expect(response).to have_http_status(:ok)
          expect(@grouping1.tas.size).to eq 1
          expect(@grouping2.tas.size).to eq 1
          expect(@grouping3.tas.size).to eq 1
        end

        it 'and weights all being 0 results in nothing being assigned' do
          post_as @instructor,
                  :global_actions,
                  params: { course_id: course.id, assignment_id: @assignment.id, global_actions: 'random_assign',
                            groupings: [@grouping1.id, @grouping2.id, @grouping3.id], graders: [@ta1.id, @ta2.id],
                            weightings: [0, 0], current_table: 'groups_table' }
          expect(@grouping1.tas.size).to eq 0
          expect(@grouping2.tas.size).to eq 0
        end

        it 'and any weight being negative results in nothing being assigned' do
          post_as @instructor,
                  :global_actions,
                  params: { course_id: course.id, assignment_id: @assignment.id, global_actions: 'random_assign',
                            groupings: [@grouping1.id, @grouping2.id, @grouping3.id], graders: [@ta1.id, @ta2.id],
                            weightings: [-1, 1], current_table: 'groups_table' }
          expect(@grouping1.tas.size).to eq 0
          expect(@grouping2.tas.size).to eq 0
        end

        it 'and weights being invalid results in nothing being assigned' do
          post_as @instructor,
                  :global_actions,
                  params: { course_id: course.id, assignment_id: @assignment.id, global_actions: 'random_assign',
                            groupings: [@grouping1.id, @grouping2.id, @grouping3.id], graders: [@ta1.id, @ta2.id],
                            weightings: [[], 0], current_table: 'groups_table' }
          expect(@grouping1.tas.size).to eq 0
          expect(@grouping2.tas.size).to eq 0
        end

        it 'and weights being an invalid string results in nothing being assigned' do
          post_as @instructor,
                  :global_actions,
                  params: { course_id: course.id, assignment_id: @assignment.id, global_actions: 'random_assign',
                            groupings: [@grouping1.id, @grouping2.id, @grouping3.id], graders: [@ta1.id, @ta2.id],
                            weightings: ['weight', 0], current_table: 'groups_table' }
          expect(@grouping1.tas.size).to eq 0
          expect(@grouping2.tas.size).to eq 0
        end

        it 'and only inactive graders (and multiple groupings) are selected' do
          post_as @instructor,
                  :global_actions,
                  params: {
                    course_id: course.id, assignment_id: @assignment.id, global_actions: 'random_assign',
                    groupings: [@grouping1.id, @grouping2.id, @grouping3.id], graders: [@ta4.id, @ta5.id],
                    weightings: [1, 1], current_table: 'groups_table'
                  }
          expect(response).to have_http_status(:ok)
          @assignment.groupings.each do |grouping|
            expect(grouping.tas).to eq []
          end
        end

        it 'and both active and inactive graders (and multiple groupings) are selected' do
          # In this case, the active graders should be assigned to the specified groups but the inactive
          # ones should not
          post_as @instructor,
                  :global_actions,
                  params: {
                    course_id: course.id, assignment_id: @assignment.id, global_actions: 'random_assign',
                    groupings: [@grouping1.id, @grouping2.id], graders: [@ta1.id, @ta4.id],
                    weightings: [1, 1], current_table: 'groups_table'
                  }

          expect(response).to have_http_status(:ok)

          expect(@grouping1.tas[0].id).to eq(@ta1.id)
          expect(@grouping2.tas[0].id).to eq(@ta1.id)
          expect(@grouping3.tas).to eq []

          expect(@grouping1.tas.size).to eq(1)
          expect(@grouping2.tas.size).to eq(1)
          expect(@grouping3.tas.size).to eq(0)
        end
      end

      context 'POST on :global_actions on assign' do
        before do
          @grouping1 = create(:grouping, assignment: @assignment)
          @grouping2 = create(:grouping, assignment: @assignment)
          @grouping3 = create(:grouping, assignment: @assignment)
          @grouping4 = create(:grouping, assignment: @assignment)
          @ta1 = create(:ta)
          @ta2 = create(:ta)
          @ta3 = create(:ta)

          # Making two new TA's that are 'inactive', to test additional functionality
          @ta4 = create(:ta, hidden: true)
          @ta5 = create(:ta, hidden: true)
        end

        it 'and no graders selected' do
          post_as @instructor,
                  :global_actions,
                  params: { course_id: course.id, assignment_id: @assignment.id,
                            global_actions: 'assign', current_table: 'groups_table' }
          expect(response).to have_http_status(:bad_request)
          @assignment.groupings.each do |grouping|
            expect(grouping.tas).to eq []
          end
        end

        it 'and no groupings selected, at least one grader' do
          post_as @instructor,
                  :global_actions,
                  params: { course_id: course.id, assignment_id: @assignment.id, global_actions: 'assign',
                            graders: [@ta1.id], current_table: 'groups_table' }
          expect(response).to have_http_status(:bad_request)
          @assignment.groupings.each do |grouping|
            expect(grouping.tas).to eq []
          end
        end

        it 'and no graders are selected, at least one grouping' do
          post_as @instructor,
                  :global_actions,
                  params: { course_id: course.id, assignment_id: @assignment.id, global_actions: 'assign',
                            groupings: [@grouping1.id], current_table: 'groups_table' }
          expect(response).to have_http_status(:bad_request)
          @assignment.groupings.each do |grouping|
            expect(grouping.tas).to eq []
          end
        end

        it 'and one grader and one grouping is selected' do
          post_as @instructor,
                  :global_actions,
                  params: { course_id: course.id, assignment_id: @assignment.id, global_actions: 'assign',
                            groupings: [@grouping1.id], graders: [@ta1.id], current_table: 'groups_table' }
          expect(response).to have_http_status(:ok)
          expect(@grouping1.tas[0].id).to eq @ta1.id
          expect(@grouping2.tas).to eq []
          expect(@grouping3.tas).to eq []
        end

        it 'and one grader and two groupings are selected' do
          post_as @instructor,
                  :global_actions,
                  params: { course_id: course.id, assignment_id: @assignment.id, global_actions: 'assign',
                            groupings: [@grouping1.id, @grouping2.id],
                            graders: [@ta1.id], current_table: 'groups_table' }
          expect(response).to have_http_status(:ok)
          expect(@grouping1.tas[0].id).to eq @ta1.id
          expect(@grouping2.tas[0].id).to eq @ta1.id
          expect(@grouping3.tas).to eq []
        end

        it 'and two graders and one grouping is selected' do
          post_as @instructor,
                  :global_actions,
                  params: { course_id: course.id, assignment_id: @assignment.id, global_actions: 'assign',
                            groupings: [@grouping1.id], graders: [@ta1.id, @ta2.id], current_table: 'groups_table' }
          expect(response).to have_http_status(:ok)
          expect(@grouping1.tas.length).to eq 2
          expect(@grouping1.tas).to include(@ta1)
          expect(@grouping1.tas).to include(@ta2)
          expect(@grouping2.tas).to eq []
          expect(@grouping3.tas).to eq []
        end

        it 'and two graders and two groupings are selected' do
          post_as @instructor,
                  :global_actions,
                  params: { course_id: course.id, assignment_id: @assignment.id, global_actions: 'assign',
                            groupings: [@grouping1.id, @grouping2.id], graders: [@ta1.id, @ta2.id],
                            current_table: 'groups_table' }
          expect(response).to have_http_status(:ok)
          expect(@grouping1.tas.length).to eq 2
          expect(@grouping1.tas).to include(@ta1)
          expect(@grouping1.tas).to include(@ta2)
          expect(@grouping2.tas.length).to eq 2
          expect(@grouping2.tas).to include(@ta1)
          expect(@grouping2.tas).to include(@ta2)
          expect(@grouping3.tas).to eq []
        end

        it 'and multiple graders and multiple groupings are selected' do
          @ta3 = create(:ta)
          post_as @instructor,
                  :global_actions,
                  params: { course_id: course.id, assignment_id: @assignment.id, global_actions: 'assign',
                            groupings: [@grouping1.id, @grouping2.id, @grouping3.id],
                            graders: [@ta1.id, @ta2.id, @ta3.id],
                            current_table: 'groups_table' }
          expect(response).to have_http_status(:ok)
          expect(@grouping1.tas.length).to eq 3
          expect(@grouping1.tas).to include(@ta1)
          expect(@grouping1.tas).to include(@ta2)
          expect(@grouping1.tas).to include(@ta3)
          expect(@grouping2.tas.length).to eq 3
          expect(@grouping2.tas).to include(@ta1)
          expect(@grouping2.tas).to include(@ta2)
          expect(@grouping2.tas).to include(@ta3)
        end

        it 'and some graders are already assigned to some groups' do
          create(:ta_membership, role: @ta1, grouping: @grouping2)
          create(:ta_membership, role: @ta2, grouping: @grouping1)
          post_as @instructor,
                  :global_actions,
                  params: { course_id: course.id, assignment_id: @assignment.id, global_actions: 'assign',
                            groupings: [@grouping1.id, @grouping2.id], graders: [@ta1.id, @ta2.id],
                            current_table: 'groups_table' }
          expect(response).to have_http_status(:ok)
          expect(@grouping1.tas.length).to eq 2
          expect(@grouping1.tas).to include(@ta1)
          expect(@grouping1.tas).to include(@ta2)
          expect(@grouping2.tas.length).to eq 2
          expect(@grouping2.tas).to include(@ta1)
          expect(@grouping2.tas).to include(@ta2)
          expect(@grouping3.tas).to eq []
        end

        it 'and only inactive graders (and multiple groupings) are selected' do
          post_as @instructor,
                  :global_actions,
                  params: {
                    course_id: course.id, assignment_id: @assignment.id, global_actions: 'assign',
                    groupings: [@grouping1.id, @grouping2.id], graders: [@ta4.id, @ta5.id],
                    current_table: 'groups_table'
                  }

          expect(response).to have_http_status(:ok)
          @assignment.groupings.each do |grouping|
            expect(grouping.tas).to eq []
          end
        end

        it 'and both active and inactive graders (and multiple groupings) are selected' do
          # In this case, the active graders should be assigned to the specified groups but the inactive
          # ones should not.
          post_as @instructor,
                  :global_actions,
                  params: {
                    course_id: course.id, assignment_id: @assignment.id, global_actions: 'assign',
                    groupings: [@grouping1.id, @grouping3.id], graders: [@ta2.id, @ta5.id],
                    current_table: 'groups_table'
                  }

          expect(response).to have_http_status(:ok)

          expect(@grouping1.tas[0].id).to eq(@ta2.id)
          expect(@grouping2.tas).to eq([])
          expect(@grouping3.tas[0].id).to eq(@ta2.id)

          expect(@grouping1.tas.size).to eq(1)
          expect(@grouping2.tas.size).to eq(0)
          expect(@grouping3.tas.size).to eq(1)
        end

        context 'and skip_empty_submissions is true' do
          before do
            submission
            post_as @instructor, :global_actions, params: { course_id: course.id, assignment_id: @assignment.id,
                                                            global_actions: 'assign', groupings: [@grouping1.id],
                                                            graders: [@ta1.id], current_table: 'groups_table',
                                                            skip_empty_submissions: 'true' }
          end

          context 'and the group has no submission' do
            let(:submission) { nil }

            it 'should not assign graders' do
              expect(@grouping1.tas).to be_empty
            end
          end

          context 'and the group has a non-empty submission' do
            let(:submission) { create(:version_used_submission, grouping: @grouping1, is_empty: false) }

            it 'should assign graders' do
              expect(@grouping1.tas).to include(@ta1)
            end
          end

          context 'and the group has an empty submission' do
            let(:submission) { create(:version_used_submission, grouping: @grouping1, is_empty: true) }

            it 'should assign graders' do
              expect(@grouping1.tas).to be_empty
            end
          end
        end

        context 'and when assigning to multiple groupings and skip_empty_submissions is true' do
          before do
            # defining submissions for use in the 'asisgn' post
            submission
            submission2
            submission3
            submission4
            post_as @instructor,
                    :global_actions,
                    params: { course_id: course.id, assignment_id: @assignment.id, global_actions: 'assign',
                              groupings: [@grouping1.id, @grouping2.id, @grouping3.id, @grouping4.id],
                              graders: [@ta1.id], current_table: 'groups_table', skip_empty_submissions: 'true' }
          end

          context 'and some groups have empty submissions while some do not' do
            let(:submission) { create(:version_used_submission, grouping: @grouping1, is_empty: true) }
            let(:submission2) { create(:version_used_submission, grouping: @grouping2, is_empty: false) }
            let(:submission3) { create(:version_used_submission, grouping: @grouping3, is_empty: true) }
            let(:submission4) { create(:version_used_submission, grouping: @grouping4, is_empty: false) }

            it 'should not assign graders to groups with empty submissions' do
              expect(@grouping1.tas).to be_empty
              expect(@grouping3.tas).to be_empty
            end

            it 'should assign graders to groups with non-empty submissions' do
              expect(@grouping2.tas).to include(@ta1)
              expect(@grouping4.tas).to include(@ta1)
            end
          end
        end
      end

      context 'POST on :global_actions on assign_sections' do
        before do
          @section1 = create(:section)
          @section2 = create(:section)
          @section3 = create(:section)

          @student1 = create(:student, section: @section1)
          @student2 = create(:student, section: @section2)
          @student3 = create(:student, section: @section3)

          @grouping1 = create(:grouping, assignment: @assignment)
          @grouping2 = create(:grouping, assignment: @assignment)
          @grouping3 = create(:grouping, assignment: @assignment)

          create(:student_membership, grouping: @grouping1, role: @student1,
                                      membership_status: StudentMembership::STATUSES[:inviter])
          create(:student_membership, grouping: @grouping2, role: @student2,
                                      membership_status: StudentMembership::STATUSES[:inviter])
          create(:student_membership, grouping: @grouping3, role: @student3,
                                      membership_status: StudentMembership::STATUSES[:inviter])

          @ta1 = create(:ta)
          @ta2 = create(:ta)
          @ta3 = create(:ta)

          # Making two new TAs that are 'inactive', to test additional functionality
          @ta4 = create(:ta, hidden: true)
          @ta5 = create(:ta, hidden: true)
        end

        it 'assigns one TA to one section' do
          post_as @instructor,
                  :global_actions,
                  params: {
                    course_id: course.id,
                    assignment_id: @assignment.id,
                    global_actions: 'assign_sections',
                    assignments: { @section1.name => @ta1.id },
                    current_table: 'groups_table'
                  }
          expect(response).to have_http_status(:ok)
          expect(@grouping1.tas[0].id).to eq @ta1.id
          expect(@grouping2.tas).to eq []
          expect(@grouping3.tas).to eq []
        end

        it 'returns bad request when no sections are selected' do
          post_as @instructor,
                  :global_actions,
                  params: {
                    course_id: course.id,
                    assignment_id: @assignment.id,
                    global_actions: 'assign_sections',
                    assignments: {},
                    current_table: 'groups_table'
                  }
          expect(response).to have_http_status(:bad_request)
          @assignment.groupings.each do |grouping|
            expect(grouping.tas).to eq []
          end
        end

        it 'assigns multiple TAs to different sections' do
          post_as @instructor,
                  :global_actions,
                  params: {
                    course_id: course.id,
                    assignment_id: @assignment.id,
                    global_actions: 'assign_sections',
                    assignments: { @section1.name => @ta1.id, @section2.name => @ta2.id },
                    current_table: 'groups_table'
                  }
          expect(response).to have_http_status(:ok)
          expect(@grouping1.tas[0].id).to eq @ta1.id
          expect(@grouping2.tas[0].id).to eq @ta2.id
          expect(@grouping3.tas).to eq []
        end

        it 'skips empty submissions when specified' do
          allow_any_instance_of(GradersController).to receive(:filter_empty_submissions).and_return([])

          post_as @instructor,
                  :global_actions,
                  params: {
                    course_id: course.id,
                    assignment_id: @assignment.id,
                    global_actions: 'assign_sections',
                    assignments: { @section1.name => @ta1.id },
                    skip_empty_submissions: 'true',
                    current_table: 'groups_table'
                  }
          expect(response).to have_http_status(:ok)
          expect(@grouping1.tas).to eq []
          expect(@grouping2.tas).to eq []
          expect(@grouping3.tas).to eq []
        end
      end

      context 'POST on :global_actions on unassign' do
        before do
          @grouping1 = create(:grouping, assignment: @assignment)
          @grouping2 = create(:grouping, assignment: @assignment)
          @grouping3 = create(:grouping, assignment: @assignment)
          @ta1 = create(:ta)
          @ta2 = create(:ta)
          @ta3 = create(:ta)

          # Making two new TA's that are 'inactive', to test additional functionality
          @ta4 = create(:ta, hidden: true)
          @ta5 = create(:ta, hidden: true)
        end

        it 'and no graders or groupings are selected' do
          create(:ta_membership, role: @ta1, grouping: @grouping1)
          create(:ta_membership, role: @ta2, grouping: @grouping2)
          post_as @instructor,
                  :global_actions,
                  params: { course_id: course.id, assignment_id: @assignment.id,
                            global_actions: 'unassign', current_table: 'groups_table' }
          expect(response).to have_http_status(:bad_request)
          expect(@grouping1.tas).to eq [@ta1]
          expect(@grouping2.tas).to eq [@ta2]
          expect(@grouping3.tas).to eq []
        end

        it 'and all graders from one grouping are selected' do
          create(:ta_membership, role: @ta1, grouping: @grouping1)
          create(:ta_membership, role: @ta2, grouping: @grouping1)
          create(:ta_membership, role: @ta3, grouping: @grouping1)
          create(:ta_membership, role: @ta3, grouping: @grouping3)
          post_as @instructor,
                  :global_actions,
                  params: { course_id: course.id, assignment_id: @assignment.id, global_actions: 'unassign',
                            groupings: [@grouping1.id],
                            graders: [@ta1.id, @ta2.id, @ta3.id],
                            current_table: 'groups_table' }
          expect(response).to have_http_status(:ok)
          expect(@grouping1.tas).to eq []
          expect(@grouping2.tas).to eq []
          expect(@grouping3.tas).to eq [@ta3]
        end

        it 'and all groupings from one grader are selected' do
          create(:ta_membership, role: @ta1, grouping: @grouping1)
          create(:ta_membership, role: @ta2, grouping: @grouping1)
          create(:ta_membership, role: @ta3, grouping: @grouping1)
          create(:ta_membership, role: @ta3, grouping: @grouping2)
          create(:ta_membership, role: @ta3, grouping: @grouping3)
          post_as @instructor,
                  :global_actions,
                  params: { course_id: course.id, assignment_id: @assignment.id, global_actions: 'unassign',
                            groupings: [@grouping1.id, @grouping2.id, @grouping3.id],
                            graders: [@ta3.id],
                            current_table: 'groups_table' }
          expect(response).to have_http_status(:ok)
          expect(@grouping1.tas).not_to include(@ta3)
          expect(@grouping2.tas).not_to include(@ta3)
          expect(@grouping3.tas).not_to include(@ta3)
          expect(@grouping1.tas).to include(@ta1)
          expect(@grouping1.tas).to include(@ta2)
        end

        it 'and one grader and one grouping is selected where the grader and grouping have other memberships' do
          create(:ta_membership, role: @ta1, grouping: @grouping2)
          create(:ta_membership, role: @ta1, grouping: @grouping1)
          create(:ta_membership, role: @ta2, grouping: @grouping1)
          create(:ta_membership, role: @ta3, grouping: @grouping1)
          create(:ta_membership, role: @ta2, grouping: @grouping2)
          create(:ta_membership, role: @ta3, grouping: @grouping2)
          create(:ta_membership, role: @ta1, grouping: @grouping3)
          create(:ta_membership, role: @ta2, grouping: @grouping3)
          create(:ta_membership, role: @ta3, grouping: @grouping3)
          post_as @instructor,
                  :global_actions,
                  params: { course_id: course.id, assignment_id: @assignment.id, global_actions: 'unassign',
                            groupings: [@grouping2.id],
                            graders: [@ta1.id],
                            current_table: 'groups_table' }
          expect(response).to have_http_status(:ok)
          expect(@grouping2.tas).not_to include(@ta1)
          expect(@grouping1.tas).to include(@ta1)
          expect(@grouping1.tas).to include(@ta2)
          expect(@grouping1.tas).to include(@ta3)
          expect(@grouping2.tas).to include(@ta2)
          expect(@grouping2.tas).to include(@ta3)
          expect(@grouping3.tas).to include(@ta1)
          expect(@grouping3.tas).to include(@ta2)
          expect(@grouping3.tas).to include(@ta3)
        end

        it 'and multiple graders and multiple groupings are selected' do
          create(:ta_membership, role: @ta1, grouping: @grouping1)
          create(:ta_membership, role: @ta2, grouping: @grouping1)
          create(:ta_membership, role: @ta3, grouping: @grouping1)
          create(:ta_membership, role: @ta1, grouping: @grouping2)
          create(:ta_membership, role: @ta2, grouping: @grouping2)
          create(:ta_membership, role: @ta3, grouping: @grouping2)
          create(:ta_membership, role: @ta1, grouping: @grouping3)
          create(:ta_membership, role: @ta2, grouping: @grouping3)
          create(:ta_membership, role: @ta3, grouping: @grouping3)
          post_as @instructor,
                  :global_actions,
                  params: { course_id: course.id, assignment_id: @assignment.id, global_actions: 'unassign',
                            groupings: [@grouping1.id, @grouping2.id, @grouping3.id],
                            graders: [@ta1.id, @ta2.id, @ta3.id],
                            current_table: 'groups_table' }
          expect(response).to have_http_status(:ok)
          expect(@grouping1.tas).to eq []
          expect(@grouping2.tas).to eq []
          expect(@grouping3.tas).to eq []
        end

        it 'and inactive graders are selected' do
          # An instructor should be able to unassign inactive graders from groupings (inactivity only plays
          # a role in assigning and random-assigning)
          create(:ta_membership, role: @ta4, grouping: @grouping1)
          create(:ta_membership, role: @ta5, grouping: @grouping1)
          create(:ta_membership, role: @ta4, grouping: @grouping2)
          create(:ta_membership, role: @ta5, grouping: @grouping2)
          create(:ta_membership, role: @ta4, grouping: @grouping3)
          create(:ta_membership, role: @ta5, grouping: @grouping3)
          post_as @instructor,
                  :global_actions,
                  params: { course_id: course.id, assignment_id: @assignment.id, global_actions: 'unassign',
                            groupings: [@grouping1.id, @grouping2.id, @grouping3.id],
                            graders: [@ta4.id, @ta5.id],
                            current_table: 'groups_table' }
          expect(response).to have_http_status(:ok)
          expect(@grouping1.tas).to eq []
          expect(@grouping2.tas).to eq []
          expect(@grouping3.tas).to eq []
        end
      end
    end

    context 'With criteria table selected' do
      context 'with rubric marking scheme doing a' do
        context 'POST on :global_actions on random_assign' do
          before do
            @criterion1 = create(:rubric_criterion, assignment: @assignment)
            @criterion2 = create(:rubric_criterion, assignment: @assignment)
            @criterion3 = create(:rubric_criterion, assignment: @assignment)
            @ta1 = create(:ta)
            @ta2 = create(:ta)
            @ta3 = create(:ta)
          end

          it 'and no graders selected' do
            post_as @instructor,
                    :global_actions,
                    params: { course_id: course.id, assignment_id: @assignment.id, global_actions: 'random_assign',
                              current_table: 'criteria_table' }
            expect(response).to have_http_status(:bad_request)
            @assignment.criteria.each do |criterion|
              expect(criterion.tas).to eq []
            end
          end

          it 'and no criteria selected, at least one grader' do
            post_as @instructor,
                    :global_actions,
                    params: { course_id: course.id, assignment_id: @assignment.id,
                              global_actions: 'random_assign', graders: [@ta1.id], current_table: 'criteria_table' }
            expect(response).to have_http_status(:bad_request)
            @assignment.criteria.each do |criterion|
              expect(criterion.tas).to eq []
            end
          end

          it 'and no graders are selected, at least one criterion' do
            post_as @instructor,
                    :global_actions,
                    params: { course_id: course.id, assignment_id: @assignment.id, global_actions: 'random_assign',
                              criteria: [@criterion1.position],
                              current_table: 'criteria_table' }
            expect(response).to have_http_status(:bad_request)
            @assignment.criteria.each do |criterion|
              expect(criterion.tas).to eq []
            end
          end

          it 'and one grader and one criterion is selected' do
            post_as @instructor,
                    :global_actions,
                    params: { course_id: course.id, assignment_id: @assignment.id, global_actions: 'random_assign',
                              criteria: [@criterion1.position],
                              graders: [@ta1.id],
                              current_table: 'criteria_table' }
            expect(response).to have_http_status(:ok)
            expect(@criterion1.tas[0].id).to eq @ta1.id
            expect(@criterion2.tas).to eq []
            expect(@criterion3.tas).to eq []
          end

          it 'and one grader and multiple criteria are selected' do
            post_as @instructor,
                    :global_actions,
                    params: { course_id: course.id, assignment_id: @assignment.id, global_actions: 'random_assign',
                              criteria: [@criterion1.position, @criterion2.position],
                              graders: [@ta1.id], current_table: 'criteria_table' }
            expect(response).to have_http_status(:ok)
            expect(@criterion1.tas[0].id).to eq @ta1.id
            expect(@criterion2.tas[0].id).to eq @ta1.id
            expect(@criterion3.tas).to eq []
          end

          it 'and two graders and one criterion is selected' do
            post_as @instructor,
                    :global_actions,
                    params: { course_id: course.id, assignment_id: @assignment.id, global_actions: 'random_assign',
                              criteria: [@criterion1.position],
                              graders: [@ta1.id, @ta2.id], current_table:  'criteria_table' }
            expect(response).to have_http_status(:ok)
            expect(@criterion1.tas[0].id).to eq(@ta1.id).or(eq(@ta2.id))
            expect(@criterion2.tas).to eq []
            expect(@criterion3.tas).to eq []
          end

          it 'and two graders and two criteria are selected' do
            post_as @instructor,
                    :global_actions,
                    params: { course_id: course.id, assignment_id: @assignment.id, global_actions: 'random_assign',
                              criteria: [@criterion1.position, @criterion2.position],
                              graders: [@ta1.id, @ta2.id], current_table: 'criteria_table' }
            expect(response).to have_http_status(:ok)
            expect(@criterion1.tas[0].id).to eq(@ta1.id).or(eq(@ta2.id))
            expect(@criterion2.tas[0].id).to eq(@ta1.id).or(eq(@ta2.id))
            expect(@criterion1.tas[0].id).not_to eq @criterion2.tas[0].id
            expect(@criterion3.tas).to eq []
          end

          it 'and multiple graders and multiple criteria are selected' do
            @ta3 = create(:ta)
            post_as @instructor,
                    :global_actions,
                    params: { course_id: course.id, assignment_id: @assignment.id, global_actions: 'random_assign',
                              criteria: [@criterion1.position, @criterion2.position, @criterion3.position],
                              graders: [@ta1.id, @ta2.id, @ta3.id], current_table: 'criteria_table' }
            expect(response).to have_http_status(:ok)
            expect(@criterion1.tas.size).to eq(1)
            expect(@criterion2.tas.size).to eq(1)
            expect(@criterion3.tas.size).to eq(1)
          end
        end

        context 'POST on :global_actions on assign' do
          before do
            @criterion1 = create(:rubric_criterion, assignment: @assignment)
            @criterion2 = create(:rubric_criterion, assignment: @assignment)
            @criterion3 = create(:rubric_criterion, assignment: @assignment)
            @ta1 = create(:ta)
            @ta2 = create(:ta)
            @ta3 = create(:ta)
          end

          it 'and no graders selected' do
            post_as @instructor,
                    :global_actions,
                    params: { course_id: course.id, assignment_id: @assignment.id,
                              global_actions: 'assign', current_table: 'criteria_table' }
            expect(response).to have_http_status(:bad_request)
            @assignment.criteria.each do |criterion|
              expect(criterion.tas).to eq []
            end
          end

          it 'and no criteria selected, at least one grader' do
            post_as @instructor,
                    :global_actions,
                    params: { course_id: course.id, assignment_id: @assignment.id,
                              global_actions: 'assign', graders: [@ta1.id], current_table: 'criteria_table' }
            expect(response).to have_http_status(:bad_request)
            @assignment.criteria.each do |criterion|
              expect(criterion.tas).to eq []
            end
          end

          it 'and no graders are selected, at least one criterion' do
            post_as @instructor,
                    :global_actions,
                    params: { course_id: course.id, assignment_id: @assignment.id, global_actions: 'assign',
                              criteria: [@criterion1.position],
                              current_table: 'criteria_table' }
            expect(response).to have_http_status(:bad_request)
            @assignment.criteria.each do |criterion|
              expect(criterion.tas).to eq []
            end
          end

          it 'and one grader and one criterion is selected' do
            post_as @instructor,
                    :global_actions,
                    params: { course_id: course.id, assignment_id: @assignment.id, global_actions: 'assign',
                              criteria: [@criterion1.position],
                              graders: [@ta1.id],
                              current_table: 'criteria_table' }
            expect(response).to have_http_status(:ok)
            expect(@criterion1.tas[0].id).to eq @ta1.id
            expect(@criterion2.tas).to eq []
            expect(@criterion3.tas).to eq []
          end

          it 'and one grader and two criteria are selected' do
            post_as @instructor,
                    :global_actions,
                    params: { course_id: course.id, assignment_id: @assignment.id, global_actions: 'assign',
                              criteria: [@criterion1.position, @criterion2.position],
                              graders: [@ta1.id],
                              current_table: 'criteria_table' }
            expect(response).to have_http_status(:ok)
            expect(@criterion1.tas[0].id).to eq @ta1.id
            expect(@criterion2.tas[0].id).to eq @ta1.id
            expect(@criterion3.tas).to eq []
          end

          it 'and two graders and one criterion is selected' do
            post_as @instructor,
                    :global_actions,
                    params: { course_id: course.id, assignment_id: @assignment.id, global_actions: 'assign',
                              criteria: [@criterion1.position],
                              graders: [@ta1.id, @ta2.id],
                              current_table: 'criteria_table' }
            expect(response).to have_http_status(:ok)
            expect(@criterion1.tas.length).to eq 2
            expect(@criterion1.tas).to include(@ta1)
            expect(@criterion1.tas).to include(@ta2)
            expect(@criterion2.tas).to eq []
            expect(@criterion3.tas).to eq []
          end

          it 'and two graders and two criteria are selected' do
            post_as @instructor,
                    :global_actions,
                    params: { course_id: course.id, assignment_id: @assignment.id, global_actions: 'assign',
                              criteria: [@criterion1.position, @criterion2.position],
                              graders: [@ta1.id, @ta2.id],
                              current_table: 'criteria_table' }
            expect(response).to have_http_status(:ok)
            expect(@criterion1.tas.length).to eq 2
            expect(@criterion1.tas).to include(@ta1)
            expect(@criterion1.tas).to include(@ta2)
            expect(@criterion2.tas.length).to eq 2
            expect(@criterion2.tas).to include(@ta1)
            expect(@criterion2.tas).to include(@ta2)
            expect(@criterion3.tas).to eq []
          end

          it 'and multiple graders and multiple criteria are selected' do
            @ta3 = create(:ta)
            post_as @instructor,
                    :global_actions,
                    params: { course_id: course.id, assignment_id: @assignment.id, global_actions: 'assign',
                              criteria: [@criterion1.position, @criterion2.position, @criterion3.position],
                              graders: [@ta1.id, @ta2.id, @ta3.id], current_table: 'criteria_table' }
            expect(response).to have_http_status(:ok)
            expect(@criterion1.tas.length).to eq 3
            expect(@criterion1.tas).to include(@ta1)
            expect(@criterion1.tas).to include(@ta2)
            expect(@criterion1.tas).to include(@ta3)
            expect(@criterion2.tas.length).to eq 3
            expect(@criterion2.tas).to include(@ta1)
            expect(@criterion2.tas).to include(@ta2)
            expect(@criterion2.tas).to include(@ta3)
          end

          it 'and some graders are already assigned to some criteria' do
            CriterionTaAssociation.create(ta: @ta1, criterion: @criterion2)
            CriterionTaAssociation.create(ta: @ta2, criterion: @criterion1)
            post_as @instructor,
                    :global_actions,
                    params: { course_id: course.id, assignment_id: @assignment.id, global_actions: 'assign',
                              criteria: [@criterion1.position, @criterion2.position],
                              graders: [@ta1.id, @ta2.id],
                              current_table: 'criteria_table' }

            expect(response).to have_http_status(:ok)
            @criterion1.reload
            @criterion2.reload
            @criterion3.reload
            expect(@criterion1.tas.length).to eq 2
            expect(@criterion1.tas).to include(@ta1)
            expect(@criterion1.tas).to include(@ta2)
            expect(@criterion2.tas.length).to eq 2
            expect(@criterion2.tas).to include(@ta1)
            expect(@criterion2.tas).to include(@ta2)
            expect(@criterion3.tas).to eq []
          end
        end

        context 'POST on :global_actions on unassign' do
          before do
            @criterion1 = create(:rubric_criterion, assignment: @assignment)
            @criterion2 = create(:rubric_criterion, assignment: @assignment)
            @criterion3 = create(:rubric_criterion, assignment: @assignment)
            @ta1 = create(:ta)
            @ta2 = create(:ta)
            @ta3 = create(:ta)
          end

          it 'and no graders or criteria are selected' do
            CriterionTaAssociation.create(ta: @ta1, criterion: @criterion1)
            CriterionTaAssociation.create(ta: @ta2, criterion: @criterion2)
            post_as @instructor,
                    :global_actions,
                    params: { course_id: course.id, assignment_id: @assignment.id, global_actions: 'unassign',
                              current_table: 'criteria_table' }
            expect(response).to have_http_status(:bad_request)
            @criterion1.reload
            @criterion2.reload
            @criterion3.reload
            expect(@criterion1.tas).to eq [@ta1]
            expect(@criterion2.tas).to eq [@ta2]
            expect(@criterion3.tas).to eq []
          end

          it 'and all graders from one criterion are selected' do
            CriterionTaAssociation.create(ta: @ta1, criterion: @criterion1)
            CriterionTaAssociation.create(ta: @ta2, criterion: @criterion1)
            CriterionTaAssociation.create(ta: @ta3, criterion: @criterion1)
            CriterionTaAssociation.create(ta: @ta3, criterion: @criterion3)
            post_as @instructor,
                    :global_actions,
                    params: { course_id: course.id, assignment_id: @assignment.id, global_actions: 'unassign',
                              criteria: [@criterion1.position],
                              graders: [@ta1.id, @ta2.id, @ta3.id],
                              current_table: 'criteria_table' }
            expect(response).to have_http_status(:ok)
            @criterion1.reload
            expect(@criterion1.tas).to eq []
            @criterion2.reload
            @criterion3.reload
            expect(@criterion2.tas).to eq []
            expect(@criterion3.tas).to eq [@ta3]
          end

          it 'and all criteria from one grader are selected' do
            CriterionTaAssociation.create(ta: @ta1, criterion: @criterion1)
            CriterionTaAssociation.create(ta: @ta2, criterion: @criterion1)
            CriterionTaAssociation.create(ta: @ta3, criterion: @criterion1)
            CriterionTaAssociation.create(ta: @ta3, criterion: @criterion2)
            CriterionTaAssociation.create(ta: @ta3, criterion: @criterion3)
            post_as @instructor,
                    :global_actions,
                    params: { course_id: course.id, assignment_id: @assignment.id, global_actions: 'unassign',
                              criteria: [@criterion1.position, @criterion2.position, @criterion3.position],
                              graders: [@ta3.id],
                              current_table: 'criteria_table' }
            expect(response).to have_http_status(:ok)
            @criterion1.reload
            @criterion2.reload
            @criterion3.reload
            expect(@criterion1.tas).not_to include(@ta3)
            expect(@criterion2.tas).not_to include(@ta3)
            expect(@criterion3.tas).not_to include(@ta3)
            @criterion1.reload
            expect(@criterion1.tas).to include(@ta1)
            expect(@criterion1.tas).to include(@ta2)
          end

          it 'and one grader and one criterion is selected where the grader and criterion have other memberships' do
            CriterionTaAssociation.create(ta: @ta1, criterion: @criterion1)
            CriterionTaAssociation.create(ta: @ta2, criterion: @criterion1)
            CriterionTaAssociation.create(ta: @ta3, criterion: @criterion1)
            CriterionTaAssociation.create(ta: @ta1, criterion: @criterion2)
            CriterionTaAssociation.create(ta: @ta2, criterion: @criterion2)
            CriterionTaAssociation.create(ta: @ta3, criterion: @criterion2)
            CriterionTaAssociation.create(ta: @ta1, criterion: @criterion3)
            CriterionTaAssociation.create(ta: @ta2, criterion: @criterion3)
            CriterionTaAssociation.create(ta: @ta3, criterion: @criterion3)
            post_as @instructor,
                    :global_actions,
                    params: { course_id: course.id, assignment_id: @assignment.id, global_actions: 'unassign',
                              graders: [@ta1.id],
                              criteria: [@criterion2.position],
                              current_table: 'criteria_table' }
            expect(response).to have_http_status(:ok)
            expect(@criterion2.tas).not_to include(@ta1)
            @criterion1.reload
            @criterion2.reload
            @criterion3.reload
            expect(@criterion1.tas).to include(@ta1)
            expect(@criterion1.tas).to include(@ta2)
            expect(@criterion1.tas).to include(@ta3)
            expect(@criterion2.tas).to include(@ta2)
            expect(@criterion2.tas).to include(@ta3)
            expect(@criterion3.tas).to include(@ta1)
            expect(@criterion3.tas).to include(@ta2)
            expect(@criterion3.tas).to include(@ta3)
          end

          it 'and multiple graders and multiple criteria are selected' do
            CriterionTaAssociation.create(ta: @ta1, criterion: @criterion1)
            CriterionTaAssociation.create(ta: @ta2, criterion: @criterion1)
            CriterionTaAssociation.create(ta: @ta3, criterion: @criterion1)
            CriterionTaAssociation.create(ta: @ta1, criterion: @criterion2)
            CriterionTaAssociation.create(ta: @ta2, criterion: @criterion2)
            CriterionTaAssociation.create(ta: @ta3, criterion: @criterion2)
            CriterionTaAssociation.create(ta: @ta1, criterion: @criterion3)
            CriterionTaAssociation.create(ta: @ta2, criterion: @criterion3)
            CriterionTaAssociation.create(ta: @ta3, criterion: @criterion3)
            post_as @instructor,
                    :global_actions,
                    params: { course_id: course.id, assignment_id: @assignment.id, global_actions: 'unassign',
                              criteria: [@criterion1.position, @criterion2.position, @criterion3.position],
                              graders: [@ta1.id, @ta2.id, @ta3.id],
                              current_table: 'criteria_table' }
            expect(response).to have_http_status(:ok)
            @criterion1.reload
            @criterion2.reload
            @criterion3.reload
            expect(@criterion1.tas).to eq []
            expect(@criterion2.tas).to eq []
            expect(@criterion3.tas).to eq []
          end
        end
      end

      context 'with flexible marking scheme doing a' do
        before do
          @assignment = create(:assignment)
        end

        context 'POST on :global_actions on random_assign' do
          before do
            @criterion1 = create(:flexible_criterion, assignment: @assignment)
            @criterion2 = create(:flexible_criterion, assignment: @assignment)
            @criterion3 = create(:flexible_criterion, assignment: @assignment)
            @ta1 = create(:ta)
            @ta2 = create(:ta)
            @ta3 = create(:ta)
          end

          it 'and no graders selected' do
            post_as @instructor,
                    :global_actions,
                    params: { course_id: course.id, assignment_id: @assignment.id, global_actions: 'random_assign',
                              current_table: 'criteria_table' }
            expect(response).to have_http_status(:bad_request)
            @assignment.criteria.each do |criterion|
              expect(criterion.tas).to eq []
            end
          end

          it 'and no criteria selected, at least one grader' do
            post_as @instructor,
                    :global_actions,
                    params: { course_id: course.id, assignment_id: @assignment.id,
                              global_actions: 'random_assign', graders: [@ta1.id], current_table: 'criteria_table' }
            expect(response).to have_http_status(:bad_request)
            @assignment.criteria.each do |criterion|
              expect(criterion.tas).to eq []
            end
          end

          it 'and no graders are selected, at least one criterion' do
            post_as @instructor,
                    :global_actions,
                    params: { course_id: course.id, assignment_id: @assignment.id, global_actions: 'random_assign',
                              criteria: [@criterion1.position],
                              current_table: 'criteria_table' }
            expect(response).to have_http_status(:bad_request)
            @assignment.criteria.each do |criterion|
              expect(criterion.tas).to eq []
            end
          end

          it 'and one grader and one criterion is selected' do
            post_as @instructor,
                    :global_actions,
                    params: { course_id: course.id, assignment_id: @assignment.id, global_actions: 'random_assign',
                              criteria: [@criterion1.position], graders: [@ta1.id],
                              current_table: 'criteria_table' }
            expect(response).to have_http_status(:ok)
            @criterion1.reload
            @criterion2.reload
            @criterion3.reload
            expect(@criterion1.tas[0].id).to eq @ta1.id
            expect(@criterion2.tas).to eq []
            expect(@criterion3.tas).to eq []
          end

          it 'and one grader and multiple criteria are selected' do
            post_as @instructor,
                    :global_actions,
                    params: { course_id: course.id, assignment_id: @assignment.id, global_actions: 'random_assign',
                              criteria: [@criterion1.position, @criterion2.position],
                              graders: [@ta1.id],
                              current_table: 'criteria_table' }
            expect(response).to have_http_status(:ok)
            @criterion1.reload
            @criterion2.reload
            @criterion3.reload
            expect(@criterion1.tas[0].id).to eq @ta1.id
            expect(@criterion2.tas[0].id).to eq @ta1.id
            expect(@criterion3.tas).to eq []
          end

          it 'and two graders and one criterion is selected' do
            post_as @instructor,
                    :global_actions,
                    params: { course_id: course.id, assignment_id: @assignment.id, global_actions: 'random_assign',
                              criteria: [@criterion1.position],
                              graders: [@ta1.id, @ta2.id],
                              current_table: 'criteria_table' }
            expect(response).to have_http_status(:ok)
            @criterion1.reload
            @criterion2.reload
            @criterion3.reload
            expect(@criterion1.tas[0].id).to eq(@ta1.id).or(eq(@ta2.id))
            expect(@criterion2.tas).to eq []
            expect(@criterion3.tas).to eq []
          end

          it 'and two graders and two criteria are selected' do
            post_as @instructor,
                    :global_actions,
                    params: { course_id: course.id, assignment_id: @assignment.id, global_actions: 'random_assign',
                              criteria: [@criterion1.position, @criterion2.position],
                              graders: [@ta1.id, @ta2.id],
                              current_table: 'criteria_table' }
            expect(response).to have_http_status(:ok)
            @criterion1.reload
            @criterion2.reload
            @criterion3.reload
            expect(@criterion1.tas[0].id).to eq(@ta1.id).or(eq(@ta2.id))
            expect(@criterion2.tas[0].id).to eq(@ta1.id).or(eq(@ta2.id))
            expect(@criterion1.tas[0].id).not_to eq(@criterion2.tas[0].id)
            expect(@criterion3.tas).to eq []
          end

          it 'and multiple graders and multiple criteria are selected' do
            @ta3 = create(:ta)
            post_as @instructor,
                    :global_actions,
                    params: { course_id: course.id, assignment_id: @assignment.id, global_actions: 'random_assign',
                              criteria: [@criterion1.position, @criterion2.position, @criterion3.position],
                              graders: [@ta1.id, @ta2.id, @ta3.id],
                              current_table: 'criteria_table' }
            expect(response).to have_http_status(:ok)
            @criterion1.reload
            @criterion2.reload
            @criterion3.reload
            expect(@criterion1.tas.size).to eq 1
            expect(@criterion2.tas.size).to eq 1
            expect(@criterion3.tas.size).to eq 1
          end
        end

        context 'POST on :global_actions on assign' do
          before do
            @criterion1 = create(:flexible_criterion, assignment: @assignment, position: 1)
            @criterion2 = create(:flexible_criterion, assignment: @assignment, position: 2)
            @criterion3 = create(:flexible_criterion, assignment: @assignment, position: 3)
            @ta1 = create(:ta)
            @ta2 = create(:ta)
            @ta3 = create(:ta)
          end

          it 'and no graders selected' do
            post_as @instructor,
                    :global_actions,
                    params: { course_id: course.id, assignment_id: @assignment.id,
                              global_actions: 'assign', current_table: 'criteria_table' }
            expect(response).to have_http_status(:bad_request)
            @assignment.reload
            @assignment.criteria.each do |criterion|
              expect(criterion.tas).to eq []
            end
          end

          it 'and no criteria selected, at least one grader' do
            post_as @instructor,
                    :global_actions,
                    params: { course_id: course.id, assignment_id: @assignment.id, global_actions: 'assign',
                              graders: [@ta1.id], current_table: 'criteria_table' }
            expect(response).to have_http_status(:bad_request)
            @assignment.reload
            @assignment.criteria.each do |criterion|
              expect(criterion.tas).to eq []
            end
          end

          it 'and no graders are selected, at least one criterion' do
            post_as @instructor,
                    :global_actions,
                    params: { course_id: course.id, assignment_id: @assignment.id, global_actions: 'assign',
                              criteria: [@criterion1], current_table: 'criteria_table' }
            expect(response).to have_http_status(:bad_request)
            @assignment.criteria.each do |criterion|
              expect(criterion.tas).to eq []
            end
          end

          it 'and one grader and one criterion is selected' do
            post_as @instructor,
                    :global_actions,
                    params: { course_id: course.id, assignment_id: @assignment.id, global_actions: 'assign',
                              criteria: [@criterion1.position],
                              graders: [@ta1.id],
                              current_table: 'criteria_table' }
            expect(response).to have_http_status(:ok)
            @criterion1.reload
            @criterion2.reload
            @criterion3.reload
            expect(@criterion1.tas[0].id).to eq @ta1.id
            expect(@criterion2.tas).to eq []
            expect(@criterion3.tas).to eq []
          end

          it 'and one grader and two criteria are selected' do
            post_as @instructor,
                    :global_actions,
                    params: { course_id: course.id, assignment_id: @assignment.id, global_actions: 'assign',
                              criteria: [@criterion1.position, @criterion2.position],
                              graders: [@ta1.id],
                              current_table: 'criteria_table' }
            expect(response).to have_http_status(:ok)
            @criterion1.reload
            @criterion2.reload
            @criterion3.reload
            expect(@criterion1.tas[0].id).to eq @ta1.id
            expect(@criterion2.tas[0].id).to eq @ta1.id
            expect(@criterion3.tas).to eq []
          end

          it 'and two graders and one criterion is selected' do
            post_as @instructor,
                    :global_actions,
                    params: { course_id: course.id, assignment_id: @assignment.id, global_actions: 'assign',
                              criteria: [@criterion1.position],
                              graders: [@ta1.id, @ta2.id],
                              current_table: 'criteria_table' }
            expect(response).to have_http_status(:ok)
            @criterion1.reload
            @criterion2.reload
            @criterion3.reload
            expect(@criterion1.tas.length).to eq 2
            expect(@criterion1.tas).to include(@ta1)
            expect(@criterion1.tas).to include(@ta2)
            expect(@criterion2.tas).to eq []
            expect(@criterion3.tas).to eq []
          end

          it 'and two graders and two criteria are selected' do
            post_as @instructor,
                    :global_actions,
                    params: { course_id: course.id, assignment_id: @assignment.id, global_actions: 'assign',
                              criteria: [@criterion1.position, @criterion2.position],
                              graders: [@ta1.id, @ta2.id],
                              current_table: 'criteria_table' }
            expect(response).to have_http_status(:ok)
            @criterion1.reload
            @criterion2.reload
            @criterion3.reload
            expect(@criterion1.tas.length).to eq 2
            expect(@criterion1.tas).to include(@ta1)
            expect(@criterion1.tas).to include(@ta2)
            expect(@criterion2.tas.length).to eq 2
            expect(@criterion2.tas).to include(@ta1)
            expect(@criterion2.tas).to include(@ta2)
            expect(@criterion3.tas).to eq []
          end

          it 'and multiple graders and multiple criteria are selected' do
            @ta3 = create(:ta)
            post_as @instructor,
                    :global_actions,
                    params: { course_id: course.id, assignment_id: @assignment.id, global_actions: 'assign',
                              criteria: [@criterion1.position, @criterion2.position, @criterion3.position],
                              graders: [@ta1.id, @ta2.id, @ta3.id], current_table: 'criteria_table' }
            expect(response).to have_http_status(:ok)
            @criterion1.reload
            @criterion2.reload
            @criterion3.reload
            expect(@criterion1.tas.length).to eq 3
            expect(@criterion1.tas).to include(@ta1)
            expect(@criterion1.tas).to include(@ta2)
            expect(@criterion1.tas).to include(@ta3)
            expect(@criterion2.tas.length).to eq 3
            expect(@criterion2.tas).to include(@ta1)
            expect(@criterion2.tas).to include(@ta2)
            expect(@criterion2.tas).to include(@ta3)
          end

          it 'and some graders are already assigned to some criteria' do
            CriterionTaAssociation.create(ta: @ta1, criterion: @criterion2)
            CriterionTaAssociation.create(ta: @ta2, criterion: @criterion1)
            post_as @instructor,
                    :global_actions,
                    params: { course_id: course.id, assignment_id: @assignment.id, global_actions: 'assign',
                              criteria: [@criterion1.position, @criterion2.position],
                              graders: [@ta1.id, @ta2.id], current_table: 'criteria_table' }
            expect(response).to have_http_status(:ok)
            @criterion1.reload
            @criterion2.reload
            @criterion3.reload
            expect(@criterion1.tas.length).to eq 2
            expect(@criterion1.tas).to include(@ta1)
            expect(@criterion1.tas).to include(@ta2)
            expect(@criterion2.tas.length).to eq 2
            expect(@criterion2.tas).to include(@ta1)
            expect(@criterion2.tas).to include(@ta2)
            expect(@criterion3.tas).to eq []
          end
        end

        context 'POST on :global_actions on unassign' do
          before do
            @criterion1 = create(:flexible_criterion, assignment: @assignment)
            @criterion2 = create(:flexible_criterion, assignment: @assignment)
            @criterion3 = create(:flexible_criterion, assignment: @assignment)
            @ta1 = create(:ta)
            @ta2 = create(:ta)
            @ta3 = create(:ta)
          end

          it 'and no graders or criteria are selected' do
            CriterionTaAssociation.create(ta: @ta1, criterion: @criterion1)
            CriterionTaAssociation.create(ta: @ta2, criterion: @criterion2)
            post_as @instructor,
                    :global_actions,
                    params: { course_id: course.id, assignment_id: @assignment.id, global_actions: 'unassign',
                              current_table: 'criteria_table' }
            expect(response).to have_http_status(:bad_request)
            @criterion1.reload
            @criterion2.reload
            @criterion3.reload
            expect(@criterion1.tas).to eq [@ta1]
            expect(@criterion2.tas).to eq [@ta2]
            expect(@criterion3.tas).to eq []
          end

          it 'and all graders from one criterion are selected' do
            CriterionTaAssociation.create(ta: @ta1, criterion: @criterion1)
            CriterionTaAssociation.create(ta: @ta2, criterion: @criterion1)
            CriterionTaAssociation.create(ta: @ta3, criterion: @criterion1)
            CriterionTaAssociation.create(ta: @ta3, criterion: @criterion3)
            post_as @instructor,
                    :global_actions,
                    params: { course_id: course.id, assignment_id: @assignment.id, global_actions: 'unassign',
                              criteria: [@criterion1.position],
                              graders: [@ta1.id, @ta2.id, @ta3.id],
                              current_table: 'criteria_table' }
            expect(response).to have_http_status(:ok)
            @criterion1.reload
            expect(@criterion1.tas).to eq []
            @criterion2.reload
            @criterion3.reload
            expect(@criterion2.tas).to eq []
            expect(@criterion3.tas).to eq [@ta3]
          end

          it 'and all criteria from one grader are selected' do
            CriterionTaAssociation.create(ta: @ta1, criterion: @criterion1)
            CriterionTaAssociation.create(ta: @ta2, criterion: @criterion1)
            CriterionTaAssociation.create(ta: @ta3, criterion: @criterion1)
            CriterionTaAssociation.create(ta: @ta3, criterion: @criterion2)
            CriterionTaAssociation.create(ta: @ta3, criterion: @criterion3)
            post_as @instructor,
                    :global_actions,
                    params: { course_id: course.id, assignment_id: @assignment.id, global_actions: 'unassign',
                              criteria: [@criterion1.position, @criterion2.position, @criterion3.position],
                              graders: [@ta3.id],
                              current_table: 'criteria_table' }
            expect(response).to have_http_status(:ok)
            @criterion1.reload
            @criterion2.reload
            @criterion3.reload
            expect(@criterion1.tas).not_to include(@ta3)
            expect(@criterion2.tas).not_to include(@ta3)
            expect(@criterion3.tas).not_to include(@ta3)
            @criterion1.reload
            expect(@criterion1.tas).to include(@ta1)
            expect(@criterion1.tas).to include(@ta2)
          end

          it 'and one grader and one criterion is selected where the grader and criterion have other memberships' do
            CriterionTaAssociation.create(ta: @ta1, criterion: @criterion1)
            CriterionTaAssociation.create(ta: @ta2, criterion: @criterion1)
            CriterionTaAssociation.create(ta: @ta3, criterion: @criterion1)
            CriterionTaAssociation.create(ta: @ta1, criterion: @criterion2)
            CriterionTaAssociation.create(ta: @ta2, criterion: @criterion2)
            CriterionTaAssociation.create(ta: @ta3, criterion: @criterion2)
            CriterionTaAssociation.create(ta: @ta1, criterion: @criterion3)
            CriterionTaAssociation.create(ta: @ta2, criterion: @criterion3)
            CriterionTaAssociation.create(ta: @ta3, criterion: @criterion3)
            post_as @instructor,
                    :global_actions,
                    params: { course_id: course.id, assignment_id: @assignment.id, global_actions: 'unassign',
                              criteria: [@criterion2.position],
                              graders: [@ta1.id],
                              current_table: 'criteria_table' }
            expect(response).to have_http_status(:ok)
            expect(@criterion2.tas).not_to include(@ta1)
            @criterion1.reload
            @criterion2.reload
            @criterion3.reload
            expect(@criterion1.tas).to include(@ta1)
            expect(@criterion1.tas).to include(@ta2)
            expect(@criterion1.tas).to include(@ta3)
            expect(@criterion2.tas).to include(@ta2)
            expect(@criterion2.tas).to include(@ta3)
            expect(@criterion3.tas).to include(@ta1)
            expect(@criterion3.tas).to include(@ta2)
            expect(@criterion3.tas).to include(@ta3)
          end

          it 'and multiple graders and multiple criteria are selected' do
            CriterionTaAssociation.create(ta: @ta1, criterion: @criterion1)
            CriterionTaAssociation.create(ta: @ta2, criterion: @criterion1)
            CriterionTaAssociation.create(ta: @ta3, criterion: @criterion1)
            CriterionTaAssociation.create(ta: @ta1, criterion: @criterion2)
            CriterionTaAssociation.create(ta: @ta2, criterion: @criterion2)
            CriterionTaAssociation.create(ta: @ta3, criterion: @criterion2)
            CriterionTaAssociation.create(ta: @ta1, criterion: @criterion3)
            CriterionTaAssociation.create(ta: @ta2, criterion: @criterion3)
            CriterionTaAssociation.create(ta: @ta3, criterion: @criterion3)
            post_as @instructor,
                    :global_actions,
                    params: { course_id: course.id, assignment_id: @assignment.id, global_actions: 'unassign',
                              criteria: [@criterion1.position, @criterion2.position, @criterion3.position],
                              graders: [@ta1.id, @ta2.id, @ta3.id],
                              current_table: 'criteria_table' }
            expect(response).to have_http_status(:ok)
            expect(@criterion1.tas).to eq []
            expect(@criterion2.tas).to eq []
            expect(@criterion3.tas).to eq []
          end
        end
      end
    end
  end
end
