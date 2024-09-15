# frozen_string_literal: true

# this extension allows ExceptionNotifier to reset all the glocal settings
# (i.e. class vars that otherwise remains during the test)
# please remembeer to call this method each time after you set such settings
# to prevent order dependent test fails.
module ExceptionNotifier
  def self.reset_notifiers!
    @@notifiers = {}
    clear_ignore_conditions!
    ExceptionNotifier.error_grouping = false
    ExceptionNotifier.notification_trigger = nil
  end
end
