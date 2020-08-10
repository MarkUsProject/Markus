module AnnotationCategoriesHelper

  def prepare_for_conversion(annotation_categories)
    result = {}
    annotation_categories.each do |annotation_category|
      if annotation_category.flexible_criterion.nil?
        result[annotation_category.annotation_category_name] = [nil] +
          annotation_category.annotation_texts.pluck(:content)
      else
        annotation_text_info = [annotation_category.flexible_criterion.name]
        annotation_text_info += annotation_category.annotation_texts.pluck(:content, :deduction).flatten
        result[annotation_category.annotation_category_name] = annotation_text_info
      end
    end
    result
  end

  def convert_to_yml(annotation_categories)
    categories_data = {}
    annotation_categories.each do |category|
      if category.flexible_criterion_id.nil?
        categories_data[category.annotation_category_name] = category.annotation_texts.pluck(:content)
      else
        categories_data[category.annotation_category_name] = {
          'criterion' => category.flexible_criterion.name,
          'texts' => category.annotation_texts.pluck(:content, :deduction)
        }
      end
    end
    categories_data.to_yaml
  end
end
