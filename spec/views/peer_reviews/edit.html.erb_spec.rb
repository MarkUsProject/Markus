require 'rails_helper'

RSpec.describe "peer_reviews/edit", type: :view do
  before(:each) do
    @peer_review = assign(:peer_review, PeerReview.create!(
      :reviewer_id => 1,
      :reviewee_id => 1,
      :result_id => 1
    ))
  end

  it "renders the edit peer_review form" do
    render

    assert_select "form[action=?][method=?]", peer_review_path(@peer_review), "post" do

      assert_select "input#peer_review_reviewer_id[name=?]", "peer_review[reviewer_id]"

      assert_select "input#peer_review_reviewee_id[name=?]", "peer_review[reviewee_id]"

      assert_select "input#peer_review_result_id[name=?]", "peer_review[result_id]"
    end
  end
end
