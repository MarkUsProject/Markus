module AssessmentsHelper
  def formatted_assessment_visibility_label(assessment, base_text)
    return t('assignments.hidden', assignment_text: base_text) if assessment.currently_hidden?

    base_text
  end
end
