class MakeResultOverallCommentAText < ActiveRecord::Migration
  def self.up
    change_column :results, :overall_comment, :text
  end

  def self.down
    change_column :results, :overall_comment, :string
  end
end
