require 'spec_helper'

RSpec.describe 'criteria/update_positions.js.erb', type: :view do
  it 'infers the controller path' do
    expect(controller.request.path_parameters[:controller]).to eq('criteria')
    expect(controller.request.path_parameters[:action]).to eq('update_positions')
  end
end
