module ExamTemplatesHelper
  def get_template_divisions_table_info
    template_divisions = @exam_templates[0].template_divisions

    template_divisions.map do |division|
      t = division.attributes
      t
    end
  end
end
