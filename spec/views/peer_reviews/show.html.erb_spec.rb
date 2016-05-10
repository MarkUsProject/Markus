require 'rails_helper'

RSpec.describe "peer_reviews/show", type: :view do
  before(:each) do
    @peer_review = assign(:peer_review, PeerReview.create!(
      :reviewier_id => 1,
      :reviewee_id => 2,
      :result_id => 3
    ))
  end

  it "renders attributes in <p>" do
    render
    expect(rendered).to match(/1/)
    expect(rendered).to match(/2/)
    expect(rendered).to match(/3/)
  end
end
