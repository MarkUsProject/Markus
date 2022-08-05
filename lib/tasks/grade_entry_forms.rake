namespace :db do
  task grade_entry_forms: :environment do
    puts 'Marks Spreadsheet 1: Marks Spreadsheet Visible with Marks'
    grade_entry_form = GradeEntryForm.create(
      course: Course.first,
      short_identifier: 'Quiz1',
      description: 'Class Quiz on Variables',
      message: 'Class quiz on variables',
      due_date: 1.minute.from_now,
      is_hidden: false
    )

    grade_entry_form.grade_entry_items << GradeEntryItem.new(
      name: 'Q1', out_of: 3, position: 1
    )
    grade_entry_form.grade_entry_items << GradeEntryItem.new(
      name: 'Q2', out_of: 4, position: 2
    )
    grade_entry_form.grade_entry_items << GradeEntryItem.new(
      name: 'Q3', out_of: 5, position: 3
    )
    grade_entry_form.grade_entry_items.each { |item| item.save validate: false }
    grade_entry_form.save validate: false

    puts 'Marks Spreadsheet 2: Marks Spreadsheet Hidden'
    grade_entry_form = GradeEntryForm.create(
      course: Course.first,
      short_identifier: 'Quiz2',
      description: 'Class Quiz on Conditionals',
      message: 'Class quiz on conditional statements',
      due_date: 2.months.from_now,
      is_hidden: true
    )

    grade_entry_form.grade_entry_items << GradeEntryItem.new(
      name: 'Q1', out_of: 6, position: 1
    )
    grade_entry_form.grade_entry_items << GradeEntryItem.new(
      name: 'Q2', out_of: 7, position: 2
    )
    grade_entry_form.grade_entry_items << GradeEntryItem.new(
      name: 'Q3', out_of: 8, position: 3
    )
    grade_entry_form.grade_entry_items.each { |item| item.save validate: false }
    grade_entry_form.save validate: false
  end
end
