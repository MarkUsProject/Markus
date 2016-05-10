require 'rails_helper'

RSpec.describe "peer_reviews/index", type: :view do
  before(:each) do
    assign(:peer_reviews, [
      PeerReview.create!(
        :reviewer_id => 1,
        :reviewee_id => 2,
        :result_id => 3
      ),
      PeerReview.create!(
        :reviewer_id => 1,
        :reviewee_id => 2,
        :result_id => 3
      )
    ])
  end

  it "renders a list of peer_reviews" do
    render
    assert_select "tr>td", :text => 1.to_s, :count => 2
    assert_select "tr>td", :text => 2.to_s, :count => 2
    assert_select "tr>td", :text => 3.to_s, :count => 2
  end
end
