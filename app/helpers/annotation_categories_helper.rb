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

  def annotation_categories_to_yml(annotation_categories)
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

  def upload_annotations_from_yaml(file_content, assignment)
    successes = 0
    file_content.each do |category, category_data|
      if category_data.is_a?(Array)
        AnnotationCategory.add_by_row([category, nil] + category_data, assignment, current_role)
        successes += 1
      elsif category_data.is_a?(Hash)
        row = [category, category_data['criterion']] + category_data['texts'].flatten
        AnnotationCategory.add_by_row(row, assignment, current_role)
        successes += 1
      end
    end
    successes
  end
end
