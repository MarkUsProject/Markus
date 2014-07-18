require File.expand_path(File.join(File.dirname(__FILE__),
                                   'authenticated_controller_test'))
require File.expand_path(File.join(File.dirname(__FILE__),
                                   '..', 'test_helper'))
require File.expand_path(File.join(File.dirname(__FILE__),
                                   '..', 'blueprints', 'blueprints'))
require File.expand_path(File.join(File.dirname(__FILE__),
                                   '..', 'blueprints', 'helper'))
require 'shoulda'
require 'mocha/setup'

class SummariesControllerTest < AuthenticatedControllerTest
  context 'instructor attempts to display all information' do

    setup do
      @admin = Admin.make
      @group = Group.make
      @assignment = Assignment.make
      @grouping = Grouping.make(group: @group, assignment: @assignment)

    end

    should 'per_page and sort_by not defined so set cookies to default' do
      Assignment.stubs(:find).returns(@assignment)

      @c_per_page = @admin.id.to_s + '_' + @assignment.id.to_s + '_per_page'
      @c_sort_by = @admin.id.to_s + '_' + @assignment.id.to_s + '_sort_by'

      get_as @admin,
             :index,
             assignment_id: 1,
             id: 1

      assert_response :success
      assert_equal 30,
                   cookies[@c_per_page],
                   "Debug: Cookies=#{cookies.inspect}"
      assert_equal 'group_name', cookies[@c_sort_by]
    end

    should '15 per_page & sort_by revision_timestamp set cookies to default' do
      Assignment.stubs(:find).returns(@assignment)

      @c_per_page = @admin.id.to_s + '_' + @assignment.id.to_s + '_per_page'
      @c_sort_by = @admin.id.to_s + '_' + @assignment.id.to_s + '_sort_by'

      get_as @admin,
             :index,
             assignment_id: 1,
             id: 1,
             per_page: 15,
             sort_by: 'revision_timestamp'

      assert_response :success
      assert_equal '15',
                   cookies[@c_per_page],
                   "Debug: Cookies=#{cookies.inspect}"
      assert_equal 'revision_timestamp', cookies[@c_sort_by]
    end

    should '15 per_page and sort_by total_mark so set cookies to default' do
      Assignment.stubs(:find).returns(@assignment)

      @c_per_page = @admin.id.to_s + '_' + @assignment.id.to_s + '_per_page'
      @c_sort_by = @admin.id.to_s + '_' + @assignment.id.to_s + '_sort_by'

      get_as @admin,
             :index,
             assignment_id: 1,
             id: 1,
             per_page: 15,
             sort_by: 'total_mark'

      assert_response :success
      assert_equal '15',
                   cookies[@c_per_page],
                   "Debug: Cookies=#{cookies.inspect}"
      assert_equal 'total_mark', cookies[@c_sort_by]
    end

    should '15 per_page and sort_by criterion 1 so set cookies to default' do
      Assignment.stubs(:find).returns(@assignment)

      @c_per_page = @admin.id.to_s + '_' + @assignment.id.to_s + '_per_page'
      @c_sort_by = @admin.id.to_s + '_' + @assignment.id.to_s + '_sort_by'
      @c_cid = @admin.id.to_s + '_' + @assignment.id.to_s + '_cid'
      get_as @admin,
             :index,
             assignment_id: 1,
             id: 1,
             per_page: 15,
             sort_by: 'criterion',
             cid: 1

      assert_response :success
      assert_equal '15',
                   cookies[@c_per_page],
                   "Debug: Cookies=#{cookies.inspect}"
      assert_equal 'criterion', cookies[@c_sort_by]
      assert_equal '1', cookies[@c_cid]
    end

    should '50 per_page and sort_by criterion 1 so set cookies to default' do
      Assignment.stubs(:find).returns(@assignment)

      @c_per_page = @admin.id.to_s + '_' + @assignment.id.to_s + '_per_page'
      @c_sort_by = @admin.id.to_s + '_' + @assignment.id.to_s + '_sort_by'
      @c_cid = @admin.id.to_s + '_' + @assignment.id.to_s + '_cid'
      get_as @admin,
             :index,
             assignment_id: 1,
             id: 1,
             per_page: 50,
             sort_by: 'criterion',
             cid: 1

      assert_response :success
      assert_equal '50',
                   cookies[@c_per_page],
                   "Debug: Cookies=#{cookies.inspect}"
      assert_equal 'criterion', cookies[@c_sort_by]
      assert_equal '1', cookies[@c_cid]
    end

    should '15 per_page and sort_by criterion 2 so set cookies to default' do
      Assignment.stubs(:find).returns(@assignment)

      @c_per_page = @admin.id.to_s + '_' + @assignment.id.to_s + '_per_page'
      @c_sort_by = @admin.id.to_s + '_' + @assignment.id.to_s + '_sort_by'
      @c_cid = @admin.id.to_s + '_' + @assignment.id.to_s + '_cid'
      get_as @admin,
             :index,
             assignment_id: 1,
             id: 1,
             per_page: 15,
             sort_by: 'criterion',
             cid: 2

      assert_response :success
      assert_equal '15',
                   cookies[@c_per_page],
                   "Debug: Cookies=#{cookies.inspect}"
      assert_equal 'criterion', cookies[@c_sort_by]
      assert_equal '2', cookies[@c_cid]
    end
  end
end
