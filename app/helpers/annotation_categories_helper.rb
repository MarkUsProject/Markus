require 'ya2yaml'

module AnnotationCategoriesHelper

  def prepare_for_conversion(annotation_categories)
    result = {}
    annotation_categories.each do |annotation_category|
      annotation_texts = []
      annotation_category.annotation_texts.each do |annotation_text|
        annotation_texts.push(annotation_text.content)
      end
      result[annotation_category.annotation_category_name] = annotation_texts
    end
    result
  end

  def convert_to_yml(annotation_categories)
    prepare_for_conversion(annotation_categories).ya2yaml
  end
end
