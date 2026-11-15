# Annotation policy class
class AnnotationPolicy < ApplicationPolicy
  def manage?
    check?(:review?, record.result)
  end

  def add_existing_annotation?
    check?(:grade?, record.result)
  end
end
