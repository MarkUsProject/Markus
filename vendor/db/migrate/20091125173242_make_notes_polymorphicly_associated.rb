class MakeNotesPolymorphiclyAssociated < ActiveRecord::Migration
  def self.up
    change_table :notes do |t|
      t.remove :grouping_id, :type_association
      t.references :noteable, :polymorphic => true, :null => false
    end
  end

  def self.down
    change_table :notes do |t|
      t.remove :noteable_id, :noteable_type
      t.integer :grouping_id, :null => false
      t.text :type_association, :null => false
    end
  end
end
