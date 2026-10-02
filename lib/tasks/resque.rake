# To create resque workers
require 'resque/tasks'
task 'resque:setup' => :environment do
  # Resque performs each job in a forked process that exits without running at_exit hooks, so Semantic Logger
  # would not get a chance to write the log entries that are still queued. Write each log entry immediately instead.
  SemanticLogger.sync!
  # Also write logs to standard output if the environment declares server appenders (as development does)
  RailsSemanticLogger.add_server_appenders
end
