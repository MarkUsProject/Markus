class AutotestSetting < ApplicationRecord
  include AutomatedTestsHelper::AutotestApi

  validates :url, presence: true
  before_create :register_autotester

  private

  def register_autotester
    self.api_key = register(self.url)
    self.schema = get_schema(self)
  end
end
