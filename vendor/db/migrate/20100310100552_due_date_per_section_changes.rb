class DueDatePerSectionChanges < ActiveRecord::Migration
  def self.up
    create_table :section_due_dates do |t|
      t.references :sections
      t.references :assignments
      t.datetime :due_date
    end

    change_table :assignments do |t|
      t.boolean :section_due_dates, :default => false
    end
  end

  def self.down
    drop_table :section_due_dates
    remove_column :assignments, :section_due_dates
  end
end
