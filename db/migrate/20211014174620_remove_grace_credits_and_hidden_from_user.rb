class RemoveGraceCreditsAndHiddenFromUser < ActiveRecord::Migration[6.1]
  def change
    remove_column :users, :grace_credits, :integer
    remove_column :users, :hidden, :boolean
    remove_column :users, :section_id, :integer
    remove_column :users, :receives_results_emails, :boolean
    remove_column :users, :receives_invite_emails, :boolean
  end
end
