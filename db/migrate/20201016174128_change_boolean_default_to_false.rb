class ChangeBooleanDefaultToFalse < ActiveRecord::Migration[6.0]
  def change
    # line 52
    change_column :annotations, :is_remark, :boolean,
                  :null => false, :default => false
    # line 234
    change_column :grade_entry_items, :bonus, :boolean,
                  :null => false, :default => false
    # line 241
    change_column :grade_entry_students, :released_to_student, :boolean,
                  :null => false, :default => false
    # line 283
    change_column :groupings, :is_collected, :boolean,
                  :null => false, :default => false
    # line 463
    change_column :split_pdf_logs, :qr_code_found, :boolean,
                  :null => false, :default => false
    # line 489
    change_column :submission_files, :is_converted, :boolean,
                  :null => false, :default => false
    # line 490
    change_column :submission_files, :error_converting,
                  :boolean, :null => false, :default => false
    # line 507
    change_column :submissions, :submission_version_used,
                  :boolean, :null => false, :default => false
  end
end
