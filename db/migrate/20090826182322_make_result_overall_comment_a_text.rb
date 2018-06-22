class MakeResultOverallCommentAText < ActiveRecord::Migration[4.2]
  def self.up
    change_column :results, :overall_comment, :text
  end

  def self.down
    change_column :results, :overall_comment, :string
  end
end
