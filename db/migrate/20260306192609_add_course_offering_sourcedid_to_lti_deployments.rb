class AddCourseOfferingSourcedidToLtiDeployments < ActiveRecord::Migration[8.1]
  def change
    add_column :lti_deployments, :course_offering_sourcedid, :string
  end
end
