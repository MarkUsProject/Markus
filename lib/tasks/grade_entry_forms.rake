namespace :db do

  task grade_entry_forms: :environment do
    puts 'Marks Spreadsheet 1: Marks Spreadsheet Visible'
    grade_entry_form = GradeEntryForm.create(
      short_identifier: "Q1",
      description: "Class Quiz",
      message: "Class quiz on conditional statements",
      date: 1.minute.from_now,
      is_hidden: true
    )

    grade_entry_form.grade_entry_items << GradeEntryItem.create({name: "Q1", out_of: 3, position: 1})
    grade_entry_form.grade_entry_items << GradeEntryItem.create({name: "Q2", out_of: 4, position: 2})
    grade_entry_form.grade_entry_items << GradeEntryItem.create({name: "Q3", out_of: 5, position: 3})
    grade_entry_form.save





  end

end
