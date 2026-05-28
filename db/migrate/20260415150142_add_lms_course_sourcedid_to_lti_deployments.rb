class AddLmsCourseSourcedidToLtiDeployments < ActiveRecord::Migration[8.1]
  def change
    add_column :lti_deployments, :lms_course_sourcedid, :string
  end
end
