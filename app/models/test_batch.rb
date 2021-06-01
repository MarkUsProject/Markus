class TestBatch < ApplicationRecord
  has_many :test_runs, dependent: :nullify
end
