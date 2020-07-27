class AddMailSettingsToUsers < ActiveRecord::Migration[6.0]
  def change
    add_column :users,
               :receives_results_emails,
               :boolean,
               default: false,
               null: false

    add_column :users,
               :receives_invite_emails,
               :boolean,
               default: false,
               null: false
  end
end
