require File.expand_path(File.join(File.dirname(__FILE__), '..', 'test_helper'))
require File.expand_path(File.join(File.dirname(__FILE__), '..', 'blueprints', 'blueprints'))
require File.expand_path(File.join(File.dirname(__FILE__), '..', 'blueprints', 'helper'))
require 'shoulda'
require 'mocha'


#IMPORTANT NOTE to anyone modifying these tests. It is highly recommended
#that any tests of methods that implicitly call the start_collection_process
#method have the line:
#
#@submission_collector.stubs(:start_collection_process)
#
#in them to intercept the call to start_collection_process. The reason for this
#is that start_collection_process forks off a child, that could potentially
#do unwanted things if you dont know what you're doing.
class SubmissionCollectorTest < ActiveSupport::TestCase

  should validate_numericality_of :child_pid

  def setup_collector
    @submission_collector = SubmissionCollector.instance
    @submission_collector.init_queues
    @priority_queue = @submission_collector.grouping_queues.find_by_priority_queue(true).groupings
    @regular_queue = @submission_collector.grouping_queues.find_by_priority_queue(false).groupings
    @groupings = []
    (1..10).each do |i|
      @groupings.push(Grouping.make)
    end
  end

  context "A submission_collector calling its push_groupings_to_queue" do

    context "when both priority and regular queues are empty" do
      setup do
        setup_collector
        @submission_collector.stubs(:start_collection_process)
        @submission_collector.push_groupings_to_queue(@groupings)
      end

      should "push all groupings to the regular queue" do
        assert_equal @groupings, (@regular_queue).sort { |x,y| x.id <=> y.id}
        assert @priority_queue.empty?
        @groupings.each do |grouping| assert !grouping.is_collected? end
      end
    end

    context "with part of the groupings to be pushed already existing in the
    regular queue" do

      context "and none in the priority_queue" do
        setup do
          setup_collector
          @regular_queue.push(@groupings[0])
          @regular_queue.push(@groupings[1])
          @submission_collector.stubs(:start_collection_process)
          @submission_collector.push_groupings_to_queue(@groupings)
        end

        should "only push the groupings that were missing" do
          assert_equal @groupings, (@regular_queue).sort { |x,y| x.id <=> y.id}
          assert @priority_queue.empty?
          @groupings.slice(2..9).each do |grouping| assert !grouping.is_collected? end
        end
      end

      context "and some in the priority_queue" do
        setup do
          setup_collector
          @regular_queue.push(@groupings[0])
          @priority_queue.push(@groupings[8])
          @priority_queue.push(@groupings[9])
          @submission_collector.stubs(:start_collection_process)
          @submission_collector.push_groupings_to_queue(@groupings)
        end

        should "only push the groupings that were in neither queue" do
          assert_equal @groupings.slice(0..7), @regular_queue.sort { |x,y| x.id <=> y.id}
          assert_equal @groupings.slice(8..9), @priority_queue.sort { |x,y| x.id <=> y.id}
          @groupings.slice(1..7).each do |grouping| assert !grouping.is_collected? end
        end
      end
    end
  end

  context "A submission_collector pushing a grouping to the priority queue" do

    context "with both regular and priority queues empty" do
      setup do
        setup_collector
        @submission_collector.stubs(:start_collection_process)
        @submission_collector.push_grouping_to_priority_queue(@groupings.first)
      end

      should "add that grouping to the priority queue" do
        assert_equal [@groupings.first], @priority_queue.sort { |x,y| x.id <=> y.id}
        assert @regular_queue.empty?
        @groupings.each do |grouping| assert !grouping.is_collected? end
      end
    end

    context "with neither regular or priority queues empty or containing the
    grouping" do
      setup do
        setup_collector
        @groupings.slice(0..4).each do |grouping| @regular_queue.push(grouping) end
        @groupings.slice(5..8).each do |grouping| @priority_queue.push(grouping) end
        @submission_collector.stubs(:start_collection_process)
        @submission_collector.push_grouping_to_priority_queue(@groupings[9])
      end

      should "add that grouping to the priority queue" do
        assert_equal @groupings.slice(5..9), @priority_queue.sort { |x,y| x.id <=> y.id}
        assert_equal @groupings.slice(0..4), @regular_queue.sort { |x,y| x.id <=> y.id}
        assert !@groupings[9].is_collected?
      end
    end

    context "when the grouping is already in" do
      context "the priority queue" do
        setup do
          setup_collector
          @priority_queue.push(@groupings.first)
          @submission_collector.stubs(:start_collection_process)
          @submission_collector.push_grouping_to_priority_queue(@groupings.first)
        end

        should "do nothing" do
          assert_equal [@groupings.first], @priority_queue
          assert @regular_queue.empty?
        end
      end

      context "the regular queue" do
        setup do
          setup_collector
          @regular_queue.push(@groupings.first)
          @submission_collector.stubs(:start_collection_process)
          @submission_collector.push_grouping_to_priority_queue(@groupings.first)
        end

        should "move it from regular to priority queue" do
          assert_equal [@groupings.first], @priority_queue
          assert @regular_queue.empty?
          assert !@groupings.first.is_collected?
        end
      end
    end
  end

  context "Calling the submission collector's remove_grouping_form_queue
  method" do

    context "when the grouping doesn't belong to any queue" do
      setup do
        setup_collector
      end

      should "return nil and modify nothing" do
        assert_nil @submission_collector.remove_grouping_from_queue(@groupings[0])
        assert @regular_queue.empty?
        assert @priority_queue.empty?
      end
    end

    context "when the grouping belongs to the regular queue" do
      setup do
        setup_collector
        @submission_collector.stubs(:start_collection_process)
        @submission_collector.push_groupings_to_queue(@groupings.slice(0..4))
        @submission_collector.push_grouping_to_priority_queue(@groupings[5])
        @submission_collector.remove_grouping_from_queue(@groupings[4])
      end

      should "remove the grouping from the regular queue" do
        assert_nil @groupings[4].grouping_queue
        assert_equal @groupings.slice(0..3), @regular_queue.sort { |x,y| x.id <=> y.id}
        assert_equal [@groupings[5]], @priority_queue
      end
    end

    context "when the grouping belongs to the priority queue" do
      setup do
        setup_collector
        @submission_collector.stubs(:start_collection_process)
        @submission_collector.push_groupings_to_queue(@groupings.slice(0..4))
        @submission_collector.push_grouping_to_priority_queue(@groupings[5])
        @submission_collector.push_grouping_to_priority_queue(@groupings[6])
        @submission_collector.remove_grouping_from_queue(@groupings[5])
      end

      should "remove the grouping from the priority queue" do
        assert_nil @groupings[5].grouping_queue
        assert_equal @groupings.slice(0..4), @regular_queue.sort { |x,y| x.id <=> y.id}
        assert_equal [@groupings[6]], @priority_queue
      end
    end
  end

  context "Calling the submission collector's get_next_grouping_for_collection
  method" do

    context "when both priority and regular queues are empty" do
      setup do
        setup_collector
      end

      should "return nil" do
        assert_nil @submission_collector.get_next_grouping_for_collection
        assert @regular_queue.empty?
        assert @priority_queue.empty?
      end
    end

    context "when the priority queue is empty but the regular isn't" do
      setup do
        setup_collector
        @submission_collector.stubs(:start_collection_process)
        #puts @groupings.slice(0..4).inspect
        @submission_collector.push_groupings_to_queue(@groupings.slice(0..4))
      end

      should "return the first grouping of the regular queue" do
        assert_equal @groupings[0],
          @submission_collector.get_next_grouping_for_collection
        assert_equal @groupings.slice(0..4), @regular_queue.sort { |x,y| x.id <=> y.id}
        assert @priority_queue.empty?
      end
    end

    context "when neither the priority nor the regular queues are empty" do
      setup do
        setup_collector
        @submission_collector.stubs(:start_collection_process)
        @submission_collector.push_groupings_to_queue(@groupings.slice(0..4))
        @submission_collector.push_grouping_to_priority_queue(@groupings[5])
        @submission_collector.push_grouping_to_priority_queue(@groupings[6])
      end

      should "return the first grouping of the priority queue" do
        assert_equal @groupings[5],
          @submission_collector.get_next_grouping_for_collection
        assert_equal @groupings.slice(0..4), @regular_queue.sort { |x,y| x.id <=> y.id}
        assert_equal @groupings.slice(5..6), @priority_queue.sort { |x,y| x.id <=> y.id}
      end
    end
  end

  context "Calling the submission collector's collect_next_submission method" do

    context "when both priority and regular queues are empty" do
      setup do
        setup_collector
        @submission_collector.stubs(:start_collection_process)
      end

      should "return nil" do
        assert_nil @submission_collector.collect_next_submission
        assert @regular_queue.empty?
        assert @priority_queue.empty?
      end
    end

    context "when there is a submission to collect" do
      setup do
        setup_collector
        @submission_collector.stubs(:start_collection_process)
        @submission_collector.expects(:get_next_grouping_for_collection).returns(@groupings[5])
        @submission_collector.push_groupings_to_queue(@groupings.slice(0..4))
        @submission_collector.push_grouping_to_priority_queue(@groupings[5])
        @submission_collector.collect_next_submission
      end

      should "collect that submission and remove it from the queue" do
        assert @groupings[5].is_collected?
        assert_nil @groupings[5].grouping_queue
        assert_equal @groupings.slice(0..4), @regular_queue.sort { |x,y| x.id <=> y.id}
        assert @priority_queue.empty?
      end
    end
  end
end
