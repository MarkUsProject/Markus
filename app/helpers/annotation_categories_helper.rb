module AnnotationCategoriesHelper

  def prepare_for_conversion(annotation_categories)
    result = {}
    annotation_categories.each do |annotation_category|
      if annotation_category.flexible_criterion.nil?
        annotation_texts = [nil]
        annotation_texts += annotation_category.annotation_texts.pluck(:content)
        result[annotation_category.annotation_category_name] = annotation_texts
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
        annotation_texts = category.annotation_texts.pluck(:content)
        categories_data[category.annotation_category_name] = annotation_texts
      else
        info = { 'criterion' => category.flexible_criterion.name }
        text_info = []
        text_info += category.annotation_texts.pluck(:content, :deduction)
        info['texts'] = text_info
        categories_data[category.annotation_category_name] = info
      end
    end
    categories_data.ya2yaml
  end
end
