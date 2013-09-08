require File.join(File.dirname(__FILE__), '..', '..', 'test_helper')
require 'shoulda'
require 'fileutils'
require 'mocha/setup'
require 'will_paginate'
require 'will_paginate/collection'
include PaginationHelper

class PaginationHelperTest < ActiveSupport::TestCase

  context 'I need some points paginated' do

    setup do
      if defined?(Oracle).nil?
        Oracle = mock()
      end
      @point_table_params = {
        :model => nil,
        :per_pages => nil,
        :filters => {
          'none' => {
            :display => 'all',
            :proc => lambda { |params, to_include|
              Oracle.get_all()
            }
          },
          'even' => {
            :display => 'even',
            :proc => lambda { |params, to_include|
              Oracle.get_even()
            }
          },
          'odd' => {
            :display => 'odd',
            :proc => lambda { |params, to_include|
              Oracle.get_odd()
            }
          },
          'prime' => {
            :display => 'prime',
            :proc => lambda { |params, to_include|
              Oracle.get_prime()
            }
          }
        },
        :sorts => {
          'x_cord' => lambda { |a,b| Oracle.x_sort() } ,
          'y_cord' => lambda { |a,b| Oracle.y_sort() }
        }
      }
    end

    should 'display all points, and sort by the x coordinate' do
      params = { :filter => 'none', :sort_by => 'x_cord' }

      # mocking the array that gets returned
      array = [ [1,1] , [2,2] , [3,3] , [4,4] , [5,5] ]

      # mocking the getters
      Oracle.expects( :get_all ).returns( array )
      Oracle.expects( :get_even ).never
      Oracle.expects( :get_odd ).never
      Oracle.expects( :get_prime ).never

      #mocking the sorting
      Oracle.expects( :x_sort ).returns( -1 ).at_least_once
      Oracle.expects( :y_sort ).never
      PaginationHelper.handle_paginate_event( @point_table_params, nil, params )
    end

    should 'display prime points, and sort by the y coordinate' do
      params = { :filter => 'prime', :sort_by => 'y_cord' }

      # mocking the array that gets returned
      array = [ [2,2] , [3,3] , [5,5] ]

      # mocking the getters
      Oracle.expects( :get_all ).never
      Oracle.expects( :get_even ).never
      Oracle.expects( :get_odd ).never
      Oracle.expects( :get_prime ).returns( array )

      #mocking the sorting
      Oracle.expects( :x_sort ).never
      Oracle.expects( :y_sort ).returns( -1 ).at_least_once
      PaginationHelper.handle_paginate_event( @point_table_params, nil, params )
    end

    should 'sort in ascending order' do
      params = { :filter => 'none', :sort_by => 'x_cord' }

      # mocking the array that gets returned
      array = [ [1,1] , [2,2] , [3,3] , [4,4] , [5,5] ]
      sorted_array = [ [1,1] , [2,2] , [3,3] , [4,4] , [5,5] ]
      # desc flag not set, so the array should not be reversed
      sorted_array.expects( :reverse! ).never

      # mocking the getters
      Oracle.expects( :get_all ).returns( array )
      array.expects(:sort).returns( sorted_array )

      #mocking the sorting
      PaginationHelper.handle_paginate_event( @point_table_params, nil, params )
    end

    should 'sort in descending order' do
      params = { :filter => 'none', :sort_by => 'x_cord', :desc => true }

      # mocking the array that gets returned
      array = [ [1,1] , [2,2] , [3,3] , [4,4] , [5,5] ]
      sorted_array = [ [5,5], [4,4], [3,3], [2,2], [1,1] ]
      # desc flag not set, so the array should not be reversed
      sorted_array.expects( :reverse! )

      # mocking the getters
      Oracle.expects( :get_all ).returns( array )
      array.expects(:sort).returns( sorted_array )

      #mocking the sorting
      PaginationHelper.handle_paginate_event( @point_table_params, nil, params )
    end

    should 'return a paginated list' do
      params = { :filter => 'none', :page => 3, :per_page => 10, :sort_by => 'x_cord' }

      # mocking the array that gets returned
      array = []
      array = (1 .. 100).entries

      # mocking the getters
      Oracle.expects( :get_all ).returns( array )
      array.expects(:sort).returns( array )

      # checking the pagination
      items = PaginationHelper.handle_paginate_event( @point_table_params, nil, params )
      assert_equal items[0].total_pages(), 10
      assert_equal items[0].current_page(), 3
      assert_equal items[0].next_page(), 4
      assert_equal items[0].previous_page(), 2

    end

    should 'return all the filters from the table_params' do
      filters = PaginationHelper.get_filters( @point_table_params )
      assert filters.include?('all'), 'filters did not include all'
      assert filters['all'].include?('none'), 'filters did not include none'
      assert filters.include?('even'), 'filters did not include even'
      assert filters['even'].include?('even'), 'filters did not include even'
      assert filters.include?('odd'), 'filters did not include odd'
      assert filters['odd'].include?('odd'), 'filters did not include odd'
      assert filters.include?('prime'), 'filters did not include prime'
      assert filters['prime'].include?('prime'), 'filters did not include prime'
      assert_equal filters.size(), 4, 'filters contained an extra filter'
    end

  end
end
