require File.join(File.dirname(__FILE__), '..', '..', 'test_helper')
require 'shoulda'
include GradeEntryFormsPaginationHelper

class GradeEntryFormsPaginationHelperTest < ActiveSupport::TestCase

# Tests for construct_alpha_category
  context 'Construct alphabetical category: ' do
    setup do
      @alpha_categories = Array.new(4){[]}
    end

    should 'construct the correct category when the first name is shorter than the last one' do
      @alpha_categories = construct_alpha_category('Berio', 'Bernstein', @alpha_categories, 0)
      assert_equal(%w(Beri), @alpha_categories[0])
      assert_equal(%w(Bern), @alpha_categories[1])
    end

    should 'construct the correct category when the first name is longer than the last one' do
      @alpha_categories = construct_alpha_category('Brown', 'Chan', @alpha_categories, 0)
      assert_equal(%w(B), @alpha_categories[0])
      assert_equal(%w(C), @alpha_categories[1])
    end

    should 'construct the correct category when the first name is the same length as the last one' do
      @alpha_categories = construct_alpha_category('Bliss', 'Brown', @alpha_categories, 0)
      assert_equal(%w(Bl), @alpha_categories[0])
      assert_equal(%w(Br), @alpha_categories[1])
    end

    should 'construct the correct category when the first name is identical to the last one' do
      @alpha_categories = construct_alpha_category('Smith', 'Smith', @alpha_categories, 0)
      assert_equal(%w(Smith), @alpha_categories[0])
      assert_equal(%w(Smith), @alpha_categories[1])
    end
  end

# Tests for the alpha_paginate algorithm
  context 'Construct alphabetical categories: ' do
    setup do
      @students = []

      last_names = %w(Albert Alwyn Auric Berio Bliss Bridge Britten Cage
                        Dukas Duparc Egge Feldman)
      first_names = %w(Aaron Albert Alice Allen Benedict Bob Carl Dina
                        Eric Erin  Sara Zelda)
      user_names = %w(c5albert c5alwyn c5auric c6berio c6bliss c6bridge c6britte c7cage
                        g7dukas g7duparc g7egge g9feldma)

      (0..11).each do |i|
        student = Student.new(:user_name => user_names[i], :last_name => last_names[i], :first_name => first_names[i])
        student.save
        @students << student
      end
    end
    context 'sorted by last name' do
      should 'be able to handle the case where there are no students without errors' do
        alpha_pagination_students = alpha_paginate([], 12, 'last_name');
        assert_equal(alpha_pagination_students, [])
      end

      should 'construct the appropriate categories for alphabetical pagination when there is 1 page' do
        alpha_pagination_students = alpha_paginate(@students, 12, 'last_name');
        assert_equal('A-F', alpha_pagination_students[0])
      end

      should 'construct the appropriate categories for alphabetical pagination when there are multiple pages' do
        alpha_pagination_students = alpha_paginate(@students, 3, 'last_name');
        assert_equal('Al-Au', alpha_pagination_students[0])
        assert_equal('Be-Brid', alpha_pagination_students[1])
        assert_equal('Brit-Duk', alpha_pagination_students[2])
        assert_equal('Dup-F', alpha_pagination_students[3])
      end

      should 'construct the appropriate categories for alphabetical pagination when the last page has 1 student on it' do
        student = Student.new(:user_name => 's12', :last_name => 'Harris', :first_name => 'Bob')
        student.save
        @students << student

        alpha_pagination_students = alpha_paginate(@students, 4, 'last_name')
        assert_equal('A-Be', alpha_pagination_students[0])
        assert_equal('Bl-C', alpha_pagination_students[1])
        assert_equal('D-F', alpha_pagination_students[2])
        assert_equal('Harris-Harris', alpha_pagination_students[3])
      end
    end

    context 'sorted by first name' do
      should 'construct the appropriate categories for alphabetical pagination when there is 1 page' do
        alpha_pagination_students = alpha_paginate(@students, 12, 'first_name');
        assert_equal('A-Z', alpha_pagination_students[0])
      end

      should 'construct the appropriate categories for alphabetical pagination when there are multiple pages' do
        alpha_pagination_students = alpha_paginate(@students, 3, 'first_name');
        assert_equal('Aa-Ali', alpha_pagination_students[0])
        assert_equal('All-B', alpha_pagination_students[1])
        assert_equal('C-Eric', alpha_pagination_students[2])
        assert_equal('Erin-Z', alpha_pagination_students[3])
      end

      should 'construct the appropriate categories for alphabetical pagination when the last page has 1 student on it' do
        student = Student.new(:user_name => 'g9harris', :last_name => 'Harris', :first_name => 'Zeus')
        student.save
        @students << student

        alpha_pagination_students = alpha_paginate(@students, 4, 'first_name')
        assert_equal('Aa-Al', alpha_pagination_students[0])
        assert_equal('B-D', alpha_pagination_students[1])
        assert_equal('E-Zel', alpha_pagination_students[2])
        assert_equal('Zeus-Zeus', alpha_pagination_students[3])
      end
    end

    context 'sorted by user name' do
      should 'construct the appropriate categories for alphabetical pagination when there is 1 page' do
        alpha_pagination_students = alpha_paginate(@students, 12, 'user_name');
        assert_equal('c-g', alpha_pagination_students[0])
      end

      should 'construct the appropriate categories for alphabetical pagination when there are multiple pages' do
        alpha_pagination_students = alpha_paginate(@students, 3, 'user_name');
        assert_equal('c5al-c5au', alpha_pagination_students[0])
        assert_equal('c6be-c6brid', alpha_pagination_students[1])
        assert_equal('c6brit-g7duk', alpha_pagination_students[2])
        assert_equal('g7dup-g9', alpha_pagination_students[3])
      end

      should 'construct the appropriate categories for alphabetical pagination when the last page has 1 student on it' do
        student = Student.new(:user_name => 'g9harris', :last_name => 'Harris', :first_name => 'Zeus')
        student.save
        @students << student

        alpha_pagination_students = alpha_paginate(@students, 4, 'user_name')
        assert_equal('c5-c6be', alpha_pagination_students[0])
        assert_equal('c6bl-c7', alpha_pagination_students[1])
        assert_equal('g7-g9f', alpha_pagination_students[2])
        assert_equal('g9harris-g9harris', alpha_pagination_students[3])
      end
    end
  end
end
