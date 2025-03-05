require 'net/http'

module AutomatedTestsHelper
  def extra_test_group_schema(assignment)
    criterion_names = [{ const: nil, title: I18n.t('not_applicable') }]
    criterion_names += assignment.ta_criteria.order(:name).pluck(:name).map { |c| { const: c, title: c } }
    { type: :object,
      properties: {
        name: {
          type: :string,
          title: "#{TestGroup.model_name.human} #{TestGroup.human_attribute_name(:name).downcase}",
          default: TestGroup.model_name.human
        },
        display_output: {
          type: :string,
          oneOf: TestGroup.display_outputs.keys.map do |k|
            { const: k, title: I18n.t("automated_tests.display_output.#{k}") }
          end,
          default: TestGroup.display_outputs.keys.first,
          title: I18n.t('automated_tests.display_output_title')
        },
        criterion: {
          type: %w[string null],
          title: Criterion.model_name.human,
          oneOf: criterion_names,
          default: nil
        }
      },
      required: %w[display_output] }
  end

  def fill_in_schema_data!(schema_data, files, assignment)
    if files.present?
      schema_data['definitions']['files_list']['enum'] = files
    else
      schema_data['definitions']['files_list']['enum'] = ['']
    end
    schema_data['definitions']['test_data_categories']['enum'] = TestRun.all_test_categories
    schema_data['definitions']['extra_group_data'] = extra_test_group_schema(assignment)

    # TODO: remove these two lines when autotest schema is updated
    schema_data['definitions']['tester_schemas']['discriminator'] = { propertyName: 'tester_type' }
    schema_data['definitions']['tester_schemas']['required'] = ['tester_type']
    schema_data
  end

  def autotest_settings_for(assignment)
    test_specs = assignment.autotest_settings&.deep_dup || {}
    test_specs['testers']&.each do |tester_specs|
      test_group_ids = tester_specs['test_data'] || []
      tester_specs['test_data'] = assignment.test_groups.where(id: test_group_ids).order(:position).map(&:to_json)
    end
    test_specs
  end

  # Create/Modify test groups based on the autotest specs
  def update_test_groups_from_specs(assignment, test_specs)
    test_group_ids = []

    test_group_position = 1
    test_specs['testers']&.each do |tester_specs|
      current_test_group_ids = []
      tester_specs['test_data']&.each do |test_group_specs|
        test_group_specs['extra_info'] ||= {}
        extra_data_specs = test_group_specs['extra_info']
        test_group_id = extra_data_specs['test_group_id']
        display_output = extra_data_specs['display_output'] || TestGroup.display_outputs.keys.first
        test_group_name = extra_data_specs['name'] || TestGroup.model_name.human
        criterion_name = extra_data_specs['criterion']
        criterion = assignment.ta_criteria.find_by(name: criterion_name)
        if criterion_name.present? && criterion.nil?
          flash_message(:warning, I18n.t('automated_tests.no_criteria', name: criterion_name))
        end
        fields = { name: test_group_name, display_output: display_output,
                   criterion_id: criterion&.id, autotest_settings: test_group_specs,
                   position: test_group_position }
        test_group_position += 1
        if test_group_id.nil?
          test_group = assignment.test_groups.create!(fields)
          test_group_id = test_group.id
          extra_data_specs['test_group_id'] = test_group_id # update specs to contain new id
        else
          test_group = assignment.test_groups.find(test_group_id)
          test_group.update!(fields)
        end
        test_group_ids << test_group_id
        current_test_group_ids << test_group_id
      end
      tester_specs['test_data'] = current_test_group_ids
    end

    # Save test specs
    assignment.update!(autotest_settings: test_specs)
  end

  def server_params(markus_address, assignment_id)
    { client_type: :markus,
      client_data: { url: markus_address,
                     assignment_id: assignment_id,
                     api_key: server_api_key } }
  end

  def test_data(test_run_ids)
    TestRun.joins(:grouping, :role)
           .where(id: test_run_ids)
           .pluck_to_hash('groupings.group_id as group_id',
                          'test_runs.id as run_id',
                          'roles.type as role_type')
           .each { |h| h[:user_type] = 'Instructor' if h[:user_type] == 'Ta' }
           .each { |h| h[:test_categories] = [h['user_type'].downcase] }
  end

  def get_markus_address(host_with_port)
    if Rails.application.config.relative_url_root.nil?
      host_with_port
    else
      host_with_port + Rails.application.config.relative_url_root
    end
  end

  # Sends RESTful api requests to the autotester
  module AutotestApi
    include AutomatedTestsHelper
    AUTOTEST_USERNAME = "markus_#{Rails.application.config.relative_url_root}".freeze

    class LimitExceededException < StandardError; end
    class UnauthorizedException < StandardError; end
    class ServiceUnavailableException < StandardError; end

    # Register this MarkUs instance with the autotester by sending a unique user name and credentials that
    # the autotester can use to make get requests to MarkUs' API
    def register(autotest_url)
      autotest_user = AutotestUser.find_or_create
      uri = URI("#{autotest_url}/register")
      req = Net::HTTP::Post.new(uri)
      req['Content-Type'] = 'application/json'
      req.body = { user_name: AUTOTEST_USERNAME,
                   auth_type: Api::MainApiController::AUTHTYPE,
                   credentials: autotest_user.api_key }.to_json
      res = send_request!(req, uri)
      JSON.parse(res.body)['api_key']
    end

    # Send updated credentials to the autotester for this MarkUs instance
    def update_credentials(autotest_setting)
      autotest_user = AutotestUser.find_or_create
      uri = URI("#{autotest_setting.url}/reset_credentials")
      req = Net::HTTP::Put.new(uri)
      req.body = { auth_type: Api::MainApiController::AUTHTYPE, credentials: autotest_user.api_key }.to_json
      set_headers(req, autotest_setting.api_key)
      send_request!(req, uri)
    end

    # Get the json schema from the autotester that we can use to render a form using so that users
    # can customize tests.
    def get_schema(autotest_setting)
      uri = URI("#{autotest_setting.url}/schema")
      req = Net::HTTP::Get.new(uri)
      set_headers(req, autotest_setting.api_key)
      res = send_request!(req, uri)
      JSON.parse(res.body).to_json
    end

    # Send settings (result of filling out the schema form and uploading files) to the autotester.
    # Each assignment can have one or zero settings associated with it on the autotester.
    def update_settings(assignment, host_with_port)
      assignment.reload && assignment.assignment_properties.reload
      if assignment.remote_autotest_settings_id
        uri = URI("#{assignment.course.autotest_setting.url}/settings/#{assignment.remote_autotest_settings_id}")
        req = Net::HTTP::Put.new(uri)
      else
        uri = URI("#{assignment.course.autotest_setting.url}/settings")
        req = Net::HTTP::Post.new(uri)
      end
      set_headers(req, assignment.course.autotest_setting.api_key)
      markus_address = get_markus_address(host_with_port)
      req.body = {
        settings: autotest_settings_for(assignment),
        file_url: "#{markus_address}/api/courses/#{assignment.course.id}/assignments/#{assignment.id}/test_files",
        files: assignment.autotest_files
      }.to_json
      res = send_request!(req, uri)
      remote_autotest_settings_id = JSON.parse(res.body)['settings_id']
      assignment.update!(remote_autotest_settings_id: remote_autotest_settings_id)
    end

    # Send tests to the autotester to be run.
    def run_tests(assignment, host_with_port, group_ids, role, collected: true, batch: nil)
      raise I18n.t('automated_tests.settings_not_setup') unless assignment.remote_autotest_settings_id

      uri = URI("#{assignment.course.autotest_setting.url}/settings/#{assignment.remote_autotest_settings_id}/test")
      req = Net::HTTP::Put.new(uri)
      set_headers(req, assignment.course.autotest_setting.api_key)
      markus_address = get_markus_address(host_with_port)
      # NOTE: this stores the order in which groups are sent to the autotester. The autotester will return an array of
      #       autotest_test_ids *in the same order* so this array can be zipped together with that one to create a
      #       mapping between the group id and the autotest_test_id (used later to associate the result of the test to
      #       a test run).
      group_id_send_order = []
      test_data = group_info_for_tests(assignment, group_ids).map do |id_, name, starter_files|
        param = collected ? 'collected=true' : ''
        file_url = "#{markus_address}/api/courses/#{assignment.course.id}/assignments/#{assignment.id}/" \
                   "groups/#{id_}/submission_files?#{param}"
        group_id_send_order << id_
        # TODO: add other relevant info to env_vars as needed and make the environment variable customizable
        { file_url: file_url, env_vars: { MARKUS_GROUP: name, MARKUS_STARTER_FILES: starter_files.to_json } }
      end
      req.body = {
        test_data: test_data,
        categories: role.student? ? ['student'] : ['instructor'],
        request_high_priority: batch.nil? && role.student?
      }.to_json
      res = send_request!(req, uri)
      autotest_test_ids = JSON.parse(res.body)['test_ids']
      test_id_hash = group_id_send_order.zip(autotest_test_ids).to_h
      groupings = Grouping.includes(:current_submission_used).where(group_id: group_ids, assignment: assignment)
      groupings.each do |grouping|
        revision_id = collected ? nil : grouping.access_repo { |repo| repo.get_latest_revision.revision_identifier }
        TestRun.create!(
          role_id: role.id,
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
      raise I18n.t('automated_tests.settings_not_setup') unless assignment.remote_autotest_settings_id

      uri = URI("#{assignment.course.autotest_setting.url}/settings/" \
                "#{assignment.remote_autotest_settings_id}/tests/cancel")
      req = Net::HTTP::Delete.new(uri)
      req.body = { test_ids: test_runs.where.not(autotest_test_id: nil).pluck(:autotest_test_id) }.to_json
      set_headers(req, assignment.course.autotest_setting.api_key)
      send_request!(req, uri)
      test_runs.each(&:cancel)
    end

    # Get the status of tests from the autotester
    def statuses(assignment, test_runs)
      raise I18n.t('automated_tests.settings_not_setup') unless assignment.remote_autotest_settings_id

      uri = URI("#{assignment.course.autotest_setting.url}/settings/" \
                "#{assignment.remote_autotest_settings_id}/tests/status")
      req = Net::HTTP::Get.new(uri)
      req.body = { test_ids: test_runs.pluck(:autotest_test_id) }.to_json
      set_headers(req, assignment.course.autotest_setting.api_key)
      res = send_request!(req, uri)
      JSON.parse(res.body)
    end

    # Get the results of a test from the autotester. If this is successful, the autotester will discard
    # the results of the test so all data must be saved.
    def results(assignment, test_run)
      raise I18n.t('automated_tests.settings_not_setup') unless assignment.remote_autotest_settings_id

      test_id = test_run.autotest_test_id
      settings_id = assignment.remote_autotest_settings_id
      uri = URI("#{assignment.course.autotest_setting.url}/settings/#{settings_id}/test/#{test_id}")
      req = Net::HTTP::Get.new(uri)
      set_headers(req, assignment.course.autotest_setting.api_key)
      res = send_request(req, uri)
      raise LimitExceededException if res.code == '429'
      if res.is_a?(Net::HTTPSuccess)
        results = JSON.parse(res.body)
        add_feedback_data(results, settings_id, test_id, assignment.course.autotest_setting)
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
        raise UnauthorizedException if res.code == '401'
        raise ServiceUnavailableException, JSON.parse(res.body)['message'] if res.code == '503'
        begin
          raise JSON.parse(res.body)['message']
        rescue JSON::ParserError
          raise res.body
        end
      end
      res
    end

    # Set default authentication and content type headers on the request object.
    def set_headers(req, api_key)
      req['Api-Key'] = api_key
      req['Content-Type'] = 'application/json'
    end

    # Get the current URL for this MarkUs instance (adds the relative url root to +host_with_port+) if it exists.
    def get_markus_address(host_with_port)
      if Rails.application.config.relative_url_root.nil?
        host_with_port
      else
        host_with_port + Rails.application.config.relative_url_root
      end
    end

    # Gets the feedback file data from the autotester for the TestRun with autotest_test_id = +test_id+
    # and adds it to the +results+ hash.
    def add_feedback_data(results, settings_id, test_id, autotest_setting)
      return if results['test_groups'].blank?

      results['test_groups'].each do |result|
        result['feedback']&.each do |feedback|
          feedback_id = feedback['id']
          next if feedback_id.nil?

          uri = URI("#{autotest_setting.url}/settings/#{settings_id}/test/#{test_id}/feedback/#{feedback_id}")
          req = Net::HTTP::Get.new(uri)
          set_headers(req, autotest_setting.api_key)
          res = send_request!(req, uri)
          feedback['content'] = res.body
        end
      end
    end
  end

  # Returns an array of arrays containing a group id, group name, and an array of
  # starter file entry paths assigned to the grouping associated with the +assignment+
  # and the given group.
  #
  # Only groups with id in +group_ids+ are included in the list.
  # Note that the group information returned by this function is not guaranteed to be in
  # the same order as +group_ids+.
  def group_info_for_tests(assignment, group_ids)
    assignment.groupings
              .left_outer_joins(:group, starter_file_entries: :starter_file_group)
              .where('groups.id': group_ids)
              .pluck('groups.id', 'groups.group_name', 'starter_file_groups.name', 'starter_file_entries.path')
              .group_by { |val| val[...2] }
              .map do |key, val|
                [*key,
                 val.filter_map { |v| { starter_file_group: v[2], starter_file_path: v[3] } if v[2] }
                    .sort_by { |x| [x[:starter_file_group], x[:starter_file_path]] }]
              end
  end

  def server_api_key
    AutotestUser.find_or_create.api_key
  rescue ActiveRecord::RecordNotUnique
    # find_or_create_by is not atomic, there could be race conditions on creation: we just retry until it succeeds
    retry
  end
end
