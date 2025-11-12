class TestResultsContract < Dry::Validation::Contract
  params do
    required(:error).maybe(:string)
    required(:status).filled(:string)

    required(:test_groups).array(:hash) do
      required(:time).maybe(:integer)
      optional(:timeout).maybe(:integer)
      optional(:stderr).maybe(:string)
      optional(:malformed).maybe(:string)

      required(:tests).array(:hash) do
        required(:name).filled(:string)
        required(:time).maybe(:integer)
        required(:output).value(:string)
        required(:status).filled(:string)
        required(:marks_total).filled(:integer)
        required(:marks_earned).filled(:integer)
      end

      required(:extra_info).maybe(:hash) do
        required(:name).filled(:string)
        optional(:criterion).maybe(:string)
        required(:test_group_id).filled(:integer)
        required(:display_output).value(:integer)
      end

      optional(:annotations).array(:hash) do
        required(:content).filled(:string)
        required(:filename).filled(:string)
        optional(:type).filled(:string)
        optional(:line_start).maybe(:integer)
        optional(:line_end).maybe(:integer)
        optional(:column_start).maybe(:integer)
        optional(:column_end).maybe(:integer)
        optional(:x1).maybe(:integer)
        optional(:x2).maybe(:integer)
        optional(:y1).maybe(:integer)
        optional(:y2).maybe(:integer)
        optional(:start_node).maybe(:string)
        optional(:start_offset).maybe(:integer)
        optional(:end_node).maybe(:string)
        optional(:end_offset).maybe(:integer)
      end

      optional(:feedback).array(:hash) do
        required(:filename).filled(:string)
        required(:mime_type).filled(:string)
        required(:content).filled(:string)
        optional(:compression).filled(:string)
      end

      optional(:tags).array(:hash) do
        required(:name).filled(:string)
        optional(:description).maybe(:string)
      end

      optional(:overall_comment).maybe(:string)
      optional(:extra_marks).array(:hash) do
        required(:unit).filled(:string)
        required(:mark).filled(:integer)
        required(:description).filled(:string)
      end
    end
  end
end
