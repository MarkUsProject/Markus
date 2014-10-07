require 'spec_helper'

describe FlexibleCriterion do
  let(:assignment_factory_name) { :flexible_assignment }
  let(:criterion_factory_name) { :flexible_criterion }

  it_behaves_like 'a criterion'
end

