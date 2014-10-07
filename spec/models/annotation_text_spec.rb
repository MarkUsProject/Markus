require 'spec_helper'

describe AnnotationText do
  context 'checks relationships' do
    it { is_expected.to belong_to(:annotation_category) }
    it { is_expected.to have_many(:annotations) }
  end
end
