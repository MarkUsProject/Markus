class ChangeBooleanDefaultToFalse < ActiveRecord::Migration[6.0]
  def change
    change_column :annotations, :is_remark, :boolean,
                  :null => false, :default => false

    change_column :grade_entry_items, :bonus, :boolean,
                  :null => false, :default => false

    change_column :grade_entry_students, :released_to_student, :boolean,
                  :null => false, :default => false

    change_column :groupings, :is_collected, :boolean,
                  :null => false, :default => false

    change_column :split_pdf_logs, :qr_code_found, :boolean,
                  :null => false, :default => false

    change_column :submission_files, :is_converted, :boolean,
                  :null => false, :default => false

    change_column :submission_files, :error_converting,
                  :boolean, :null => false, :default => false

    change_column :submissions, :submission_version_used,
                  :boolean, :null => false, :default => false
  end
end
