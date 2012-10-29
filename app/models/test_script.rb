class TestScript < ActiveRecord::Base
  has_many :test_results
  has_one :assignment

  validates :seq_num, :presence => true
  validates :script_name, :presence => true
  validates :max_marks, :presence => true
  validates :run_on_submission, :presence => true
  validates :run_on_request, :presence => true
  validates :uses_token, :presence => true
  validates :halts_testing, :presence => true
  validates :display_description, :presence => true
  validates :display_run_status, :presence => true
  validates :display_input, :presence => true
  validates :display_marks_earned, :presence => true
  validates :display_expected_output, :presence => true
  validates :display_actual_output, :presence => true
end
