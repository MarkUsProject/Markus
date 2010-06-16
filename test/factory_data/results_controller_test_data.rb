require File.dirname(__FILE__) + '/../test_helper'
require File.dirname(__FILE__) + '/../blueprints/helper'



def make_assignment(marking_scheme_type)
  assignment = Assignment.make({:group_min => 1, :group_max => 1, :marking_scheme_type => marking_scheme_type})
  
  criterion_class_name = marking_scheme_type.capitalize + 'Criterion'
  criterion_class = Kernel.const_get(criterion_class_name)
  criterion = criterion_class.make(:assignment => assignment)
  ta = Ta.make()
  make_submission(assignment, true, ta, 'group_c' + marking_scheme_type)
  make_submission(assignment, false, ta, 'group_b' + marking_scheme_type)
  make_submission(assignment, false, ta, 'group_a' + marking_scheme_type)
  
  return assignment
end

def make_submission(assignment, result_released, ta, group_name)
  criterion = assignment.get_criteria.first
  grouping = Grouping.make({:assignment => assignment, :group => Group.make(:group_name => group_name)})
  membership = StudentMembership.make(
    {
    :grouping => grouping,
    :membership_status => 'inviter'
    }
    )
  ta_membership = TaMembership.make(
    {
      :user => ta,
      :grouping => grouping
    }
  )
  submission = Submission.make(:grouping => grouping)
  annotation_category = AnnotationCategory.make({:assignment => assignment})
  text_annotation = TextAnnotation.make({
    :annotation_text => AnnotationText.make(:annotation_category => annotation_category),
    :submission_file => SubmissionFile.make(:submission => submission)
  })

  image_annotation = ImageAnnotation.make({
  :annotation_text => AnnotationText.make(:annotation_category => annotation_category),
  :submission_file => SubmissionFile.make(:submission => submission)
  })
  
  result = submission.result
  SubmissionFile.make(:submission => submission)
  mark = Mark.make({:result => result, :markable => criterion})
  extra_mark = ExtraMark.make(:result => result)
  
  if (result_released)
    result.marking_state = 'complete'
    result.released_to_students = true
    result.save
  end
end

FactoryData.preload(:assignments_for_results_controller_test, :model_class => Assignment) do |data|
  setup_group_fixture_repos
  data.add(:assignment_flexible) {make_assignment('flexible')}
  data.add(:assignment_rubric) {make_assignment('rubric')}
end

FactoryData.preload(:submission_files_for_result_controller_test, :model_class => SubmissionFile) do |data|
  data.add(:no_access_submission_file){SubmissionFile.make}
end

FactoryData.preload(:admins_for_result_controller_test, :model_class => User) do |data|
  setup_group_fixture_repos
  data.add(:admin) {Admin.make}
end