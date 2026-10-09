# The messages of the log entries that MarkUs writes. The details of each entry (such as the ids of the records
# involved) are in its payload, so that every entry of the same kind has the same message.
module Logging
  module Messages
    # Users
    USER_AUTHENTICATED = 'User authenticated'.freeze
    USER_AUTHENTICATION_FAILED = 'User authentication failed'.freeze
    USER_LOGGED_OUT = 'User logged out'.freeze
    ROLE_SWITCH_STARTED = 'Role switch started'.freeze
    ROLE_SWITCH_ENDED = 'Role switch ended'.freeze

    # Grading
    VIEWED_SUBMISSION = 'Viewed submission'.freeze
    VIEWED_RESULTS = 'Viewed results'.freeze
    MARK_UPDATED = 'Mark updated'.freeze
    MARK_UPDATE_FAILED = 'Mark update failed'.freeze
    MARKS_RELEASED = 'Marks released'.freeze
    MARKS_UNRELEASED = 'Marks unreleased'.freeze
    TEST_RESULTS_PROCESSING_FAILED = 'Test results processing failed'.freeze

    # Groups
    GROUP_CREATED = 'Group created'.freeze
    GROUP_CREATION_FAILED = 'Group creation failed'.freeze
    GROUPING_CREATION_FAILED = 'Grouping creation failed'.freeze
    GROUP_DELETED = 'Group deleted'.freeze
    GROUP_DELETION_FAILED = 'Group deletion failed'.freeze
    ACCEPTED_GROUP_INVITATION = 'Accepted group invitation'.freeze
    DECLINED_GROUP_INVITATION = 'Declined group invitation'.freeze
    CANCELLED_GROUP_INVITATION = 'Cancelled group invitation'.freeze
    FINISHED_CREATING_GROUPS = 'Finished creating groups'.freeze

    # Repositories
    REPOSITORY_CREATION_FAILED = 'Repository creation failed'.freeze
    REPOSITORY_ACCESS_FAILED = 'Repository access failed'.freeze
    RECLONED_REPOSITORY = 'Recloned repository'.freeze
    REPOSITORY_RECLONE_FAILED = 'Repository reclone failed'.freeze

    # Submissions
    COLLECTING_SUBMISSION = 'Collecting submission'.freeze
    FINISHED_COLLECTING_SUBMISSIONS = 'Finished collecting submissions'.freeze

    # Exam templates
    GENERATING_EXAM_COPY = 'Generating exam copy'.freeze
    FINISHED_GENERATING_EXAM_COPIES = 'Finished generating exam copies'.freeze
    SCANNED_EXAM_PAGE = 'Scanned exam page'.freeze
    FINISHED_SPLITTING_SCANNED_EXAMS = 'Finished splitting scanned exams'.freeze
  end
end
