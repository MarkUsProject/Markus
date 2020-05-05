class AddMailSettingsToUsers < ActiveRecord::Migration[6.0]
  def change
    add_column :users,
               :receives_results_emails,
               :boolean,
               default: true

    add_column :users,
               :receives_invite_emails,
               :boolean,
               default: true
  end
end
