require File.join(File.dirname(__FILE__), '..', 'test_helper')
require 'shoulda'

class AnnotationCategoryTest < ActiveSupport::TestCase
   fixtures :all
   should validate_presence_of :annotation_category_name
   should validate_presence_of :assignment_id

  # Test that an Annotations Category without name are not valid
  def test_no_name
    no_name = create_no_attr(:name);
    assert !no_name.valid?
  end

  # Helper method for test_validate_presence_of to create a category without
  # the specified attribute. if attr == nil then all attributes are included
  def create_no_attr(attr)
    new_annotation_category = {
      :name => "annotationcategory1",
    }

    new_annotation_category.delete(attr) if attr
    AnnotationCategory.new(new_annotation_category)
  end

  # test the presence of an assignment id
  def test_presence_of_assignment_id
    annotation = AnnotationCategory.new
    annotation.annotation_category_name = "essai"
    assert !annotation.save, "Annotation category saved without an
    assignment id"
  end

  def test_presence_of_name
    annotation = AnnotationCategory.new
    annotation.assignment_id = 1
    assert !annotation.save, "Annotation category saved without an
    name"
  end

  def test_save_when_everything_is_OK
    annotation = AnnotationCategory.new
    annotation.assignment_id = 1
    annotation.annotation_category_name = "test"
    assert annotation.save, "Annotation category NOT saved"
  end

  def test_add_by_row
    row = []
    row.push("annotation category name")
    row.push("annotation text 1")
    row.push("annotation text 2")
    assignment = assignments(:assignment_1)
    assert AnnotationCategory.add_by_row(row, assignment), "annotation saved"
  end

  def test_add_by_row_1
    row = []
    row.push("annotation category name 2")
    row.push("annotation text 2 1")
    row.push("annotation text 2 2")
    a = AnnotationCategory.all.size
    assignment = assignments(:assignment_1)
    AnnotationCategory.add_by_row(row, assignment)
    assert_not_equal(a, AnnotationCategory.all.size, "an annotation category
    has been created. The number of annotation category should be different")
  end

  def test_add_by_row_2
    row = []
    row.push("annotation category name 3")
    row.push("annotation text 3 1")
    row.push("annotation text 3 2")
    a = AnnotationText.all.size
    assignment = assignments(:assignment_1)
    AnnotationCategory.add_by_row(row, assignment)
    assert_not_equal(a, AnnotationText.all.size, "an annotation text
    has been created. The number of annotation texts should be different")
  end


end
