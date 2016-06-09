# Using machinist

require File.expand_path(File.join(File.dirname(__FILE__), 'authenticated_controller_test'))
require File.expand_path(File.join(File.dirname(__FILE__), '..', 'test_helper'))
require File.expand_path(File.join(File.dirname(__FILE__), '..', 'blueprints', 'blueprints'))
require File.expand_path(File.join(File.dirname(__FILE__), '..', 'blueprints', 'helper'))
require 'shoulda'


class AutomatedTestsControllerTest < AuthenticatedControllerTest

  def setup
    clear_fixtures
  end

  # TODO: the following tests are aged. It worked with the old testing framework,
  # but not MarkUs ATE. Please rewrite all the tests for this controller

=begin
  context 'A logged Admin' do
    setup do
      @admin = Admin.make
      @assignment = Assignment.make
    end

    # context 'on manage' do
    #   setup do
    #     get_as @admin, :manage, {assignment_id: @assignment.id}
    #   end
    #
    #   should respond_with :success
    # end

    context 'creating a test file' do
      setup do
        post_as @admin,
                :update, {assignment_id: @assignment.id,
                          assignment: {
                                enable_test: '1',
                                 test_files_attributes: {
                                    '1' => {
                                          id: nil,
                                          filename: 'validtestfile',
                                          filetype: 'test', is_private: '0'}}}}
      end

      should 'respond with appropriate content' do
        assert_not_nil assigns :assignment
      end
      should respond_with :redirect
      should set_flash.to(t('assignment.update_success'))

      should 'add a test file named validtestfile' do
        assert TestFile.find_by_assignment_id_and_filename(
                  "#{@assignment.id}",
               'validtestfile')
      end
    end

    # context 'creating an invalid test file' do
    #   setup do
    #     post_as @admin,
    #             :update,
    #             {assignment_id: @assignment.id,
    #              assignment: {
    #                   enable_test: '1',
    #                   test_files_attributes: {
    #                         '1' => {id: nil,
    #                                 filename: 'build.xml',
    #                                 filetype: 'test',
    #                                 is_private: '0'}}}}
    #   end
    #
    #   should render_template 'manage'
    #
    #   should 'not add a test file named build.xml' do
    #     assert !TestFile.find_by_assignment_id_and_filename_and_filetype("#{@assignment.id}", 'build.xml', 'test')
    #   end
    # end

    context 'updating a test file' do
      setup do
        post_as @admin,
                :update,
                {assignment_id: @assignment.id,
                 assignment: {
                      enable_test: '1',
                      test_files_attributes: {
                          '1' => {assignment_id: nil,
                                  filename: 'validtestfile',
                                  filetype: 'test',
                                  is_private: '0'}}}}
      end

      should respond_with :redirect
      should set_flash.to(t('assignment.update_success'))

      should 'update test file named validtestfile to newvalidtestfile' do
        tfile = TestFile.find_by_assignment_id_and_filename(
                    "#{@assignment.id}",
                    'validtestfile')
        post_as @admin,
                :update,
                {assignment_id: @assignment.id,
                 assignment: {
                      enable_test: '1',
                      test_files_attributes: {
                          '1' => {id: "#{tfile.id}",
                                  filename: 'newvalidtestfile'}}}}
        assert TestFile.find_by_id_and_filename("#{tfile.id}", 'newvalidtestfile')
        assert !TestFile.find_by_id_and_filename("#{tfile.id}", 'validtestfile')
      end
    end

    context 'deleting a test file' do
      setup do
        post_as @admin,
                :update,
                {assignment_id: @assignment.id,
                 assignment: {
                      enable_test: '1',
                      test_files_attributes: {
                            '1' => {id: nil,
                                    filename: 'validtestfile',
                                    filetype: 'test',
                                    is_private: '0'}}}}
      end

      should respond_with :redirect
      should set_flash.to(t('assignment.update_success'))

      should 'delete test file named validtestfile' do
        tfile = TestFile.find_by_assignment_id_and_filename("#{@assignment.id}", 'validtestfile')
        post_as @admin,
                :update,
                {assignment_id: @assignment.id,
                 assignment: {enable_test: '1',
                                 test_files_attributes: {
                                    '1' => {id: "#{tfile.id}",
                                            _destroy: '1'}}}}
        assert !TestFile.find_by_id_and_filename("#{tfile.id}", 'validtestfile')

      end
    end
  end
=end
end
