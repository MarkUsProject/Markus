json.array!(@peer_reviews) do |peer_review|
  json.extract! peer_review, :id, :reviewier_id, :reviewee_id, :result_id
  json.url peer_review_url(peer_review, format: :json)
end
