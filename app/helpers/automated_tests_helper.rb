module AutomatedTestsHelper
  def extra_test_group_schema(assignment)
    criterion_names, criterion_disambig = assignment.get_criteria(:ta).map do |c|
      [c.name, "#{c.id}_#{c.class.name}"]
    end.transpose
    { type: :object,
      properties: {
        display_output: {
          type: :string,
          enum: TestGroup.display_outputs.keys,
          default: TestGroup.display_outputs.keys.first
        },
        criterion: {
          type: :string,
          enum: criterion_disambig || [],
          enumNames: criterion_names || []
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

      tester_specs['test_data'].each_with_index do |test_group_specs, i|
        test_group_specs['extra_info'] ||= {}
        extra_data_specs = test_group_specs['extra_info']
        test_group_name = test_group_specs['name'] || "#{tester_specs['tester_type']}: #{i}"
        test_group_id = extra_data_specs['test_group_id']
        display_output = extra_data_specs['display_output'] || TestGroup.display_outputs.keys.first
        criterion_id = nil
        criterion_type = nil
        if !extra_data_specs['criterion'].nil? && extra_data_specs['criterion'].include?('_')
          criterion_id, criterion_type = extra_data_specs['criterion'].split('_') # polymorphic field
        end
        fields = { assignment: assignment, name: test_group_name, display_output: display_output,
                   criterion_id: criterion_id, criterion_type: criterion_type }
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
end
