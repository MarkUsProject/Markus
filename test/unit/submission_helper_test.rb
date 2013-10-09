# encoding: utf-8
require File.expand_path(File.join(File.dirname(__FILE__), '..', 'test_helper'))
require 'shoulda'

class SubmissionHelperTest < ActiveSupport::TestCase

  include SubmissionsHelper

  # Put some confidence in our submission filename sanitization
  context 'A new file when submitted' do
    context "containing characters outside what's allowed in a filename" do
      setup do
        @filenames_to_be_sanitized = [ { :expected => 'llll_', :orig => 'llllé' },
                                       { :expected => '________', :orig => 'öä*?`ßÜÄ' },
                                       { :expected => '', :orig => nil },
                                       { :expected => 'garbage-__.txt', :orig => 'garbage-éæ.txt' },
                                       { :expected => 'space_space.txt', :orig => 'space space.txt' },
                                       { :expected => '______.txt', :orig => '      .txt' },
                                       { :expected => 'garbage-__.txt', :orig => 'garbage-éæ.txt' } ]
      end

      should 'have sanitized them properly' do
        @filenames_to_be_sanitized.each do |item|
          assert_equal item[:expected], sanitize_file_name(item[:orig])
        end
      end
    end

    context 'containing only valid characters in a filename' do
      setup do
        @filenames_not_to_be_sanitized = %w(valid_file.sh
                                            valid_001.file.ext
                                            valid-master.png
                                            some__file___.org-png
                                            001.txt)
      end

      should 'NOT have sanitized away any of their characters' do
        @filenames_not_to_be_sanitized.each do |orig|
          assert_equal orig, sanitize_file_name(orig)
        end
      end
    end
  end
end
