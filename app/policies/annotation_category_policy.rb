# Policy for annotation categories controller.
class AnnotationCategoryPolicy < ApplicationPolicy
  default_rule :manage?
  alias_rule :find_annotation_text?, :index?, to: :read?

  def manage?
    check?(:manage_assessments?, user)
  end

  def read?
    check?(:admin?) || check?(:ta?)
  end
end
