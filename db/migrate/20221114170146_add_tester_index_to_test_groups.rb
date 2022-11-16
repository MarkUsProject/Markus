class AddTesterIndexToTestGroups < ActiveRecord::Migration[7.0]
  def up
    add_column :test_groups, :tester_index, :integer, default: nil
    puts '-- converting test group ids in json string to tester index'
    Assignment.joins(:assignment_properties)
              .where.not('assignment_properties.autotest_settings': nil)
              .find_each do |assignment|
      test_specs = assignment.autotest_settings&.deep_dup || {}
      test_specs['testers']&.each_with_index do |tester_specs, i|
        test_group_ids = tester_specs['test_data'] || []
        assignment.test_groups.where(id: test_group_ids).update_all(tester_index: i)
      end
      assignment.update!(autotest_settings: test_specs)
    end
  end
  def down
    puts '-- converting tester index in json string to test group ids'
    Assignment.joins(:assignment_properties)
              .where.not('assignment_properties.autotest_settings': nil)
              .find_each do |assignment|
      test_specs = assignment.autotest_settings&.deep_dup || {}
      test_specs['testers']&.each_with_index do |tester_specs, i|
        tester_specs['test_data'] = assignment.test_groups.where(tester_index: i).ids
      end
      assignment.update!(autotest_settings: test_specs)
    end
    remove_column :test_groups, :tester_index
  end
end
