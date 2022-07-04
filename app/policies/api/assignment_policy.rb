module Api
  # Policies for Api::AssignmentsController
  class AssignmentPolicy < MainApiPolicy
    def test_files?
      real_user.autotest_user? || check?(:manage?)
    end

    def submit_file?
      role&.student? || false
    end

    def see_hidden?
      role.instructor? || role.ta? || role.visible_assessments(assessment_id: record.id).exists?
    end
  end
end
