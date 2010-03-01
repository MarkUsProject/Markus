# GradeEntryForm can represent a test, lab, exam, etc.
# A grade entry form has many columns which represent the questions and their total
# marks (i.e. GradeEntryItems) and many rows which represent students and their
# marks on each question (i.e. GradeEntryStudents).
class GradeEntryForm < ActiveRecord::Base
  has_many                  :grade_entry_items, :dependent => :destroy
  has_many                  :grade_entry_students, :dependent => :destroy  
  has_many                  :grades, :through => :grade_entry_items
  
  validates_presence_of     :short_identifier
  validates_uniqueness_of   :short_identifier, :case_sensitive => true
  
  accepts_nested_attributes_for :grade_entry_items, :allow_destroy => true
  
  def validate
    
    # Check that the date is valid - the date is allowed to be in the past
    if Time.zone.parse(date.to_s).nil?
      errors.add :date, I18n.t('grade_entry_forms.invalid_date')
    end
  end
  
  # The total number of marks for this grade entry form
  def out_of_total
    return grade_entry_items.sum('out_of').to_i
  end
  
  # Determine the total mark for a particular student
  def calculate_total_mark(student_id)
    # Differentiate between a blank total mark and a total mark of 0
    total = ""
    
    grade_entry_student = self.grade_entry_students.find_by_user_id(student_id)
    if !grade_entry_student.nil?
      total = grade_entry_student.grades.sum('grade')
    end
    
    return total
  end
   
  # Given two last names, construct an alphabetical category for pagination.
  # eg. If the input is "Albert" and "Auric", return "Al" and "Au".
  def construct_alpha_category(last_name1, last_name2, alpha_categories, i)
    sameSoFar = true
    index = 0
    length_of_shorter_name = [last_name1.length, last_name2.length].min
    
    # Attempt to find the first character that differs
    while sameSoFar && (index < length_of_shorter_name)
      char1 = last_name1[index].chr
      char2 = last_name2[index].chr
      
      sameSoFar = (char1 == char2)
      index += 1
    end
    
    # Form the category name
    if sameSoFar and (index < last_name1.length)
      # There is at least one character remaining in the first name
      alpha_categories[i] << last_name1[0,index+1]
      alpha_categories[i+1] << last_name2[0, index]
    elsif sameSoFar and (index < last_name2.length)
      # There is at least one character remaining in the second name
      alpha_categories[i] << last_name1[0,index]
      alpha_categories[i+1] << last_name2[0, index+1]
    else
      alpha_categories[i] << last_name1[0, index]
      alpha_categories[i+1] << last_name2[0, index]
    end
    
    return alpha_categories
  end
  
  # An algorithm for determining the category names for alphabetical pagination
  def alpha_paginate(all_grade_entry_students, per_page, total_pages)
    alpha_categories = Array.new(2 * total_pages){[]}
    alpha_pagination = []
    
    i = 0
    (1..(total_pages - 1)).each do |page|  
      grade_entry_students1 = all_grade_entry_students.paginate(:per_page => per_page, :page => page)
      grade_entry_students2 = all_grade_entry_students.paginate(:per_page => per_page, :page => page+1)
      
      # To figure out the category names, we need to keep track of the first and last students 
      # on a particular page and the first student on the next page. For example, if these
      # names are "Alwyn, Anderson, and Antheil", the category for this page would be:
      # "Al-And".
      first_student = grade_entry_students1.first.last_name
      last_student = grade_entry_students1.last.last_name
      next_student = grade_entry_students2.first.last_name
      
      # Update the possible categories
      alpha_categories = self.construct_alpha_category(first_student, last_student, 
                                                       alpha_categories, i)
      alpha_categories = self.construct_alpha_category(last_student, next_student, 
                                                       alpha_categories, i+1)
      
      i += 2
    end
    
    # Handle the last page
    page = total_pages
    grade_entry_students = all_grade_entry_students.paginate(:per_page => per_page, :page => page)
    first_student = grade_entry_students.first.last_name
    last_student = grade_entry_students.last.last_name
    
    alpha_categories = self.construct_alpha_category(first_student, last_student, alpha_categories, i)
 
    # We can now form the category names
    j=0
    (1..total_pages).each do |i| 
      alpha_pagination << (alpha_categories[j].max + "-" + alpha_categories[j+1].max)
      j += 2
    end
      
    return alpha_pagination
  end

end
