class DueDatePerSectionModification < ActiveRecord::Migration
  def self.up
    change_table :section_due_dates do |t|
      t.remove :assignments_id
      t.remove :sections_id
      t.references :section
      t.references :assignment
    end
    change_table :assignments do |t|
      t.rename :section_due_dates, :section_due_dates_type
    end
  end

  def self.down
    change_table section_due_dates do |t|
      t.remove :section_id
      t.remove :assignment_id
      t.references :sections
      t.references :assignments
    end
    change_table :assignments do |t|
      t.rename :section_due_dates_type, :section_due_dates
    end
  end
end
