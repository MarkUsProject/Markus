class TestRunsChannel < ApplicationCable::Channel
  def subscribed
    stream_for current_user
  end

  private

  def implicit_authorization_target
    current_role
  end

  def authorization_rule
    :run_tests?
  end

  def unsubscribed; end
end
