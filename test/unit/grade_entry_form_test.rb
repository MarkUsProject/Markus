require File.expand_path(File.join(File.dirname(__FILE__), '..', 'test_helper'))
require File.expand_path(File.join(File.dirname(__FILE__), '..', 'blueprints', 'helper'))
require 'shoulda'
require 'will_paginate'

# Tests for GradeEntryForms
class GradeEntryFormTest < ActiveSupport::TestCase

  # Basic validation tests
  should have_many :grade_entry_items
  should have_many :grade_entry_students
  should have_many :grades
  should validate_presence_of :short_identifier


  # Dates in the past should also be allowed
  should allow_value(1.day.ago).for(:date)
  should allow_value(1.day.from_now).for(:date)
  should_not allow_value('100-10').for(:date)
  should_not allow_value('abcd').for(:date)

  context ' A good Grade entry model' do
    setup do
      GradeEntryForm.make
    end

    should validate_uniqueness_of(
        :short_identifier).with_message(
            I18n.t('grade_entry_forms.invalid_identifier'))
  end

  # Make sure validate works appropriately when the date is valid
  def test_validate_valid_date
    g = GradeEntryForm.new(:short_identifier => 'T1', :date => 1.day.from_now)
    assert g.valid?
  end

  # Make sure validate works appropriately when the date is invalid
  def test_validate_invalid_date
    g = GradeEntryForm.new(:short_identifier => 'T1', :date => '2009-')
    assert !g.valid?
  end

  # Make sure that validate allows dates to be set in the past
  def test_validate_date_in_the_past
    g = GradeEntryForm.new(:short_identifier => 'T1', :date => 1.day.ago)
    assert g.valid?
  end

  # Tests for out_of_total
  context 'A grade entry form object: ' do
    setup do
      @grade_entry_form = GradeEntryForm.make
      @grade_entry_form.grade_entry_items.make(:out_of => 25, :position => 1)
      @grade_entry_form.grade_entry_items.make(:out_of => 50, :position => 2)
      @grade_entry_form.grade_entry_items.make(:out_of => 10.5, :position => 3)
    end

    # Need at least one GradeEntryForm object created for this
    # test to pass.
    should validate_uniqueness_of(:short_identifier).with_message(I18n.t('grade_entry_forms.invalid_identifier'))

    should 'verify that the total number of marks is calculated correctly' do
      assert_equal(85.5, @grade_entry_form.out_of_total)
    end
  end

  # Tests for calculate_total_mark
  context 'Calculate the total mark for a student: ' do
    setup do
      @grade_entry_form = make_grade_entry_form_with_multiple_grade_entry_items
      @grade_entry_items = @grade_entry_form.grade_entry_items
      @grade_entry_student_with_some_grades = @grade_entry_form.grade_entry_students.make
      @grade_entry_student_with_some_grades.grades.make(:grade_entry_item => @grade_entry_items[0],
                                                        :grade => 0.4)
      @grade_entry_student_with_some_grades.grades.make(:grade_entry_item => @grade_entry_items[1],
                                                        :grade => 0.3)
    end

    should 'verify the correct value is returned when the student has grades for none of the questions' do
      grade_entry_student_with_no_grades = @grade_entry_form.grade_entry_students.make
      assert_equal(nil, grade_entry_student_with_no_grades.update_total_grade)
    end

    should 'verify the correct value is returned when the student has zero for all of the questions' do
      grade_entry_student_with_all_zeros = @grade_entry_form.grade_entry_students.make
      @grade_entry_items.each do |grade_entry_item|
        grade_entry_student_with_all_zeros.grades.make(:grade_entry_item => grade_entry_item)
      end

      assert_equal(0.0, grade_entry_student_with_all_zeros.update_total_grade)
    end

    should 'verify the correct value is returned when the student has grades for some of the questions' do
      assert_equal(0.7, @grade_entry_student_with_some_grades.update_total_grade)
    end

    should 'when the student has grades for all of the questions' do
      @grade_entry_student_with_some_grades.grades.make(:grade_entry_item => @grade_entry_items[2],
                                                        :grade => 60.5)
      assert_equal(61.2, @grade_entry_student_with_some_grades.update_total_grade)
    end
  end

  # Tests for calculate_total_percent
  context 'Calculate the total percent for a student: ' do
    setup do
      @grade_entry_form = make_grade_entry_form_with_multiple_grade_entry_items
      @grade_entry_items = @grade_entry_form.grade_entry_items
      @grade_entry_student_with_some_grades = @grade_entry_form.grade_entry_students.make
      @grade_entry_student_with_some_grades.grades.make(:grade_entry_item => @grade_entry_items[0],
                                                        :grade => 3)
      @grade_entry_student_with_some_grades.grades.make(:grade_entry_item => @grade_entry_items[1],
                                                        :grade => 7)
    end

    should 'verify the correct percentage is returned when the student has grades for none of the questions' do
      grade_entry_student_with_no_grades = @grade_entry_form.grade_entry_students.make
      assert_equal('', @grade_entry_form.calculate_total_percent(grade_entry_student_with_no_grades))
    end

    should 'verify the correct percentage is returned when the student has zero for all of the questions' do
      grade_entry_student_with_all_zeros = @grade_entry_form.grade_entry_students.make
      @grade_entry_items.each do |grade_entry_item|
        grade_entry_student_with_all_zeros.grades.make(:grade_entry_item => grade_entry_item)
      end

      assert_equal(0, @grade_entry_form.calculate_total_percent(grade_entry_student_with_all_zeros))
    end

    should 'verify the correct percentage is returned when the student has grades for some of the questions' do
      assert_equal(33.33, @grade_entry_form.calculate_total_percent(@grade_entry_student_with_some_grades).round(2))
    end

    should 'verify the correct percentage is returned when the student has grades for all of the questions' do
      @grade_entry_student_with_some_grades.grades.make(:grade_entry_item => @grade_entry_items[2],
                                                        :grade => 8)
      assert_equal(60.00, @grade_entry_form.calculate_total_percent(@grade_entry_student_with_some_grades))
    end
  end

  # Tests for all_blank_grades
  context "Determine whether or not a student's grades are all blank: " do
    setup do
      @grade_entry_form = make_grade_entry_form_with_multiple_grade_entry_items
      @grade_entry_items = @grade_entry_form.grade_entry_items
      @grade_entry_student_with_some_grades = @grade_entry_form.grade_entry_students.make
      @grade_entry_student_with_some_grades.grades.make(:grade_entry_item => @grade_entry_items[0],
                                                        :grade => 3)
      @grade_entry_student_with_some_grades.grades.make(:grade_entry_item => @grade_entry_items[1],
                                                        :grade => 7)
    end

    should 'verify the correct value is returned when the student has grades for none of the questions' do
      student_with_no_grades = @grade_entry_form.grade_entry_students.make
      assert_equal(true, student_with_no_grades.all_blank_grades?)
    end

    should 'verify the correct value is returned when the student has grades for some of the questions' do
      assert_equal(false, @grade_entry_student_with_some_grades.all_blank_grades?)
    end

    should 'verify the correct value is returned when the student has grades for all of the questions' do
      @grade_entry_student_with_some_grades.grades.make(:grade_entry_item => @grade_entry_items[2],
                                                        :grade => 8)
      assert_equal(false, @grade_entry_student_with_some_grades.all_blank_grades?)
    end
  end

  # Tests for calculate_released_average
  context 'Calculate the average of the released marks: ' do
    setup do
      @grade_entry_form = make_grade_entry_form_with_multiple_grade_entry_items
      @grade_entry_form_none_released = make_grade_entry_form_with_multiple_grade_entry_items
      @grade_entry_items = @grade_entry_form.grade_entry_items

      # Set up 5 GradeEntryStudents
      (0..4).each do |i|
        grade_entry_student = @grade_entry_form.grade_entry_students.make
        # Give the student a grade for all three questions for the grade entry form
        (0..2).each do |j|
          grade_entry_student.grades.make(:grade_entry_item => @grade_entry_items[j],
                                          :grade => 5 + i + j)
        end

        # The marks will be released for 3 out of the 5 students
        if i <= 2
          grade_entry_student.released_to_student = true
        else
          grade_entry_student.released_to_student = false
        end
        grade_entry_student.save
      end
    end

    should 'verify the correct value is returned when there are no marks released' do
      assert_equal(0, @grade_entry_form_none_released.calculate_released_average())
    end

    should 'verify the correct value is returned when multiple marks have been released and there are no blank marks' do
      assert_equal(70.00, @grade_entry_form.calculate_released_average())
    end

    should 'verify the correct value is returned when multiple marks have been released and there are blank marks' do
      # Blank marks for students
      (0..2).each do
        grade_entry_student = @grade_entry_form.grade_entry_students.make(:released_to_student => true)
      end

      assert_equal(70.00, @grade_entry_form.calculate_released_average())
    end
  end

  # Tests for construct_alpha_category
  context 'Construct alphabetical category: ' do
    setup do
      @grade_entry_form = GradeEntryForm.make
      @alpha_categories = Array.new(4){[]}
    end

    should 'construct the correct category when the first name is shorter than the last one' do
      @alpha_categories = @grade_entry_form.construct_alpha_category('Berio', 'Bernstein', @alpha_categories, 0)
      assert_equal(%w(Beri), @alpha_categories[0])
      assert_equal(%w(Bern), @alpha_categories[1])
    end

    should 'construct the correct category when the first name is longer than the last one' do
      @alpha_categories = @grade_entry_form.construct_alpha_category('Brown', 'Chan', @alpha_categories, 0)
      assert_equal(%w(B), @alpha_categories[0])
      assert_equal(%w(C), @alpha_categories[1])
    end

    should 'construct the correct category when the first name is the same length as the last one' do
      @alpha_categories = @grade_entry_form.construct_alpha_category('Bliss', 'Brown', @alpha_categories, 0)
      assert_equal(%w(Bl), @alpha_categories[0])
      assert_equal(%w(Br), @alpha_categories[1])
    end

    should 'construct the correct category when the first name is identical to the last one' do
      @alpha_categories = @grade_entry_form.construct_alpha_category('Smith', 'Smith', @alpha_categories, 0)
      assert_equal(%w(Smith), @alpha_categories[0])
      assert_equal(%w(Smith), @alpha_categories[1])
    end
  end

  # Tests for the alpha_paginate algorithm
  context 'Construct alphabetical categories: ' do
      setup do
        @grade_entry_form = GradeEntryForm.make
        @students = []

        last_names = %w(Albert Alwyn Auric Berio Bliss Bridge Britten Cage
                        Dukas Duparc Egge Feldman)

        (0..11).each do |i|
          student = Student.new(:user_name => 's' + i.to_s, :last_name => last_names[i], :first_name => 'Bob')
          student.save
          @students << student
        end
      end

      should 'be able to handle the case where there are 0 pages without errors' do
        alpha_pagination_students = @grade_entry_form.alpha_paginate(@students, 12, 0);
        assert_equal(alpha_pagination_students, [])
      end

      should 'construct the appropriate categories for alphabetical pagination when there is 1 page' do
        alpha_pagination_students = @grade_entry_form.alpha_paginate(@students, 12, 1);
        assert_equal('A-F', alpha_pagination_students[0])
      end

      should 'construct the appropriate categories for alphabetical pagination when there are multiple pages' do
        alpha_pagination_students = @grade_entry_form.alpha_paginate(@students, 3, 4);
        assert_equal('Al-Au', alpha_pagination_students[0])
        assert_equal('Be-Brid', alpha_pagination_students[1])
        assert_equal('Brit-Duk', alpha_pagination_students[2])
        assert_equal('Dup-F', alpha_pagination_students[3])
      end

      should 'construct the appropriate categories for alphabetical pagination when the last page has 1 student on it' do
        student = Student.new(:user_name => 's12', :last_name => 'Harris', :first_name => 'Bob')
        student.save
        @students << student

        alpha_pagination_students = @grade_entry_form.alpha_paginate(@students, 4, 4)
        assert_equal('A-Be', alpha_pagination_students[0])
        assert_equal('Bl-C', alpha_pagination_students[1])
        assert_equal('D-F', alpha_pagination_students[2])
        assert_equal('Harris-Harris', alpha_pagination_students[3])
      end
  end

end
