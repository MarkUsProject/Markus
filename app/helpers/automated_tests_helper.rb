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
      required: %w[display_output]
    }
  end

  def fill_in_schema_data!(schema_data, files, assignment)
    schema_data['definitions']['files_list']['enum'] = files
    schema_data['definitions']['test_data_categories']['enum'] = TestRun.all_test_categories
    schema_data['definitions']['extra_group_data'] = extra_test_group_schema(assignment)
    schema_data
  end
end
