class AutotestSetting < ApplicationRecord
  include AutomatedTestsHelper::AutotestApi

  validates :url, presence: true
  before_create :register_autotester

  # Column name used to identify this record if the primary identifier (id) cannot be relied on.
  # For example, when unarchiving courses.
  IDENTIFIER = 'url'.freeze

  private

  def register_autotester
    self.api_key = register(self.url)
    self.schema = get_schema(self)
  end
end
