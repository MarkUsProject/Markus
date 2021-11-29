class TestBatch < ApplicationRecord
  has_many :test_runs, dependent: :nullify
  belongs_to :course
end
