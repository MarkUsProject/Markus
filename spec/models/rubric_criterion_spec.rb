require 'spec_helper'

describe RubricCriterion do
  let(:assignment_factory_name) { :rubric_assignment }
  let(:criterion_factory_name) { :rubric_criterion }

  it_behaves_like 'a criterion'
end
