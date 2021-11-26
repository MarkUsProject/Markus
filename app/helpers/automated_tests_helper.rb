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
        unless extra_data_specs['criterion_name'].nil?
          associated_criterion = assignment.criteria.find_by(name: extra_data_specs['criterion_name'])
          unless associated_criterion.nil?
            extra_data_specs['criterion'] = associated_criterion.id
            test_group_specs['extra_info'] = test_group_specs['extra_info'].except('criterion_name')
            test_group_specs['extra_info']['criterion'] = associated_criterion.id
          end
        end
        criterion_id = extra_data_specs['criterion'] unless extra_data_specs['criterion'].nil?
        fields = { assignment: assignment, name: test_group_name, display_output: display_output,
                   criterion_id: criterion_id }
        if test_group_id.nil?
          test_group = TestGroup.create!(fields)
          test_group_id = test_group.id
          test_group_specs['extra_info']['test_group_id'] = test_group_id # update specs to contain new id
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
           .each { |h| h[:user_type] = 'Admin' if h[:user_type] == 'Ta' }
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
    server_username = Settings.autotest.server_username
    server_command = Settings.autotest.server_command
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
      server_host = Settings.autotest.server_host
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

  # Sends RESTful api requests to the autotester
  module AutotestApi
    AUTOTEST_USERNAME = "markus_#{Rails.application.config.action_controller.relative_url_root}".freeze
    AUTOTEST_KEY_FILE = File.join(::Rails.root, 'config', 'autotest.api_key').freeze

    class LimitExceededException < StandardError; end

    # Register this MarkUs instance with the autotester by sending a unique user name and credentials that
    # the autotester can use to make get requests to MarkUs' API
    def register
      test_server = TestServer.find_or_create
      uri = URI("#{Settings.autotest.url}/register")
      req = Net::HTTP::Post.new(uri)
      req['Content-Type'] = 'application/json'
      req.body = { user_name: AUTOTEST_USERNAME,
                   auth_type: Api::MainApiController::AUTHTYPE,
                   credentials: test_server.api_key }.to_json
      res = send_request!(req, uri)
      File.write(AUTOTEST_KEY_FILE, JSON.parse(res.body)['api_key'])
    end

    # Send updated credentials to the autotester for this MarkUs instance
    def update_credentials
      test_server = TestServer.find_or_create
      uri = URI("#{Settings.autotest.url}/reset_credentials")
      req = Net::HTTP::Put.new(uri)
      req.body = { auth_type: Api::MainApiController::AUTHTYPE, credentials: test_server.api_key }.to_json
      set_headers(req)
      send_request!(req, uri)
    end

    # Get the json schema from the autotester that we can use to render a form using so that users
    # can customize tests.
    def schema
      uri = URI("#{Settings.autotest.url}/schema")
      req = Net::HTTP::Get.new(uri)
      set_headers(req)
      res = send_request!(req, uri)
      testers_path = File.join(Settings.autotest.client_dir, 'testers.json')
      File.write(testers_path, JSON.parse(res.body).to_json)
    end

    # Send settings (result of filling out the schema form and uploading files) to the autotester.
    # Each assignment can have one or zero settings associated with it on the autotester.
    def update_settings(assignment, host_with_port)
      if assignment.autotest_settings_id
        uri = URI("#{Settings.autotest.url}/settings/#{assignment.autotest_settings_id}")
        req = Net::HTTP::Put.new(uri)
      else
        uri = URI("#{Settings.autotest.url}/settings")
        req = Net::HTTP::Post.new(uri)
      end
      set_headers(req)
      markus_address = get_markus_address(host_with_port)
      req.body = {
        settings: JSON.parse(File.read(assignment.autotest_settings_file)),
        file_url: "#{markus_address}/api/assignments/#{assignment.id}/test_files",
        files: assignment.autotest_files
      }.to_json
      res = send_request!(req, uri)
      autotest_settings_id = JSON.parse(res.body)['settings_id']
      assignment.update!(autotest_settings_id: autotest_settings_id)
    end

    # Send tests to the autotester to be run.
    def run_tests(assignment, host_with_port, group_ids, user, collected: true, batch: nil)
      raise I18n.t('automated_tests.settings_not_setup') unless assignment.autotest_settings_id

      uri = URI("#{Settings.autotest.url}/settings/#{assignment.autotest_settings_id}/test")
      req = Net::HTTP::Put.new(uri)
      set_headers(req)
      markus_address = get_markus_address(host_with_port)
      file_urls = group_ids.map do |id_|
        param = collected ? 'collected=true' : ''
        "#{markus_address}/api/assignments/#{assignment.id}/groups/#{id_}/submission_files?#{param}"
      end
      req.body = {
        file_urls: file_urls,
        categories: user.student? ? ['student'] : ['admin'],
        request_high_priority: batch.nil? && user.student?
      }.to_json
      res = send_request!(req, uri)
      autotest_test_ids = JSON.parse(res.body)['test_ids']
      test_id_hash = group_ids.zip(autotest_test_ids).to_h
      groupings = Grouping.includes(:current_submission_used).where(group_id: group_ids, assignment: assignment)
      groupings.each do |grouping|
        revision_id = collected ? nil : grouping.access_repo { |repo| repo.get_latest_revision.revision_identifier }
        TestRun.create!(
          user_id: user.id,
          test_batch_id: batch&.id,
          grouping_id: grouping.id,
          submission_id: collected ? grouping.current_submission_used.id : nil,
          revision_identifier: revision_id,
          autotest_test_id: test_id_hash[grouping.group.id],
          status: :in_progress
        )
      end
    end

    # Send a request to the autotester to cancel enqueued tests (will not cancel running tests)
    def cancel_tests(assignment, test_runs)
      raise I18n.t('automated_tests.settings_not_setup') unless assignment.autotest_settings_id

      uri = URI("#{Settings.autotest.url}/settings/#{assignment.autotest_settings_id}/tests/cancel")
      req = Net::HTTP::Delete.new(uri)
      req.body = { test_ids: test_runs.pluck(:autotest_test_id) }.to_json
      set_headers(req)
      send_request!(req, uri)
      test_runs.each(&:cancel)
    end

    # Get the status of tests from the autotester
    def statuses(assignment, test_runs)
      raise I18n.t('automated_tests.settings_not_setup') unless assignment.autotest_settings_id

      uri = URI("#{Settings.autotest.url}/settings/#{assignment.autotest_settings_id}/tests/status")
      req = Net::HTTP::Get.new(uri)
      req.body = { test_ids: test_runs.pluck(:autotest_test_id) }.to_json
      set_headers(req)
      res = send_request!(req, uri)
      JSON.parse(res.body)
    end

    # Get the results of a test from the autotester. If this is successful, the autotester will discard
    # the results of the test so all data must be saved.
    def results(assignment, test_run)
      raise I18n.t('automated_tests.settings_not_setup') unless assignment.autotest_settings_id

      test_id = test_run.autotest_test_id
      settings_id = assignment.autotest_settings_id
      uri = URI("#{Settings.autotest.url}/settings/#{settings_id}/test/#{test_id}")
      req = Net::HTTP::Get.new(uri)
      set_headers(req)
      res = send_request(req, uri)
      raise LimitExceededException if res.code == '429'
      if res.is_a?(Net::HTTPSuccess)
        results = JSON.parse(res.body)
        add_feedback_data(results, settings_id, test_id)
        test_run.update_results!(results)
      else
        test_run.failure(res.body)
      end
    end

    private

    # Send an http request
    def send_request(req, uri)
      Net::HTTP.start(uri.hostname, uri.port, use_ssl: uri.scheme == 'https') { |http| http.request(req) }
    end

    # Send an http request and raise an error if the result was not a success
    def send_request!(req, uri)
      res = send_request(req, uri)
      unless res.is_a?(Net::HTTPSuccess)
        raise LimitExceededException if res.code == '429'
        begin
          raise JSON.parse(res.body)['message']
        rescue JSON::ParserError
          raise res.body
        end
      end
      res
    end

    # Set default authentication and content type headers on the request object.
    def set_headers(req)
      req['Api-Key'] = File.read(AUTOTEST_KEY_FILE).strip
      req['Content-Type'] = 'application/json'
    end

    # Get the current URL for this MarkUs instance (adds the relative url root to +host_with_port+) if it exists.
    def get_markus_address(host_with_port)
      if Rails.application.config.action_controller.relative_url_root.nil?
        host_with_port
      else
        host_with_port + Rails.application.config.action_controller.relative_url_root
      end
    end

    # Gets the feedback file data from the autotester for the TestRun with autotest_test_id = +test_id+
    # and adds it to the +results+ hash.
    def add_feedback_data(results, settings_id, test_id)
      return if results['test_groups'].blank?

      results['test_groups'].each do |result|
        next if result['feedback'].nil?

        feedback_id = result['feedback']['id']
        next if feedback_id.nil?

        uri = URI("#{Settings.autotest.url}/settings/#{settings_id}/test/#{test_id}/feedback/#{feedback_id}")
        req = Net::HTTP::Get.new(uri)
        set_headers(req)
        res = send_request!(req, uri)
        result['feedback']['content'] = res.body
      end
    end
  end

  private

  def server_api_key
    server_user = TestServer.find_or_create_by(user_name: '.autotest') do |user|
      user.first_name = 'Autotest'
      user.last_name = 'Server'
      user.hidden = true
    end
    server_user.reset_api_key if server_user.api_key.nil?

    server_user.api_key
  rescue ActiveRecord::RecordNotUnique
    # find_or_create_by is not atomic, there could be race conditions on creation: we just retry until it succeeds
    retry
  end
end
