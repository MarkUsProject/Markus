class UserPreference < ActiveRecord::Base

has_one :user_table

def preference_submission_table
end

def preference_grouping_table
end

end

