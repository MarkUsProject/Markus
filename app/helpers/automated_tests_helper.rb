module AutomatedTestsHelper
  def extra_test_group_schema(assignment)
    criterion_names, criterion_ids = assignment.ta_criteria.map do |c|
      [c.name, c.id]
    end.transpose
    { type: :object,
      properties: {
        name: {
          type: :string,
          title: "#{TestGroup.model_name.human} #{TestGroup.human_attribute_name(:name).downcase}",
          default: TestGroup.model_name.human
        },
        display_output: {
          type: :string,
          enum: TestGroup.display_outputs.keys,
          enumNames: TestGroup.display_outputs.keys.map { |k| I18n.t("automated_tests.display_output.#{k}") },
          default: TestGroup.display_outputs.keys.first,
          title: I18n.t('automated_tests.display_output_title')
        },
        criterion: {
          type: :string,
          enum: criterion_ids || [],
          enumNames: criterion_names || [],
          title: Criterion.model_name.human
        }
      },
      required: %w[display_output] }
  end

  def fill_in_schema_data!(schema_data, files, assignment)
    schema_data['definitions']['files_list']['enum'] = files
    schema_data['definitions']['test_data_categories']['enum'] = TestRun.all_test_categories
    schema_data['definitions']['extra_group_data'] = extra_test_group_schema(assignment)
    schema_data
  end

  def update_test_groups_from_specs(assignment, test_specs)
    test_specs_path = assignment.autotest_settings_file
    # create/modify test groups based on the autotest specs
    test_group_ids = []
    test_specs['testers'].each do |tester_specs|
      next if tester_specs['test_data'].nil?

      tester_specs['test_data'].each do |test_group_specs|
        test_group_specs['extra_info'] ||= {}
        extra_data_specs = test_group_specs['extra_info']
        test_group_id = extra_data_specs['test_group_id']
        display_output = extra_data_specs['display_output'] || TestGroup.display_outputs.keys.first
        test_group_name = extra_data_specs['name'] || TestGroup.model_name.human
        criterion_id = nil
        unless extra_data_specs['criterion'].nil?
          criterion_id = extra_data_specs['criterion']
        end
        fields = { assignment: assignment, name: test_group_name, display_output: display_output,
                   criterion_id: criterion_id }
        if test_group_id.nil?
          test_group = TestGroup.create!(fields)
          test_group_id = test_group.id
          extra_data_specs['test_group_id'] = test_group_id # update specs to contain new id
        else
          test_group = TestGroup.find(test_group_id)
          test_group.update!(fields)
        end
        test_group_ids << test_group_id
      end
    end
    # delete test groups that are not in the autotest specs
    deleted_test_groups = TestGroup.where(assignment: assignment)
    unless test_group_ids.empty?
      deleted_test_groups = deleted_test_groups.where.not(id: test_group_ids)
    end
    deleted_test_groups.delete_all
  ensure
    # save modified specs
    File.open(test_specs_path, 'w') { |f| f.write test_specs.to_json }
  end

  def server_params(markus_address, assignment_id)
    { client_type: :markus,
      client_data: { url: markus_address,
                     assignment_id: assignment_id,
                     api_key: server_api_key } }
  end

  def test_data(test_run_ids)
    TestRun.joins(:grouping, :user)
           .where(id: test_run_ids)
           .pluck_to_hash('groupings.group_id as group_id',
                          'test_runs.id as run_id',
                          'users.type as user_type')
           .each { |h| h[:test_categories] = [h['user_type'].downcase] }
  end

  def get_markus_address(host_with_port)
    if Rails.application.config.action_controller.relative_url_root.nil?
      host_with_port
    else
      host_with_port + Rails.application.config.action_controller.relative_url_root
    end
  end

  def run_autotester_command(command, server_kwargs)
    server_username = Rails.configuration.x.autotest.server_username
    server_command = Rails.configuration.x.autotest.server_command
    output = ''
    if server_username.nil?
      # local cancellation with no authentication
      args = [server_command, command, '-j', JSON.generate(server_kwargs)]
      output, status = Open3.capture2e(*args)
      if status.exitstatus != 0
        raise output
      end
    else
      # local or remote cancellation with authentication
      server_host = Rails.configuration.x.autotest.server_host
      Net::SSH.start(server_host, server_username, auth_methods: ['publickey']) do |ssh|
        args = "#{server_command} #{command} -j '#{JSON.generate(server_kwargs)}'"
        output = ssh.exec!(args)
        if output.exitstatus != 0
          raise output
        end
      end
    end
    output
  end

  private

  def server_api_key
    server_host = Rails.configuration.x.autotest.server_host
    server_user = TestServer.find_or_create_by(user_name: server_host) do |user|
      user.first_name = 'Autotest'
      user.last_name = 'Server'
      user.hidden = true
    end
    server_user.set_api_key

    server_user.api_key
  rescue ActiveRecord::RecordNotUnique
    # find_or_create_by is not atomic, there could be race conditions on creation: we just retry until it succeeds
    retry
  end
end
