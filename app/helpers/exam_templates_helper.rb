module ExamTemplatesHelper
  def get_template_divisions_table_info
    template_divisions = @exam_templates[0].template_divisions

    template_divisions.map do |division|
      t = division.attributes
      t[:delete_link] = view_context.link_to(
        'Delete',
        controller: 'exam_templates',
        action: 'destroy_template_division',
        id: division.id)
      t
    end
  end
end
