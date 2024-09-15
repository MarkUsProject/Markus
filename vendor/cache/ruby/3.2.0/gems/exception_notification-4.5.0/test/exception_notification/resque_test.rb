# frozen_string_literal: true

require 'test_helper'

require 'exception_notification/resque'
require 'resque'
require 'mock_redis'
require 'resque/failure/multiple'
require 'resque/failure/redis'

class ResqueTest < ActiveSupport::TestCase
  setup do
    # Resque.redis=() only supports a String or Redis instance in Resque 1.8
    Resque.instance_variable_set(:@redis, MockRedis.new)

    Resque::Failure::Multiple.classes = [Resque::Failure::Redis, ExceptionNotification::Resque]
    Resque::Failure.backend = Resque::Failure::Multiple

    @worker = Resque::Worker.new(:jobs)
    # Forking causes issues with Mocha's `.expects`
    @worker.cant_fork = true
  end

  test 'count returns the number of failures' do
    Resque::Job.create(:jobs, BadJob)
    @worker.work(0)
    assert_equal 1, ExceptionNotification::Resque.count
  end

  test 'notifies exception when job fails' do
    ExceptionNotifier.expects(:notify_exception).with do |ex, opts|
      ex.is_a?(RuntimeError) &&
        ex.message == 'Bad job!' &&
        opts[:data][:resque][:error_class] == 'RuntimeError' &&
        opts[:data][:resque][:error_message] == 'Bad job!' &&
        opts[:data][:resque][:failed_at].present? &&
        opts[:data][:resque][:payload] == {
          'class' => 'ResqueTest::BadJob',
          'args' => []
        } &&
        opts[:data][:resque][:queue] == :jobs &&
        opts[:data][:resque][:worker].present?
    end

    Resque::Job.create(:jobs, BadJob)
    @worker.work(0)
  end

  class BadJob
    def self.perform
      raise 'Bad job!'
    end
  end
end
