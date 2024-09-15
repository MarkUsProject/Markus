require "test_helper"

class RerunSnippetTest < PARENT_TEST_CASE
  context "A Rails application with shoulda-context added to it" do
    should "display the correct rerun snippet when a test fails" do
      if app.rails_version >= 5 && TEST_FRAMEWORK == "minitest"
        app.create

        app.write_file("test/models/failing_test.rb", <<~RUBY)
          ENV["RAILS_ENV"] = "test"
          require_relative "../../config/environment"

          class FailingTest < #{PARENT_TEST_CASE}
            class FakeMatcher
              attr_reader :subject
              attr_accessor :fail

              def description
                "be a fake matcher"
              end

              def matches?(subject)
                @subject = subject
                !@fail
              end

              def failure_message
                "positive failure message"
              end

              def failure_message_when_negated
                "negative failure message"
              end
            end

            should "fail" do
              assert false
            end

            should_not FakeMatcher.new.tap { |m| m.fail = false }
            should FakeMatcher.new.tap { |m| m.fail = true }
          end
        RUBY

        command_runner = app.run_n_unit_test_suite

        expected_executable = rails_version >= 6 ? "rails test" : "bin/rails test"

        assert_includes(command_runner.output, "#{expected_executable} test/models/failing_test.rb:27")
        assert_includes(command_runner.output, "#{expected_executable} test/models/failing_test.rb:31")
        assert_includes(command_runner.output, "#{expected_executable} test/models/failing_test.rb:32")
      end
    end
  end

  def app
    @_app ||= RailsApplicationWithShouldaContext.new
  end

  def rails_version
    # TODO: Update snowglobe so that we don't have to do this
    app.send(:bundle).version_of("rails")
  end
end
