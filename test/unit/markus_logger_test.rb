require File.expand_path(File.join(File.dirname(__FILE__), '..', 'test_helper'))
require 'markus_logger'
require 'shoulda'

include MarkusConfigurator

class MarkusLoggerTest < ActiveSupport::TestCase
  context 'A MarkusLogger instance' do
    setup do
      pid = Process.pid
      @infolog = File.join('tmp','info.log')
      @errorlog = File.join('tmp','error.log')
      @badfile = File.join('tmp','badfile')
      @badfile_w_pid = "#{@badfile}.#{pid}"
      @baddir = File.join('tmp','baddir')
      @baddir_w_pid = "#{@baddir}.#{pid}"
      @size = 1024
      interval = 'daily'
      byInterval = false
      oldfiles = 10
      MarkusConfigurator.stubs(:markus_config_logging_rotate_by_interval).returns(byInterval)
      MarkusConfigurator.stubs(:markus_config_logging_size_threshold).returns(@size)
      MarkusConfigurator.stubs(:markus_config_logging_rotate_interval).returns(interval)
      MarkusConfigurator.stubs(:markus_config_logging_logfile).returns(@infolog)
      MarkusConfigurator.stubs(:markus_config_logging_errorlogfile).returns(@errorlog)
      MarkusConfigurator.stubs(:markus_config_logging_num_oldfiles).returns(oldfiles)
      # We append the pid to log files, so have to do it here too :)
      @infolog += ".#{pid}"
      @errorlog += ".#{pid}"
      unless File.file?(@infolog)
        File.new(@infolog,'w')
      end
      unless File.file?(@errorlog)
        File.new(@errorlog,'w')
      end
    end

    # FileUtils.remove does not work properly on Windows.
    # It throws a Permission denied.
    teardown do
      begin
        if File.directory?(@baddir)
          FileUtils.chmod 0777 , @baddir # Return writing permissions
          FileUtils.remove_dir @baddir, force: false
        end
     rescue Exception => ex
        $stderr.puts "Error while trying to remove the directory #{@baddir}: " + ex
      end
      begin
        if File.directory?(@baddir_w_pid)
          FileUtils.chmod 0777 , @baddir_w_pid # Return writing permissions
          FileUtils.remove_dir @baddir_w_pid, force: false
        end
     rescue Exception => ex
        $stderr.puts "Error while trying to remove the directory #{@baddir_w_pid}: " + ex
      end
      begin
        if File.exists?(@badfile_w_pid)
          FileUtils.chmod 0777 , @badfile_w_pid # Return writing permissions
          FileUtils.remove @badfile_w_pid, force: false
        end
      rescue Exception => ex
        $stderr.puts "Error while trying to remove the file #{@badfile_w_pid}: " + ex
      end
      begin
        if File.exists?(@infolog)
          FileUtils.remove @infolog, force: false
        end
      rescue Exception => ex
        puts "Error while trying to remove the file #{@infolog}: " + ex
      end
      begin
        if File.exists?(@errorlog)
          FileUtils.remove @errorlog, force: false
        end
      rescue Exception => ex
        puts "Error while trying to remove the file #{@errorlog}: " + ex
      end

      # reset probably instantiated Singleton
      Singleton.__init__(MarkusLogger)
    end

    should 'raise exception when new is called' do
      assert_raises NoMethodError do
        logger = MarkusLogger.new
      end
    end

    should 'only be one instance of MarkusLogger' do
      log_a = MarkusLogger.instance
      log_b = MarkusLogger.instance
      assert_same log_a, log_b
    end

    should 'the valid_file? method be private' do
      logger = MarkusLogger.instance
      assert_raises NoMethodError do
        logger.valid_file?(@infolog)
      end
    end

    should 'initialize correctly and raise no exceptions' do
      assert_nothing_raised do
        logger = MarkusLogger.instance
      end
    end

    should 'if MarkusLogger is enabled, raise exception if log level is above the FATAL level' do
      if MarkusConfigurator.markus_config_logging_enabled?
        log_level = MarkusLogger::FATAL + 1
        assert_raises ArgumentError do
          logger = MarkusLogger.instance
          logger.log('test', log_level)
        end
      end
    end

    should 'if MarkusLogger is enabled, raise exception if log level is below the DEBUG level' do
      if MarkusConfigurator.markus_config_logging_enabled?
        log_level = MarkusLogger::DEBUG - 1
        assert_raises ArgumentError do
          logger = MarkusLogger.instance
          logger.log('test', log_level)
        end
      end
    end

    # Does not work properly on Windows, throws a Permission denied
    should 'if MarkusLogger is enabled, rotate infologs when @size bytes of data is reached' do
      if MarkusConfigurator.markus_config_logging_enabled?
        logger = MarkusLogger.instance
        current_size = File.size(@infolog)
        chars = ('a'..'z').to_a + ('A'..'Z').to_a
        msg = (current_size...@size).collect { chars[Kernel.rand(chars.length)] }.join
        logger.log(msg)
        logger.log(msg)
        infolog = @infolog
        assert File.file?(infolog)
        assert File.file?(infolog << '.0')
      end
    end

    # Does not work properly on Windows, throws a Permission denied
    should 'if MarkusLogger is enabled, rotate errorlogs when @size bytes of data is reached' do
      if MarkusConfigurator.markus_config_logging_enabled?
        logger = MarkusLogger.instance
        current_size = File.size(@errorlog)
        chars = ('a'..'z').to_a + ('A'..'Z').to_a
        msg = (current_size...@size).collect { chars[Kernel.rand(chars.length)] }.join
        logger.log(msg,MarkusLogger::ERROR)
        logger.log(msg,MarkusLogger::ERROR)
        errorlog = @errorlog
        assert File.file?(errorlog)
        assert File.file?(errorlog << '.0')
      end
    end

    should 'if MarkusLogger is disabled, not write to a file when the log method is called' do
      unless MarkusConfigurator.markus_config_logging_enabled?
        logger = MarkusLogger.instance
        original_size = File.size(@errorlog)
        chars = ('a'..'z').to_a + ('A'..'Z').to_a
        msg = (1..12).collect { chars[Kernel.rand(chars.length)] }.join
        logger.log(msg,MarkusLogger::ERROR)
        assert File.file?(@errorlog)
        assert original_size == File.size(@errorlog)
      end
    end

    should 'raise exception if logfile is a directory' do
      baddir = File.join('tmp', 'baddir')
      baddir_with_pid = "#{baddir}.#{Process.pid}"
      FileUtils.mkdir_p baddir_with_pid unless File.directory?(baddir_with_pid)
      MarkusConfigurator.stubs(:markus_config_logging_logfile).returns(baddir)
      assert_raises MarkusLoggerConfigurationError do
        logger = MarkusLogger.instance
      end
    end

    should 'raise exception if error_logfile is a directory' do
      FileUtils.mkdir_p @baddir_w_pid unless File.directory?(@baddir_w_pid)
      MarkusConfigurator.stubs(:markus_config_logging_errorlogfile).returns(@baddir)
      assert_raises MarkusLoggerConfigurationError do
        logger = MarkusLogger.instance
      end
    end

    should 'raise exception if error_logfile is in a directory with no writing permissions' do
      FileUtils.mkdir_p @baddir_w_pid unless File.directory?(@baddir_w_pid)
      FileUtils.chmod 0000, @baddir_w_pid
      MarkusConfigurator.stubs(:markus_config_logging_errorlogfile).returns(@baddir)
      assert_raises MarkusLoggerConfigurationError do
        logger = MarkusLogger.instance
      end
    end

    should 'raise exception if logfile is in a directory with no writing permissions' do
      FileUtils.mkdir_p @baddir unless File.directory?(@baddir)
      file = File.join(@baddir,'file')
      FileUtils.chmod 0000, @baddir
      MarkusConfigurator.stubs(:markus_config_logging_logfile).returns(file)
      assert_raises MarkusLoggerConfigurationError do
        logger = MarkusLogger.instance
      end
    end

    should 'raise exception if logfile is a file with no writing permissions' do
      badfile = File.open( @badfile_w_pid,'w')
      badfile.chmod 0000
      MarkusConfigurator.stubs(:markus_config_logging_logfile).returns(@badfile)
      assert_raises MarkusLoggerConfigurationError do
        logger = MarkusLogger.instance
      end
    end

    should 'raise exception if error_logfile is a file with no writing permissions' do
      badfile = File.open( @badfile_w_pid,'w')
      badfile.chmod 0000
      MarkusConfigurator.stubs(:markus_config_logging_errorlogfile).returns(@badfile)
      assert_raises MarkusLoggerConfigurationError do
        logger = MarkusLogger.instance
      end
    end

    should 'raise exception when the threshold size is == 0' do
      MarkusConfigurator.stubs(:markus_config_logging_size_threshold).returns(0)
      assert_raises MarkusLoggerConfigurationError do
         logger = MarkusLogger.instance
      end
    end

    should 'raise exception when the threshold size is < 0' do
      MarkusConfigurator.stubs(:markus_config_logging_size_threshold).returns(-1)
      assert_raises MarkusLoggerConfigurationError do
         logger = MarkusLogger.instance
      end
    end

    should 'raise exception when the number of old logfiles to keep is < 0' do
      MarkusConfigurator.stubs(:markus_config_logging_num_oldfiles).returns(-1)
      assert_raises MarkusLoggerConfigurationError do
         logger = MarkusLogger.instance
      end
    end

    should 'raise exception when the number of old logfiles to keep is == 0' do
      MarkusConfigurator.stubs(:markus_config_logging_num_oldfiles).returns(-1)
      assert_raises MarkusLoggerConfigurationError do
         logger = MarkusLogger.instance
      end
    end

    should 'raise exception when the rotation interval is not daily, weekly or monthly' do
      MarkusConfigurator.stubs(:markus_config_logging_rotate_by_interval).returns(true)
      MarkusConfigurator.stubs(:markus_config_logging_rotate_interval).returns('lalala')
      assert_raises MarkusLoggerConfigurationError do
        logger = MarkusLogger.instance
      end
    end

  end # end context
end
