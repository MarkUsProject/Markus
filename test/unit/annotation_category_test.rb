require File.expand_path(File.join(File.dirname(__FILE__), '..', 'test_helper'))
require File.expand_path(File.join(File.dirname(__FILE__), '..', 'blueprints', 'blueprints'))
require File.expand_path(File.join(File.dirname(__FILE__), '..', 'blueprints', 'helper'))
require 'shoulda'

class AnnotationCategoryTest < ActiveSupport::TestCase

  context 'Test annotation add by row' do
    context ', when no annotation categories exists' do
      setup do
        @row = []
        @row.push('annotation category name')
        @row.push('annotation text 1')
        @row.push('annotation text 2')
        @assignment = Assignment.make
        @current_user = Admin.make
      end

      should 'save the annotation' do
        assert AnnotationCategory.add_by_row(@row, @assignment, @current_user)
      end
    end

    context 'when the annotation category already exists' do
      setup do
        @row = []
        @row.push('annotation category name 2')
        @row.push('annotation text 2 1')
        @row.push('annotation text 2 2')
        @a = AnnotationCategory.all.size
        @assignment = Assignment.make
        @current_user = Admin.make
        AnnotationCategory.add_by_row(@row, @assignment, @current_user)
      end
      should validate_presence_of :annotation_category_name
      should validate_presence_of :assignment_id
      should have_many :annotation_texts
      should belong_to :assignment
      should validate_uniqueness_of(:annotation_category_name).scoped_to(:assignment_id).with_message('is already taken')

      # an annotation category has been created.
      # the number of annotation category should be different
      should 'update the annotation' do
        assert_not_equal(@a, AnnotationCategory.all.size)
      end
    end

    context 'when the annotation text of the annotation categorie already exists' do
      setup do
        @row = []
        @row.push('annotation category name 3')
        @row.push('annotation text 3 1')
        @row.push('annotation text 3 2')
        @a = AnnotationText.all.size
        @assignment = Assignment.make
        @current_user = Admin.make
        AnnotationCategory.add_by_row(@row, @assignment, @current_user)
      end

      should 'update the numeber of annotation texts' do
        assert_not_equal(@a, AnnotationText.all.size)
      end
    end

  end

end
