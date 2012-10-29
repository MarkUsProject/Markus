##############################################################
# This is the model for the database table test_support_files,
# which each instance of this model represents a test support
# file submitted by the admin. It can be an input description
# of a test, an expected output of a test, a code library for
# testing, or any other file to support the test scripts for
# testing. MarkUs does not interpret a test support file.
#
# The columns of test_support_files are:
#   file_name:      name of the support file. 
#   assignment_id:  id of the assignment
#   description:    a brief description of the purpose of the
#                   file.
#############################################################

class TestSupportFile < ActiveRecord::Base
  belongs_to :assignment
  
end
