require File.join(File.dirname(__FILE__),'blueprints')

def make_grade_entry_form_with_multiple_grade_entry_items
  grade_entry_form = GradeEntryForm.make
  (1..3).each do |i|
    grade_entry_item = GradeEntryItem.make(grade_entry_form: grade_entry_form,
                                           out_of: 10,
                                           name: 'Q' + i.to_s,
                                           position: i)
  end
  return grade_entry_form
end
