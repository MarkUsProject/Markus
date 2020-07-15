class StarterCodeEntry < ApplicationRecord
  belongs_to :starter_code_group
  validate :entry_exists

  def full_path
    starter_code_group.path + path
  end

  private

  def entry_exists
    errors.add(:base, 'entry does not exist') unless File.exist?(full_path)
  end
end
