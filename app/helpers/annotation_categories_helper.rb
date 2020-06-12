module AnnotationCategoriesHelper

  def prepare_for_conversion(annotation_categories)
    result = {}
    annotation_categories.each do |annotation_category|
      if annotation_category.flexible_criterion.nil?
        annotation_texts = []
        annotation_category.annotation_texts.each do |annotation_text|
          annotation_texts.push(annotation_text.content)
        end
        result[annotation_category.annotation_category_name] = annotation_texts
      else
        annotation_text_info = []
        annotation_text_info.push(annotation_category.flexible_criterion.name)
        annotation_category.annotation_texts.each do |annotation_text|
          annotation_text_info.push(annotation_text.content)
          annotation_text_info.push(annotation_text.deduction.to_s)
        end
        result[annotation_category.annotation_category_name] = annotation_text_info
      end
    end
    result
  end

  def convert_to_yml(annotation_categories)
    prepare_for_conversion(annotation_categories).ya2yaml
  end
end
