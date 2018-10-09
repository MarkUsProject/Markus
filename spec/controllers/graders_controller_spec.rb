describe GradersController do
  context 'An authenticated and authorized student doing a ' do

    before(:each) do
      @student = create(:student)
    end

    it 'GET on :set_assign_criteria' do
      get_as @student, :set_assign_criteria, params: { assignment_id: 1 }
      expect(response.status).to eq(404)
    end

    it 'GET on :index' do
      get_as @student, :index, params: { assignment_id: 1 }
      expect(response.status).to eq(404)
    end

    it 'GET on :csv_upload_grader_groups_mapping' do
      get_as @student, :csv_upload_grader_groups_mapping, params: { assignment_id: 1 }
      expect(response.status).to eq(404)
    end

    it 'GET on :global_actions' do
      get_as @student, :global_actions, params: { assignment_id: 1 }
      expect(response.status).to eq(404)
    end

    it 'POST on :set_assign_criteria' do
      post_as @student, :set_assign_criteria, params: { assignment_id: 1 }
      expect(response.status).to eq(404)
    end

    it 'POST on :csv_upload_grader_groups_mapping' do
      post_as @student, :csv_upload_grader_groups_mapping, params: { assignment_id: 1 }
      expect(response.status).to eq(404)
    end

    it 'POST on :global_actions' do
      post_as @student, :global_actions, params: { assignment_id: 1 }
      expect(response.status).to eq(404)
    end
  end # student context

  context 'An authenticated and authorized admin' do

    before :each do
      @admin = create(:admin)
      @assignment = create(:assignment)
    end

    it 'doing a GET on :index(graders_controller)' do
      get_as @admin, :index, params: { assignment_id: @assignment.id }
      expect(response.status).to eq(200)
      expect(assigns :assignment).not_to be_nil
    end #manage

    context 'doing a POST on :set_assign_criteria' do

      it 'and value is true' do
        post_as @admin, :set_assign_criteria, params: { assignment_id: @assignment.id, value: 'true' }
        expect(response.status).to eq(200)
        @assignment.reload
        expect(@assignment.assign_graders_to_criteria).to be_truthy
      end

      it 'and value is nil' do
        post_as @admin, :set_assign_criteria, params: { assignment_id: @assignment.id }
        expect(response.status).to eq(200)
        @assignment.reload
        expect(@assignment.assign_graders_to_criteria).to be_falsey
      end
    end

    context 'doing a POST on :csv_upload_grader_groups_mapping' do

      before :each do
        # Contents: test_group,g9browni,g9younas
        #           second_test_group,g9browni
        #           Group 3,c7benjam
        @group_grader_map_file = fixture_file_upload(
          File.join('group_csvs',
                    'group_grader_map.csv')
        )
      end

      it 'and all graders and groups are valid' do
        @ta1 = create(:ta, user_name: 'g9browni')
        @ta2 = create(:ta, user_name: 'g9younas')
        @ta3 = create(:ta, user_name: 'c7benjam')
        @grouping1 = create(:grouping, assignment: @assignment, group: create(:group, group_name: 'test_group'))
        @grouping2 = create(:grouping, assignment: @assignment, group: create(:group, group_name: 'second_test_group'))
        @grouping3 = create(:grouping, assignment: @assignment, group: create(:group, group_name: 'Group 3'))
        post_as @admin,
                :csv_upload_grader_groups_mapping,
                params: { assignment_id: @assignment.id, grader_mapping: @group_grader_map_file }

        expect(response).to be_redirect
        expect(@grouping1.tas.count).to eq 2
        expect(@grouping1.tas).to include(@ta1)
        expect(@grouping1.tas).to include(@ta2)
        expect(@grouping2.tas.count).to eq 1
        expect(@grouping2.tas).to include(@ta1)
        expect(@grouping3.tas.count).to eq 1
        expect(@grouping3.tas).to include(@ta3)
        expect(:post => 'assignments/1/graders/csv_upload_grader_groups_mapping')
          .to route_to(
            :controller => 'graders',
            :action     => 'csv_upload_grader_groups_mapping',
            :assignment_id => '1'
          )
      end

      it 'and a successful call updates repository permissions exactly once' do
        expect(Repository.get_class).to receive(:__update_permissions)
        post_as @admin,
                :csv_upload_grader_groups_mapping,
                params: { assignment_id: @assignment.id, grader_mapping: @group_grader_map_file }
      end

      it 'and some graders are invalid' do
        @ta1 = create(:ta, user_name: 'g9browni')
        @ta2 = create(:ta, user_name: 'g9younas')
        @ta3 = create(:ta, user_name: 'c0curtis')
        @grouping1 = create(:grouping, assignment: @assignment, group: create(:group, group_name: 'test_group'))
        @grouping2 = create(:grouping, assignment: @assignment, group: create(:group, group_name: 'second_test_group'))
        @grouping3 = create(:grouping, assignment: @assignment, group: create(:group, group_name: 'Group 3'))
        post_as @admin,
                :csv_upload_grader_groups_mapping,
                params: { assignment_id: @assignment.id, grader_mapping: @group_grader_map_file }

        expect(response).to be_redirect
        assert @grouping1.tas.count == 2
        assert @grouping1.tas.include? @ta1
        assert @grouping1.tas.include? @ta2
        assert @grouping2.tas.count == 1
        assert @grouping2.tas.include? @ta1
        assert @grouping3.tas.count == 0
      end

      it 'and some groupings are invalid' do
        @ta1 = create(:ta, user_name: 'g9browni')
        @ta2 = create(:ta, user_name: 'g9younas')
        @ta3 = create(:ta, user_name: 'c7benjam')
        @grouping1 = create(:grouping, assignment: @assignment, group: create(:group, group_name: 'Group of 7'))
        @grouping2 = create(:grouping, assignment: @assignment, group: create(:group, group_name: 'second_test_group'))
        @grouping3 = create(:grouping, assignment: @assignment, group: create(:group, group_name: 'Group 3'))
        post_as @admin,
                :csv_upload_grader_groups_mapping,
                params: { assignment_id: @assignment.id, grader_mapping: @group_grader_map_file }

        expect(response).to be_redirect
        expect(@grouping1.tas.count).to eq 0
        expect(@grouping2.tas.count).to eq 1
        expect(@grouping2.tas).to include(@ta1)
        expect(@grouping3.tas.count).to eq 1
        expect(@grouping3.tas).to include(@ta3)
      end

      it 'gracefully handle malformed csv files' do
        tempfile = fixture_file_upload('files/malformed.csv')
        post_as @admin,
                :csv_upload_grader_groups_mapping,
                params: { assignment_id: @assignment.id, grader_mapping: tempfile }

        expect(response).to be_redirect
        i18t_string = [I18n.t('upload_errors.malformed_csv')].map { |f| extract_text f }
        expect(flash[:error].map { |f| extract_text f }).to eq(i18t_string)
      end

      it 'gracefully handle a non csv file with a csv extension' do
        tempfile = fixture_file_upload('files/pdf_with_csv_extension.csv')
        post_as @admin,
                :csv_upload_grader_groups_mapping,
                params: { assignment_id: @assignment.id, grader_mapping: tempfile, encoding: 'UTF-8' }

        expect(response).to be_redirect
        i18t_string = [I18n.t('csv.upload.non_text_file_with_csv_extension')].map { |f| extract_text f }
        expect(flash[:error].map { |f| extract_text f }).to eq(i18t_string)
      end
    end #groups csv upload

    context 'doing a POST on :csv_upload_grader_criteria_mapping' do

      before :each do
        # Contents: correctness,g9browni,g9younas
        #           style,g9browni
        #           class design,c7benjam
        @criteria_grader_map_file = fixture_file_upload(
          File.join('group_csvs',
                    'criteria_grader_map.csv'))
      end

      context 'with rubric criteria' do
        before :each do
          @assignment = create(:assignment, assign_graders_to_criteria: true)
        end

        it 'and all graders and criteria are valid' do
          @ta1 = create(:ta, user_name: 'g9browni')
          @ta2 = create(:ta, user_name: 'g9younas')
          @ta3 = create(:ta, user_name: 'c7benjam')
          @criterion1 = create(:rubric_criterion, assignment: @assignment, name: 'correctness')
          @criterion2 = create(:rubric_criterion, assignment: @assignment, name: 'style')
          @criterion3 = create(:rubric_criterion, assignment: @assignment, name: 'class design')
          post_as @admin,
                  :csv_upload_grader_criteria_mapping,
                  params: { assignment_id: @assignment.id, grader_criteria_mapping: @criteria_grader_map_file }

          expect(response).to be_redirect
          expect(@criterion1.tas.count).to eq 2
          expect(@criterion1.tas).to include(@ta1)
          expect(@criterion1.tas).to include(@ta2)
          expect(@criterion2.tas.count).to eq 1
          expect(@criterion2.tas).to include(@ta1)
          expect(@criterion3.tas.count).to eq 1
          expect(@criterion3.tas).to include(@ta3)
          expect(:post => 'assignments/1/graders/csv_upload_grader_criteria_mapping')
            .to route_to(
                  :controller => 'graders',
                  :action     => 'csv_upload_grader_criteria_mapping',
                  :assignment_id => '1'
                )
        end

        it 'and some graders are invalid' do
          @ta1 = create(:ta, user_name: 'g9browni')
          @ta2 = create(:ta, user_name: 'reid')
          @ta3 = create(:ta, user_name: 'c7benjam')
          @criterion1 = create(:rubric_criterion, assignment: @assignment, name: 'correctness')
          @criterion2 = create(:rubric_criterion, assignment: @assignment, name: 'style')
          @criterion3 = create(:rubric_criterion, assignment: @assignment, name: 'class design')
          post_as @admin,
                  :csv_upload_grader_criteria_mapping,
                  params: { assignment_id: @assignment.id, grader_criteria_mapping: @criteria_grader_map_file }

          expect(response).to be_redirect
          expect(@criterion1.tas.count).to eq 0 # entire row is ignored
          expect(@criterion2.tas.count).to eq 1
          expect(@criterion2.tas).to include(@ta1)
          expect(@criterion3.tas.count).to eq 1
          expect(@criterion3.tas).to include(@ta3)
        end

        it 'and some criteria are invalid' do
          @ta1 = create(:ta, user_name: 'g9browni')
          @ta2 = create(:ta, user_name: 'g9younas')
          @ta3 = create(:ta, user_name: 'c7benjam')
          @criterion1 = create(:rubric_criterion, assignment: @assignment, name: 'correctness')
          @criterion2 = create(:rubric_criterion, assignment: @assignment, name: "professor's whim")
          @criterion3 = create(:rubric_criterion, assignment: @assignment, name: 'class design')
          post_as @admin,
                  :csv_upload_grader_criteria_mapping,
                  params: { assignment_id: @assignment.id, grader_criteria_mapping: @criteria_grader_map_file }

          expect(response).to be_redirect
          expect(@criterion1.tas.count).to eq 2
          expect(@criterion1.tas).to include(@ta1)
          expect(@criterion2.tas.count).to eq 0
          expect(@criterion3.tas.count).to eq 1
          expect(@criterion3.tas).to include(@ta3)
        end
      end # rubric criteria

      context 'with flexible criteria' do
        before :each do
          @assignemnt = create(:assignment, assign_graders_to_criteria: true)
        end

        it 'and all graders and criteria are valid' do
          @ta1 = create(:ta, user_name: 'g9browni')
          @ta2 = create(:ta, user_name: 'g9younas')
          @ta3 = create(:ta, user_name: 'c7benjam')
          @criterion1 = create(:flexible_criterion, assignment: @assignment, name: 'correctness')
          @criterion2 = create(:flexible_criterion, assignment: @assignment, name: 'style')
          @criterion3 = create(:flexible_criterion, assignment: @assignment, name: 'class design')
          post_as @admin,
                  :csv_upload_grader_criteria_mapping,
                  params: { assignment_id: @assignment.id, grader_criteria_mapping: @criteria_grader_map_file }

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
          @ta1 = create(:ta, user_name: 'g9browni')
          @ta2 = create(:ta, user_name: 'reid')
          @ta3 = create(:ta, user_name: 'c7benjam')
          @criterion1 = create(:flexible_criterion, assignment: @assignment, name: 'correctness')
          @criterion2 = create(:flexible_criterion, assignment: @assignment, name: 'style')
          @criterion3 = create(:flexible_criterion, assignment: @assignment, name: 'class design')
          post_as @admin,
                  :csv_upload_grader_criteria_mapping,
                  params: { assignment_id: @assignment.id, grader_criteria_mapping: @criteria_grader_map_file }

          expect(response).to be_redirect
          expect(@criterion1.tas.count).to eq 0 # entire row is ignored
          expect(@criterion2.tas.count).to eq 1
          expect(@criterion2.tas).to include(@ta1)
          expect(@criterion3.tas.count).to eq 1
          expect(@criterion3.tas).to include(@ta3)
        end

        it 'and some criteria are invalid' do
          @ta1 = create(:ta, user_name: 'g9browni')
          @ta2 = create(:ta, user_name: 'g9younas')
          @ta3 = create(:ta, user_name: 'c7benjam')
          @criterion1 = create(:flexible_criterion, assignment: @assignment, name: 'correctness')
          @criterion2 = create(:flexible_criterion, assignment: @assignment, name: "professor's whim")
          @criterion3 = create(:flexible_criterion, assignment: @assignment, name: 'class design')
          post_as @admin,
                  :csv_upload_grader_criteria_mapping,
                  params: { assignment_id: @assignment.id, grader_criteria_mapping: @criteria_grader_map_file }

          expect(response).to be_redirect
          expect(@criterion1.tas.count).to eq 2
          expect(@criterion1.tas).to include(@ta1)
          expect(@criterion2.tas.count).to eq 0
          expect(@criterion3.tas.count).to eq 1
          expect(@criterion3.tas).to include(@ta3)
        end
      end # flexible criteria

      it 'gracefully handle malformed csv files' do
        tempfile = fixture_file_upload('files/malformed.csv')
        post_as @admin,
                :csv_upload_grader_criteria_mapping,
                params: { assignment_id: @assignment.id, grader_criteria_mapping: tempfile, encoding: 'UTF-8' }

        expect(response).to be_redirect
        i18t_string = [I18n.t('upload_errors.malformed_csv')].map { |f| extract_text f }
        expect(flash[:error].map { |f| extract_text f }).to eq(i18t_string)
      end

      it 'gracefully handle a non csv file with a csv extension' do
        tempfile = fixture_file_upload('files/pdf_with_csv_extension.csv')
        post_as @admin,
                :csv_upload_grader_criteria_mapping,
                params: { assignment_id: @assignment.id, grader_criteria_mapping: tempfile, encoding: 'UTF-8' }

        expect(response).to be_redirect
        i18t_string = [I18n.t('csv.upload.non_text_file_with_csv_extension')].map { |f| extract_text f }
        expect(flash[:error].map { |f| extract_text f }).to eq(i18t_string)
      end
    end # criteria csv upload

    context 'doing a GET on :download_grader_groupings_mapping' do
      before :each do
        @assignment = create(:assignment, assign_graders_to_criteria: true)
      end

      it 'routing properly' do
        post_as @admin, :download_grader_groupings_mapping, params: { assignment_id: @assignment.id }
        expect(response.status).to eq(200)
        expect(:get => 'assignments/1/graders/download_grader_groupings_mapping')
          .to route_to(
                :controller => 'graders',
                :action     => 'download_grader_groupings_mapping',
                :assignment_id => '1'
              )
      end
    end

    context 'doing a GET on :download_grader_criteria_mapping' do
      before :each do
        @assignment = create(:assignment, assign_graders_to_criteria: true)
      end

      it 'routing properly' do
        post_as @admin, :download_grader_criteria_mapping, params: { assignment_id: @assignment.id }
        expect(response.status).to eq(200)
        expect(:get => 'assignments/1/graders/download_grader_criteria_mapping')
          .to route_to(
                :controller => 'graders',
                :action     => 'download_grader_criteria_mapping',
                :assignment_id => '1'
              )
      end
    end

    context 'with groups table selected doing a' do

      context 'POST on :global_actions on random_assign' do
        before :each do
          @grouping1 = create(:grouping, assignment: @assignment)
          @grouping2 = create(:grouping, assignment: @assignment)
          @grouping3 = create(:grouping, assignment: @assignment)
          @ta1 = create(:ta)
          @ta2 = create(:ta)
          @ta3 = create(:ta)
        end

        it 'and no graders selected' do
          post_as @admin,
                  :global_actions,
                  params: { assignment_id: @assignment.id, global_actions: 'random_assign',
                            current_table: 'groups_table' }
          expect(response.status).to eq(400)
          @assignment.groupings do |grouping|
            expect(grouping.tas).to eq []
          end
        end

        it 'and no groups selected, at least one grader' do
          post_as @admin,
                  :global_actions,
                  params: { assignment_id: @assignment.id, global_actions: 'random_assign', graders: [@ta1],
                            current_table: 'groups_table' }
          expect(response.status).to eq(400)
          @assignment.groupings do |grouping|
            expect(grouping.tas).to eq []
          end
        end

        it 'and no graders are selected, at least one grouping' do
          post_as @admin,
                  :global_actions,
                  params: { assignment_id: @assignment.id, global_actions: 'random_assign', groupings: [@grouping1],
                            current_table: 'groups_table' }
          expect(response.status).to eq(400)
          @assignment.groupings do |grouping|
            expect(grouping.tas).to eq []
          end
        end

        it 'and one grader and one grouping is selected' do
          post_as @admin,
                  :global_actions,
                  params: { assignment_id: @assignment.id, global_actions: 'random_assign', groupings: [@grouping1],
                            graders: [@ta1], current_table: 'groups_table' }
          expect(response.status).to eq(200)
          expect(@grouping1.tas[0].id).to eq @ta1.id
          expect(@grouping2.tas).to eq []
          expect(@grouping3.tas).to eq []
        end

        it 'and one grader and multiple groupings are selected' do
          post_as @admin,
                  :global_actions,
                  params: { assignment_id: @assignment.id, global_actions: 'random_assign',
                            groupings: [@grouping1, @grouping2], graders: [@ta1], current_table: 'groups_table' }
          expect(response.status).to eq(200)
          expect(@grouping1.tas[0].id).to eq @ta1.id
          expect(@grouping2.tas[0].id).to eq @ta1.id
          expect(@grouping3.tas).to eq []
        end

        it 'and two graders and one grouping is selected' do
          post_as @admin,
                  :global_actions,
                  params: { assignment_id: @assignment.id, global_actions: 'random_assign', groupings: [@grouping1],
                            graders: [@ta1, @ta2], current_table: 'groups_table' }
          expect(response.status).to eq(200)
          expect(@grouping1.tas[0].id).to eq(@ta1.id).or eq(@ta2.id)
          expect(@grouping2.tas).to eq []
          expect(@grouping3.tas).to eq []
        end

        it 'and two graders and two groupings are selected' do
          post_as @admin,
                  :global_actions,
                  params: { assignment_id: @assignment.id, global_actions: 'random_assign',
                            groupings: [@grouping1, @grouping2], graders: [@ta1, @ta2], current_table: 'groups_table' }
          expect(response.status).to eq(200)
          expect(@grouping1.tas[0].id).to eq(@ta1.id).or eq(@ta2.id)
          expect(@grouping2.tas[0].id).to eq(@ta1.id).or eq(@ta2.id)
          expect(@grouping1.tas[0].id).not_to eq @grouping2.tas[0].id
          expect(@grouping3.tas).to eq []
        end

        it 'and multiple graders and multiple groupings are selected' do
          @ta3 = create(:ta)
          post_as @admin,
                  :global_actions,
                  params: { assignment_id: @assignment.id, global_actions: 'random_assign',
                            groupings: [@grouping1, @grouping2, @grouping3], graders: [@ta1, @ta2, @ta3],
                            current_table: 'groups_table' }
          expect(response.status).to eq(200)
          expect(@grouping1.tas.size).to eq 1
          expect(@grouping2.tas.size).to eq 1
          expect(@grouping3.tas.size).to eq 1
        end
      end #random assign

      context 'POST on :global_actions on assign' do
        before :each do
          @grouping1 = create(:grouping, assignment: @assignment)
          @grouping2 = create(:grouping, assignment: @assignment)
          @grouping3 = create(:grouping, assignment: @assignment)
          @ta1 = create(:ta)
          @ta2 = create(:ta)
          @ta3 = create(:ta)
        end

        it 'and no graders selected' do
          post_as @admin,
                  :global_actions,
                  params: { assignment_id: @assignment.id, global_actions: 'assign', current_table: 'groups_table' }
          expect(response.status).to eq(400)
          @assignment.groupings do |grouping|
            expect(grouping.tas).to eq []
          end
        end

        it 'and no groupings selected, at least one grader' do
          post_as @admin,
                  :global_actions,
                  params: { assignment_id: @assignment.id, global_actions: 'assign', graders: [@ta1],
                            current_table: 'groups_table' }
          expect(response.status).to eq(400)
          @assignment.groupings do |grouping|
            expect(grouping.tas).to eq []
          end
        end

        it 'and no graders are selected, at least one grouping' do
          post_as @admin,
                  :global_actions,
                  params: { assignment_id: @assignment.id, global_actions: 'assign', groupings: [@grouping1],
                            current_table: 'groups_table' }
          expect(response.status).to eq(400)
          @assignment.groupings do |grouping|
            expect(grouping.tas).to eq []
          end
        end

        it 'and one grader and one grouping is selected' do
          post_as @admin,
                  :global_actions,
                  params: { assignment_id: @assignment.id, global_actions: 'assign', groupings: [@grouping1],
                            graders: [@ta1], current_table: 'groups_table' }
          expect(response.status).to eq(200)
          expect(@grouping1.tas[0].id).to eq @ta1.id
          expect(@grouping2.tas).to eq []
          expect(@grouping3.tas).to eq []
        end

        it 'and one grader and two groupings are selected' do
          post_as @admin,
                  :global_actions,
                  params: { assignment_id: @assignment.id, global_actions: 'assign',
                            groupings: [@grouping1, @grouping2], graders: [@ta1], current_table: 'groups_table' }
          expect(response.status).to eq(200)
          expect(@grouping1.tas[0].id).to eq @ta1.id
          expect(@grouping2.tas[0].id).to eq @ta1.id
          expect(@grouping3.tas).to eq []
        end

        it 'and two graders and one grouping is selected' do
          post_as @admin,
                  :global_actions,
                  params: { assignment_id: @assignment.id, global_actions: 'assign', groupings: [@grouping1],
                            graders: [@ta1, @ta2], current_table: 'groups_table' }
          expect(response.status).to eq(200)
          expect(@grouping1.tas.length).to eq 2
          expect(@grouping1.tas).to include(@ta1)
          expect(@grouping1.tas).to include(@ta2)
          expect(@grouping2.tas).to eq []
          expect(@grouping3.tas).to eq []
        end

        it 'and two graders and two groupings are selected' do
          post_as @admin,
                  :global_actions,
                  params: { assignment_id: @assignment.id, global_actions: 'assign',
                            groupings: [@grouping1, @grouping2], graders: [@ta1, @ta2], current_table: 'groups_table' }
          expect(response.status).to eq(200)
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
          post_as @admin,
                  :global_actions,
                  params: { assignment_id: @assignment.id, global_actions: 'assign',
                            groupings: [@grouping1, @grouping2, @grouping3], graders: [@ta1, @ta2, @ta3],
                            current_table: 'groups_table' }
          expect(response.status).to eq(200)
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
          create(:ta_membership, user: @ta1, grouping: @grouping2)
          create(:ta_membership, user: @ta2, grouping: @grouping1)
          post_as @admin,
                  :global_actions,
                  params: { assignment_id: @assignment.id, global_actions: 'assign',
                            groupings: [@grouping1, @grouping2], graders: [@ta1.id.to_s, @ta2.id.to_s],
                            current_table: 'groups_table' }
          expect(response.status).to eq(200)
          expect(@grouping1.tas.length).to eq 2
          expect(@grouping1.tas).to include(@ta1)
          expect(@grouping1.tas).to include(@ta2)
          expect(@grouping2.tas.length).to eq 2
          expect(@grouping2.tas).to include(@ta1)
          expect(@grouping2.tas).to include(@ta2)
          expect(@grouping3.tas).to eq []
        end
      end #assign

      context 'POST on :global_actions on unassign' do
        before :each do
          @grouping1 = create(:grouping, assignment: @assignment)
          @grouping2 = create(:grouping, assignment: @assignment)
          @grouping3 = create(:grouping, assignment: @assignment)
          @ta1 = create(:ta)
          @ta2 = create(:ta)
          @ta3 = create(:ta)
        end

        it 'and no graders or groupings are selected' do
          create(:ta_membership, user: @ta1, grouping: @grouping1)
          create(:ta_membership, user: @ta2, grouping: @grouping2)
          post_as @admin,
                  :global_actions,
                  params: { assignment_id: @assignment.id, global_actions: 'unassign', current_table: 'groups_table' }
          expect(response.status).to eq(400)
          expect(@grouping1.tas).to eq [@ta1]
          expect(@grouping2.tas).to eq [@ta2]
          expect(@grouping3.tas).to eq []
        end

        it 'and all graders from one grouping are selected' do
          create(:ta_membership, user: @ta1, grouping: @grouping1)
          create(:ta_membership, user: @ta2, grouping: @grouping1)
          create(:ta_membership, user: @ta3, grouping: @grouping1)
          create(:ta_membership, user: @ta3, grouping: @grouping3)
          post_as @admin,
                  :global_actions,
                  params: { assignment_id: @assignment.id, global_actions: 'unassign',
                            groupings: [@grouping1.id],
                            graders: [@ta1.id, @ta2.id, @ta3.id],
                            current_table: 'groups_table' }
          expect(response.status).to eq(200)
          expect(@grouping1.tas).to eq []
          expect(@grouping2.tas).to eq []
          expect(@grouping3.tas).to eq [@ta3]
        end

        it 'and all groupings from one grader are selected' do
          create(:ta_membership, user: @ta1, grouping: @grouping1)
          create(:ta_membership, user: @ta2, grouping: @grouping1)
          ta_memberships = [
            create(:ta_membership, user: @ta3, grouping: @grouping1),
            create(:ta_membership, user: @ta3, grouping: @grouping2),
            create(:ta_membership, user: @ta3, grouping: @grouping3),
          ]
          post_as @admin,
                  :global_actions,
                  params: { assignment_id: @assignment.id, global_actions: 'unassign',
                            groupings: [@grouping1.id, @grouping2.id, @grouping3.id],
                            graders: [@ta3.id],
                            current_table: 'groups_table' }
          expect(response.status).to eq(200)
          expect(@grouping1.tas).not_to include(@ta3)
          expect(@grouping2.tas).not_to include(@ta3)
          expect(@grouping3.tas).not_to include(@ta3)
          expect(@grouping1.tas).to include(@ta1)
          expect(@grouping1.tas).to include(@ta2)
        end

        it 'and one grader and one grouping is selected where the grader and grouping have other memberships' do
          create(:ta_membership, user: @ta1, grouping: @grouping2)
          create(:ta_membership, user: @ta1, grouping: @grouping1)
          create(:ta_membership, user: @ta2, grouping: @grouping1)
          create(:ta_membership, user: @ta3, grouping: @grouping1)
          create(:ta_membership, user: @ta2, grouping: @grouping2)
          create(:ta_membership, user: @ta3, grouping: @grouping2)
          create(:ta_membership, user: @ta1, grouping: @grouping3)
          create(:ta_membership, user: @ta2, grouping: @grouping3)
          create(:ta_membership, user: @ta3, grouping: @grouping3)
          post_as @admin,
                  :global_actions,
                  params: { assignment_id: @assignment.id, global_actions: 'unassign',
                            groupings: [@grouping2.id],
                            graders: [@ta1.id],
                            current_table: 'groups_table' }
          expect(response.status).to eq(200)
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
          create(:ta_membership, user: @ta1, grouping: @grouping1)
          create(:ta_membership, user: @ta2, grouping: @grouping1)
          create(:ta_membership, user: @ta3, grouping: @grouping1)
          create(:ta_membership, user: @ta1, grouping: @grouping2)
          create(:ta_membership, user: @ta2, grouping: @grouping2)
          create(:ta_membership, user: @ta3, grouping: @grouping2)
          create(:ta_membership, user: @ta1, grouping: @grouping3)
          create(:ta_membership, user: @ta2, grouping: @grouping3)
          create(:ta_membership, user: @ta3, grouping: @grouping3)
          post_as @admin,
                  :global_actions,
                  params: { assignment_id: @assignment.id, global_actions: 'unassign',
                            groupings: [@grouping1.id, @grouping2.id, @grouping3.id],
                            graders: [@ta1.id, @ta2.id, @ta3.id],
                            current_table: 'groups_table' }
          expect(response.status).to eq(200)
          expect(@grouping1.tas).to eq []
          expect(@grouping2.tas).to eq []
          expect(@grouping3.tas).to eq []
        end
      end #unassign

    end #groupings table

    context 'With criteria table selected' do
      context 'with rubric marking scheme doing a' do
        context 'POST on :global_actions on random_assign' do
          before :each do
            @criterion1 = create(:rubric_criterion, assignment: @assignment)
            @criterion2 = create(:rubric_criterion, assignment: @assignment)
            @criterion3 = create(:rubric_criterion, assignment: @assignment)
            @ta1 = create(:ta)
            @ta2 = create(:ta)
            @ta3 = create(:ta)
          end

          it 'and no graders selected' do
            post_as @admin,
                    :global_actions,
                    params: { assignment_id: @assignment.id, global_actions: 'random_assign',
                              current_table: 'criteria_table' }
            expect(response.status).to eq(400)
            @assignment.get_criteria do |criterion|
              expect(criterion.tas).to eq []
            end
          end

          it 'and no criteria selected, at least one grader' do
            post_as @admin,
                    :global_actions,
                    params: { assignment_id: @assignment.id, global_actions: 'random_assign', graders: [@ta1],
                              current_table: 'criteria_table' }
            expect(response.status).to eq(400)
            @assignment.get_criteria do |criterion|
              expect(criterion.tas).to eq []
            end
          end

          it 'and no graders are selected, at least one criterion' do
            post_as @admin,
                    :global_actions,
                    params: { assignment_id: @assignment.id, global_actions: 'random_assign',
                              criteria: [@criterion1.position],
                              current_table: 'criteria_table' }
            expect(response.status).to eq(400)
            @assignment.get_criteria do |criterion|
              expect(criterion.tas).to eq []
            end
          end

          it 'and one grader and one criterion is selected' do
            post_as @admin,
                    :global_actions,
                    params: { assignment_id: @assignment.id, global_actions: 'random_assign',
                              criteria: [@criterion1.position],
                              graders: [@ta1.id],
                              current_table: 'criteria_table' }
            expect(response.status).to eq(200)
            expect(@criterion1.tas[0].id).to eq @ta1.id
            expect(@criterion2.tas).to eq []
            expect(@criterion3.tas).to eq []
          end

          it 'and one grader and multiple criteria are selected' do
            post_as @admin,
                    :global_actions,
                    params: { assignment_id: @assignment.id, global_actions: 'random_assign',
                              criteria: [@criterion1.position, @criterion2.position],
                              graders: [@ta1.id], current_table: 'criteria_table' }
            expect(response.status).to eq(200)
            expect(@criterion1.tas[0].id).to eq @ta1.id
            expect(@criterion2.tas[0].id).to eq @ta1.id
            expect(@criterion3.tas).to eq []
          end

          it 'and two graders and one criterion is selected' do
            post_as @admin,
                    :global_actions,
                    params: { assignment_id: @assignment.id, global_actions: 'random_assign',
                              criteria: [@criterion1.position],
                              graders: [@ta1.id, @ta2.id], current_table:  'criteria_table' }
            expect(response.status).to eq(200)
            expect(@criterion1.tas[0].id).to eq(@ta1.id).or(eq(@ta2.id))
            expect(@criterion2.tas).to eq []
            expect(@criterion3.tas).to eq []
          end

          it 'and two graders and two criteria are selected' do
            post_as @admin,
                    :global_actions,
                    params: { assignment_id: @assignment.id, global_actions: 'random_assign',
                              criteria: [@criterion1.position, @criterion2.position],
                              graders: [@ta1.id, @ta2.id], current_table: 'criteria_table' }
            expect(response.status).to eq(200)
            expect(@criterion1.tas[0].id).to eq(@ta1.id).or(eq(@ta2.id))
            expect(@criterion2.tas[0].id).to eq(@ta1.id).or(eq(@ta2.id))
            expect(@criterion1.tas[0].id).not_to eq @criterion2.tas[0].id
            expect(@criterion3.tas).to eq []
          end

          it 'and multiple graders and multiple criteria are selected' do
            @ta3 = create(:ta)
            post_as @admin,
                    :global_actions,
                    params: { assignment_id: @assignment.id, global_actions: 'random_assign',
                              criteria: [@criterion1.position, @criterion2.position, @criterion3.position],
                              graders: [@ta1.id, @ta2.id, @ta3.id], current_table: 'criteria_table' }
            expect(response.status).to eq(200)
            expect(@criterion1.tas.size).to eq(1)
            expect(@criterion2.tas.size).to eq(1)
            expect(@criterion3.tas.size).to eq(1)
          end
        end #random assign

        context 'POST on :global_actions on assign' do
          before :each do
            @criterion1 = create(:rubric_criterion, assignment: @assignment)
            @criterion2 = create(:rubric_criterion, assignment: @assignment)
            @criterion3 = create(:rubric_criterion, assignment: @assignment)
            @ta1 = create(:ta)
            @ta2 = create(:ta)
            @ta3 = create(:ta)
          end

          it 'and no graders selected' do
            post_as @admin,
                    :global_actions,
                    params: { assignment_id: @assignment.id, global_actions: 'assign', current_table: 'criteria_table' }
            expect(response.status).to eq(400)
            @assignment.get_criteria do |criterion|
              expect(criterion.tas).to eq []
            end
          end

          it 'and no criteria selected, at least one grader' do
            post_as @admin,
                    :global_actions,
                    params: { assignment_id: @assignment.id, global_actions: 'assign', graders: [@ta1],
                              current_table: 'criteria_table' }
            expect(response.status).to eq(400)
            @assignment.get_criteria do |criterion|
              expect(criterion.tas).to eq []
            end
          end

          it 'and no graders are selected, at least one criterion' do
            post_as @admin,
                    :global_actions,
                    params: { assignment_id: @assignment.id, global_actions: 'assign',
                              criteria: [@criterion1.position],
                              current_table: 'criteria_table' }
            expect(response.status).to eq(400)
            @assignment.get_criteria do |criterion|
              expect(criterion.tas).to eq []
            end
          end

          it 'and one grader and one criterion is selected' do
            post_as @admin,
                    :global_actions,
                    params: { assignment_id: @assignment.id, global_actions: 'assign',
                              criteria: [@criterion1.position],
                              graders: [@ta1.id],
                              current_table: 'criteria_table' }
            expect(response.status).to eq(200)
            expect(@criterion1.tas[0].id).to eq @ta1.id
            expect(@criterion2.tas).to eq []
            expect(@criterion3.tas).to eq []
          end

          it 'and one grader and two criteria are selected' do
            post_as @admin,
                    :global_actions,
                    params: { assignment_id: @assignment.id, global_actions: 'assign',
                              criteria: [@criterion1.position, @criterion2.position],
                              graders: [@ta1.id],
                              current_table: 'criteria_table' }
            expect(response.status).to eq(200)
            expect(@criterion1.tas[0].id).to eq @ta1.id
            expect(@criterion2.tas[0].id).to eq @ta1.id
            expect(@criterion3.tas).to eq []
          end

          it 'and two graders and one criterion is selected' do
            post_as @admin,
                    :global_actions,
                    params: { assignment_id: @assignment.id, global_actions: 'assign',
                              criteria: [@criterion1.position],
                              graders: [@ta1.id, @ta2.id],
                              current_table: 'criteria_table' }
            expect(response.status).to eq(200)
            expect(@criterion1.tas.length).to eq 2
            expect(@criterion1.tas).to include(@ta1)
            expect(@criterion1.tas).to include(@ta2)
            expect(@criterion2.tas).to eq []
            expect(@criterion3.tas).to eq []
          end

          it 'and two graders and two criteria are selected' do
            post_as @admin,
                    :global_actions,
                    params: { assignment_id: @assignment.id, global_actions: 'assign',
                              criteria: [@criterion1.position, @criterion2.position],
                              graders: [@ta1.id, @ta2.id],
                              current_table: 'criteria_table' }
            expect(response.status).to eq(200)
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
            post_as @admin,
                    :global_actions,
                    params: { assignment_id: @assignment.id, global_actions: 'assign',
                              criteria: [@criterion1.position, @criterion2.position, @criterion3.position],
                              graders: [@ta1.id, @ta2.id, @ta3.id], current_table: 'criteria_table' }
            expect(response.status).to eq(200)
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
            post_as @admin,
                    :global_actions,
                    params: { assignment_id: @assignment.id, global_actions: 'assign',
                              criteria: [@criterion1.position, @criterion2.position],
                              graders: [@ta1.id, @ta2.id],
                              current_table: 'criteria_table' }

            expect(response.status).to eq(200)
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
        end #assign

        context 'POST on :global_actions on unassign' do
          before :each do
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
            post_as @admin,
                    :global_actions,
                    params: { assignment_id: @assignment.id, global_actions: 'unassign',
                              current_table: 'criteria_table' }
            expect(response.status).to eq(400)
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
            post_as @admin,
                    :global_actions,
                    params: { assignment_id: @assignment.id, global_actions: 'unassign',
                              criteria: [@criterion1.position],
                              graders: [@ta1.id, @ta2.id, @ta3.id],
                              current_table: 'criteria_table' }
            expect(response.status).to eq(200)
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
            post_as @admin,
                    :global_actions,
                    params: { assignment_id: @assignment.id, global_actions: 'unassign',
                              criteria: [@criterion1.position, @criterion2.position, @criterion3.position],
                              graders: [@ta3.id],
                              current_table: 'criteria_table' }
            expect(response.status).to eq(200)
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
            post_as @admin,
                    :global_actions,
                    params: { assignment_id: @assignment.id, global_actions: 'unassign',
                              graders: [@ta1.id],
                              criteria: [@criterion2.position],
                              current_table: 'criteria_table' }
            expect(response.status).to eq(200)
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
            post_as @admin,
                    :global_actions,
                    params: { assignment_id: @assignment.id, global_actions: 'unassign',
                              criteria: [@criterion1.position, @criterion2.position, @criterion3.position],
                              graders: [@ta1.id, @ta2.id, @ta3.id],
                              current_table: 'criteria_table' }
            expect(response.status).to eq(200)
            expect(@criterion1.tas).to eq []
            expect(@criterion2.tas).to eq []
            expect(@criterion3.tas).to eq []
          end
        end #unassign

      end #rubric scheme

      context 'with flexible marking scheme doing a' do
        before :each do
          @assignment = create(:assignment)
        end

        context 'POST on :global_actions on random_assign' do
          before :each do
            @criterion1 = create(:flexible_criterion, assignment: @assignment)
            @criterion2 = create(:flexible_criterion, assignment: @assignment)
            @criterion3 = create(:flexible_criterion, assignment: @assignment)
            @ta1 = create(:ta)
            @ta2 = create(:ta)
            @ta3 = create(:ta)
          end

          it 'and no graders selected' do
            post_as @admin,
                    :global_actions,
                    params: { assignment_id: @assignment.id, global_actions: 'random_assign',
                              current_table: 'criteria_table' }
            expect(response.status).to eq(400)
            @assignment.get_criteria do |criterion|
              expect(criterion.tas).to eq []
            end
          end

          it 'and no criteria selected, at least one grader' do
            post_as @admin,
                    :global_actions,
                    params: { assignment_id: @assignment.id, global_actions: 'random_assign', graders: [@ta1],
                              current_table: 'criteria_table' }
            expect(response.status).to eq(400)
            @assignment.get_criteria do |criterion|
              expect(criterion.tas).to eq []
            end
          end

          it 'and no graders are selected, at least one criterion' do
            post_as @admin,
                    :global_actions,
                    params: { assignment_id: @assignment.id, global_actions: 'random_assign',
                              criteria: [@criterion1.position],
                              current_table: 'criteria_table' }
            expect(response.status).to eq(400)
            @assignment.get_criteria do |criterion|
              expect(criterion.tas).to eq []
            end
          end

          it 'and one grader and one criterion is selected' do
            post_as @admin,
                    :global_actions,
                    params: { assignment_id: @assignment.id, global_actions: 'random_assign',
                              criteria: [@criterion1.position], graders: [@ta1.id],
                              current_table: 'criteria_table' }
            expect(response.status).to eq(200)
            expect(@criterion1.tas[0].id).to eq @ta1.id
            expect(@criterion2.tas).to eq []
            expect(@criterion3.tas).to eq []
          end

          it 'and one grader and multiple criteria are selected' do
            post_as @admin,
                    :global_actions,
                    params: { assignment_id: @assignment.id, global_actions: 'random_assign',
                              criteria: [@criterion1.position, @criterion2.position],
                              graders: [@ta1.id],
                              current_table: 'criteria_table' }
            expect(response.status).to eq(200)
            expect(@criterion1.tas[0].id).to eq @ta1.id
            expect(@criterion2.tas[0].id).to eq @ta1.id
            expect(@criterion3.tas).to eq []
          end

          it 'and two graders and one criterion is selected' do
            post_as @admin,
                    :global_actions,
                    params: { assignment_id: @assignment.id, global_actions: 'random_assign',
                              criteria: [@criterion1.position],
                              graders: [@ta1.id, @ta2.id],
                              current_table: 'criteria_table' }
            expect(response.status).to eq(200)
            expect(@criterion1.tas[0].id).to eq(@ta1.id).or(eq(@ta2.id))
            expect(@criterion2.tas).to eq []
            expect(@criterion3.tas).to eq []
          end

          it 'and two graders and two criteria are selected' do
            post_as @admin,
                    :global_actions,
                    params: { assignment_id: @assignment.id, global_actions: 'random_assign',
                              criteria: [@criterion1.position, @criterion2.position],
                              graders: [@ta1.id, @ta2.id],
                              current_table: 'criteria_table' }
            expect(response.status).to eq(200)
            expect(@criterion1.tas[0].id).to eq(@ta1.id).or(eq(@ta2.id))
            expect(@criterion2.tas[0].id).to eq(@ta1.id).or(eq(@ta2.id))
            expect(@criterion1.tas[0].id).not_to eq(@criterion2.tas[0].id)
            expect(@criterion3.tas).to eq []
          end

          it 'and multiple graders and multiple criteria are selected' do
            @ta3 = create(:ta)
            post_as @admin,
                    :global_actions,
                    params: { assignment_id: @assignment.id, global_actions: 'random_assign',
                              criteria: [@criterion1.position, @criterion2.position, @criterion3.position],
                              graders: [@ta1.id, @ta2.id, @ta3.id],
                              current_table: 'criteria_table' }
            expect(response.status).to eq(200)
            expect(@criterion1.tas.size).to eq 1
            expect(@criterion2.tas.size).to eq 1
            expect(@criterion3.tas.size).to eq 1
          end
        end #random assign

        context 'POST on :global_actions on assign' do
          before :each do
            @criterion1 = create(:flexible_criterion, assignment: @assignment, position: 1)
            @criterion2 = create(:flexible_criterion, assignment: @assignment, position: 2)
            @criterion3 = create(:flexible_criterion, assignment: @assignment, position: 3)
            @ta1 = create(:ta)
            @ta2 = create(:ta)
            @ta3 = create(:ta)
          end

          it 'and no graders selected' do
            post_as @admin,
                    :global_actions,
                    params: { assignment_id: @assignment.id, global_actions: 'assign', current_table: 'criteria_table' }
            expect(response.status).to eq(400)
            @assignment.get_criteria do |criterion|
              expect(criterion.tas).to eq []
            end
          end

          it 'and no criteria selected, at least one grader' do
            post_as @admin,
                    :global_actions,
                    params: { assignment_id: @assignment.id, global_actions: 'assign', graders: [@ta1],
                              current_table: 'criteria_table' }
            expect(response.status).to eq(400)
            @assignment.get_criteria do |criterion|
              expect(criterion.tas).to eq []
            end
          end

          it 'and no graders are selected, at least one criterion' do
            post_as @admin,
                    :global_actions,
                    params: { assignment_id: @assignment.id, global_actions: 'assign', criteria: [@criterion1],
                              current_table: 'criteria_table' }
            expect(response.status).to eq(400)
            @assignment.get_criteria do |criterion|
              expect(criterion.tas).to eq []
            end
          end

          it 'and one grader and one criterion is selected' do
            post_as @admin,
                    :global_actions,
                    params: { assignment_id: @assignment.id, global_actions: 'assign',
                              criteria: [@criterion1.position],
                              graders: [@ta1.id],
                              current_table: 'criteria_table' }
            expect(response.status).to eq(200)
            expect(@criterion1.tas[0].id).to eq @ta1.id
            expect(@criterion2.tas).to eq []
            expect(@criterion3.tas).to eq []
          end

          it 'and one grader and two criteria are selected' do
            post_as @admin,
                    :global_actions,
                    params: { assignment_id: @assignment.id, global_actions: 'assign',
                              criteria: [@criterion1.position, @criterion2.position],
                              graders: [@ta1.id],
                              current_table: 'criteria_table' }
            expect(response.status).to eq(200)
            expect(@criterion1.tas[0].id).to eq @ta1.id
            expect(@criterion2.tas[0].id).to eq @ta1.id
            expect(@criterion3.tas).to eq []
          end

          it 'and two graders and one criterion is selected' do
            post_as @admin,
                    :global_actions,
                    params: { assignment_id: @assignment.id, global_actions: 'assign',
                              criteria: [@criterion1.position],
                              graders: [@ta1.id, @ta2.id],
                              current_table: 'criteria_table' }
            expect(response.status).to eq(200)
            expect(@criterion1.tas.length).to eq 2
            expect(@criterion1.tas).to include(@ta1)
            expect(@criterion1.tas).to include(@ta2)
            expect(@criterion2.tas).to eq []
            expect(@criterion3.tas).to eq []
          end

          it 'and two graders and two criteria are selected' do
            post_as @admin,
                    :global_actions,
                    params: { assignment_id: @assignment.id, global_actions: 'assign',
                              criteria: [@criterion1.position, @criterion2.position],
                              graders: [@ta1.id, @ta2.id],
                              current_table: 'criteria_table' }
            expect(response.status).to eq(200)
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
            post_as @admin,
                    :global_actions,
                    params: { assignment_id: @assignment.id, global_actions: 'assign',
                              criteria: [@criterion1.position, @criterion2.position, @criterion3.position],
                              graders: [@ta1.id, @ta2.id, @ta3.id], current_table: 'criteria_table' }
            expect(response.status).to eq(200)
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
            post_as @admin,
                    :global_actions,
                    params: { assignment_id: @assignment.id, global_actions: 'assign',
                              criteria: [@criterion1.position, @criterion2.position],
                              graders: [@ta1.id, @ta2.id], current_table: 'criteria_table' }
            expect(response.status).to eq(200)
            @criterion1.reload
            @criterion2.reload
            expect(@criterion1.tas.length).to eq 2
            expect(@criterion1.tas).to include(@ta1)
            expect(@criterion1.tas).to include(@ta2)
            expect(@criterion2.tas.length).to eq 2
            expect(@criterion2.tas).to include(@ta1)
            expect(@criterion2.tas).to include(@ta2)
            expect(@criterion3.tas).to eq []
          end
        end #assign

        context 'POST on :global_actions on unassign' do
          before :each do
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
            post_as @admin,
                    :global_actions,
                    params: { assignment_id: @assignment.id, global_actions: 'unassign',
                              current_table: 'criteria_table' }
            expect(response.status).to eq(400)
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
            post_as @admin,
                    :global_actions,
                    params: { assignment_id: @assignment.id, global_actions: 'unassign',
                              criteria: [@criterion1.position],
                              graders: [@ta1.id, @ta2.id, @ta3.id],
                              current_table: 'criteria_table' }
            expect(response.status).to eq(200)
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
            post_as @admin,
                    :global_actions,
                    params: { assignment_id: @assignment.id, global_actions: 'unassign',
                              criteria: [@criterion1.position, @criterion2.position, @criterion3.position],
                              graders: [@ta3.id],
                              current_table: 'criteria_table' }
            expect(response.status).to eq(200)
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
            criterion_ta = CriterionTaAssociation.create(ta: @ta1, criterion: @criterion2)
            CriterionTaAssociation.create(ta: @ta2, criterion: @criterion2)
            CriterionTaAssociation.create(ta: @ta3, criterion: @criterion2)
            CriterionTaAssociation.create(ta: @ta1, criterion: @criterion3)
            CriterionTaAssociation.create(ta: @ta2, criterion: @criterion3)
            CriterionTaAssociation.create(ta: @ta3, criterion: @criterion3)
            post_as @admin,
                    :global_actions,
                    params: { assignment_id: @assignment.id, global_actions: 'unassign',
                              criteria: [@criterion2.position],
                              graders: [@ta1.id],
                              current_table: 'criteria_table' }
            expect(response.status).to eq(200)
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
            post_as @admin,
                    :global_actions,
                    params: { assignment_id: @assignment.id, global_actions: 'unassign',
                              criteria: [@criterion1.position, @criterion2.position, @criterion3.position],
                              graders: [@ta1.id, @ta2.id, @ta3.id],
                              current_table: 'criteria_table' }
            expect(response.status).to eq(200)
            expect(@criterion1.tas).to eq []
            expect(@criterion2.tas).to eq []
            expect(@criterion3.tas).to eq []
          end
        end #unassign

      end #flexible scheme
    end #criteria table

  end #admin context
end
