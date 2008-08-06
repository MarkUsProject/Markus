class AssignmentsController < ApplicationController
  
  def edit
  end
  
  def new
    @title = "Create a New Assignment"
    @assignment = Assignment.new
    @assignment.assignment_files.build  # create one file
  end
  
  # Adds another file text field for this assignment
  def add_file
    @file = AssignmentFile.new
  end

  def create
  end

end
