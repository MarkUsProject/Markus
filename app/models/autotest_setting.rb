# rubocop:disable Layout/LineLength, Lint/RedundantCopDisableDirective
# == Schema Information
#
# Table name: autotest_settings
#
#  id      :bigint           not null, primary key
#  api_key :string           not null
#  schema  :string           not null
#  url     :string           not null
#
# rubocop:enable Layout/LineLength, Lint/RedundantCopDisableDirective
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
