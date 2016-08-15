require File.join(File.dirname(__FILE__), '..', '..', 'test_helper')
require 'shoulda'
require 'fileutils'
include EnsureConfigHelper
include MarkusConfigurator

class EnsureConfigHelperTest < ActiveSupport::TestCase

  context 'A configured default language with language file present in config/locales' do
    should 'not raise an exception' do
      EnsureConfigHelper.check_configured_default_language('en')
    end
  end

  context 'A configured default language with language file not present in config/locales' do
    should 'raise an exception' do
      assert_raise RuntimeError do
        EnsureConfigHelper.check_configured_default_language('no')
      end
    end
  end

  context 'setting up the markus_configurator' do

    setup do
      @temp_dir = "./tmp/ensure_config_helper_test_#{rand(1073741824)}"
      @log_dir = "#{@temp_dir}/log"
      @log_info_file = "#{@log_dir}/log_info_file.log"
      @log_error_file = "#{@log_dir}/log_error_file.log"
      @source_repo_dir = "#{@temp_dir}/source_repo_dir"
      @validate_script = "#{@temp_dir}/validate_script.sh"

      MarkusConfigurator.stubs(:markus_config_logging_logfile).returns(@log_info_file)
      MarkusConfigurator.stubs(:markus_config_logging_errorlogfile).returns(@log_error_file)
      MarkusConfigurator.stubs(:markus_config_repository_storage).returns(@source_repo_dir)
      MarkusConfigurator.stubs(:markus_config_validate_file).returns(@validate_script)
      FileUtils.mkdir( @temp_dir )
    end

    teardown do
      FileUtils.rm_r(@temp_dir)
    end

    context 'running ensure config when all required files are missing' do
      should 'throw an exception' do
        assert_raise RuntimeError do
          EnsureConfigHelper.check_config()
        end
      end
    end

    context 'with a log dir' do
      setup do
        FileUtils.mkdir(@log_dir)
      end

      should 'throw an exception because the validate file and repo do not exist' do
        assert_raise RuntimeError do
          EnsureConfigHelper.check_config()
        end
      end

      context 'with a repo dir' do
        setup do
          FileUtils.mkdir(@source_repo_dir)
        end

        should 'throw an exception because the validate file does not exist' do
          #MarkUs on Windows does not support external authentication so skip if Windows platform
          unless RUBY_PLATFORM =~ /(:?mswin|mingw)/
            assert_raise RuntimeError do
              EnsureConfigHelper.check_config()
            end
          end
        end

        context 'with an unexecutable validate file' do
          setup do
            FileUtils.touch(@validate_script)
            FileUtils.chmod(0200, @validate_script)
          end

          should 'throw an exception because the validate file is not executable' do
            assert_raise RuntimeError do
              EnsureConfigHelper.check_config()
            end
          end
        end

        context 'with an executable validate file' do
          setup do
            FileUtils.touch(@validate_script)
            FileUtils.chmod( 0700, @validate_script)

            f = File.open(@validate_script, 'w')
            f.write("#!/bin/bash\n")
            f.write("read user\n")
            f.write("read password\n")
            f.write('exit 0')
            f.close
          end

          should 'accept the configuration because all files and directories are ready' do
            assert_nothing_raised do
              EnsureConfigHelper.check_config()
            end
          end
        end

        context 'with an executable validate file with an escaped space' do
          setup do
            @validate_script = "#{@temp_dir}/validate\\ script.sh"
            MarkusConfigurator.stubs(:markus_config_validate_file).returns(@validate_script)

            FileUtils.touch(@validate_script)
            FileUtils.chmod(0700, @validate_script)

            f = File.open(@validate_script, 'w')
            f.write("#!/bin/bash\n")
            f.write("read user\n")
            f.write("read password\n")
            f.write('exit 0')
            f.close
          end

          should 'accept the configuration because all files and directories are ready' do
            assert_nothing_raised do
              EnsureConfigHelper.check_config()
            end
          end
        end

        context 'with an executable that is not properly escaped' do
          setup do
            @validate_script = "#{@temp_dir}/validate script.sh"
            MarkusConfigurator.stubs(:markus_config_validate_file).returns(@validate_script)

            FileUtils.touch(@validate_script)
            FileUtils.chmod(0700, @validate_script)

            f = File.open(@validate_script, 'w')
            f.write("#!/bin/bash\n")
            f.write("read user\n")
            f.write("read password\n")
            f.write('exit 0')
            f.close
          end

          should 'accept the configuration' do
            assert_nothing_raised do
              EnsureConfigHelper.check_config()
            end
          end
        end

      end
    end
  end
end
