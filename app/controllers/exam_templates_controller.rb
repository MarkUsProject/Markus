# The actions necessary for managing the Testing Framework form
require 'helpers/ensure_config_helper.rb'

class ExamTemplatesController < ApplicationController

  before_filter      :authorize_only_for_admin

  layout 'assignment_content'

  def index
    @assignment = Assignment.find(params[:assignment_id])
    @assignment.test_scripts.build(
      # TODO: make these default values
      run_by_instructors: true,
      run_by_students: false,
      display_input: :do_not_display,
      display_expected_output: :do_not_display,
      display_actual_output: :do_not_display
    )
    @assignment.test_support_files.build
    @student_tests_on = MarkusConfigurator.markus_ate_experimental_student_tests_on?
  end
end
