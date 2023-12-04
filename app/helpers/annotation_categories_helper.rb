module AnnotationCategoriesHelper
  def prepare_for_conversion(annotation_categories)
    result = {}
    annotation_categories.each do |annotation_category|
      if annotation_category.flexible_criterion.nil?
        result[annotation_category.annotation_category_name] = [nil]
        result[annotation_category.annotation_category_name] += annotation_category.annotation_texts.pluck(:content)
      else
        annotation_text_info = [annotation_category.flexible_criterion.name]
        annotation_text_info += annotation_category.annotation_texts.pluck(:content, :deduction).flatten
        result[annotation_category.annotation_category_name] = annotation_text_info
      end
    end
    result
  end
end
