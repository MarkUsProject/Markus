class TestResultsContract < Dry::Validation::Contract
  json do
    required(:error).maybe(:string)
    required(:status).filled(:string)
    
    required(:test_groups).array(:hash) do
      required(:time).maybe(:integer)
      required(:tests).array(:hash) do
        required(:name).filled(:string)
        required(:time).maybe(:integer)
        required(:output).value(:string)
        required(:status).filled(:string)
        required(:marks_total).filled(:integer)
        required(:marks_earned).filled(:integer)
        optional(:extra_properties).value(:hash)
      end
      required(:extra_info).maybe(:hash) do
        required(:name).filled(:string)
        required(:criterion).filled(:string)
        required(:test_group_id).filled(:integer)
        required(:display_output).filled(:string)
      end

    end
  end
end