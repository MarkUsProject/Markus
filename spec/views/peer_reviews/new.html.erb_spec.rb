require 'rails_helper'

RSpec.describe "peer_reviews/new", type: :view do
  before(:each) do
    assign(:peer_review, PeerReview.new(
      :reviewier_id => 1,
      :reviewee_id => 1,
      :result_id => 1
    ))
  end

  it "renders new peer_review form" do
    render

    assert_select "form[action=?][method=?]", peer_reviews_path, "post" do

      assert_select "input#peer_review_reviewier_id[name=?]", "peer_review[reviewier_id]"

      assert_select "input#peer_review_reviewee_id[name=?]", "peer_review[reviewee_id]"

      assert_select "input#peer_review_result_id[name=?]", "peer_review[result_id]"
    end
  end
end
