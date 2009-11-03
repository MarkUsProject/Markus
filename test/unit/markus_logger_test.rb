require 'test/unit'
require File.join(File.dirname(__FILE__),'/../../app/models/markus_logger')
require 'shoulda'

class MarkusLoggerTest < Test::Unit::TestCase
  context "A MarkusLogger instance" do
    setup do
      @infolog = File.join('test','unit','info.log')
      if !File.file?(@infolog)
        File.new(@infolog,'w')
      end
      @errorlog = File.join('test','unit','error.log')
      if !File.file?(@errorlog)
        File.new(@errorlog,'w')
      end
      @badfile = File.join('test','unit','badfile')
      @baddir = File.join('test','unit','baddir')
      @size = 1024
      interval = 'daily'
      byInterval = false
      oldfiles = 10
      MarkusLogger.const_set(:MARKUS_LOGGING_ROTATE_BY_INTERVAL, byInterval)
      MarkusLogger.const_set(:MARKUS_LOGGING_SIZE_THRESHOLD, size)
      MarkusLogger.const_set(:MARKUS_LOGGING_ROTATE_INTERVAL, interval)
      MarkusLogger.const_set(:MARKUS_LOGGING_LOGFILE, @infolog)
      MarkusLogger.const_set(:MARKUS_LOGGING_ERRORLOGFILE, @errorlog)
      MarkusLogger.const_set(:MARKUS_LOGGING_OLDFILES, oldfiles)
    end

    
    teardown do
      begin
        if File.directory?(@baddir)
          FileUtils.chmod 0777 , @baddir # Return writing permissions
          FileUtils.remove_dir @baddir, :force => false
        end
     rescue Exception => ex
        puts "Error while trying to remove the directory #{@baddir}: " + ex
      end
      begin
        if File.exists?(@badfile)
          FileUtils.chmod 0777 , @badfile # Return writing permissions
          FileUtils.remove @badfile, :force => false
        end
      rescue Exception => ex
        puts "Error while trying to remove the file #{@badfile}: " + ex
      end
      begin
        if File.exists?(@infolog)
          FileUtils.remove @infolog, :force => false
        end
      rescue Exception => ex
        puts "Error while trying to remove the file #{@infolog}: " + ex
      end
      begin
        if File.exists?(@errorlog)
          FileUtils.remove @errorlog, :force => false
        end
      rescue Exception => ex
        puts "Error while trying to remove the file #{@errorlog}: " + ex
      end
    end


    should "01raise exception if logfile is a directory" do
      FileUtils.mkdir_p @baddir unless File.directory?(@baddir)
      MarkusLogger.const_set(:MARKUS_LOGGING_LOGFILE, @baddir)
      assert_raise MarkusLoggerConfigurationError do
        logger = MarkusLogger.instance
      end
    end

    should "01raise exception if error_logfile is a directory" do
      FileUtils.mkdir_p @baddir unless File.directory?(@baddir)
      MarkusLogger.const_set(:MARKUS_LOGGING_ERRORLOGFILE, @baddir)
      assert_raise MarkusLoggerConfigurationError do
        logger = MarkusLogger.instance
      end
    end

    should "01raise exception if error_logfile is in a directory with no writing permissions" do
      FileUtils.mkdir_p @baddir unless File.directory?(@baddir)
      file = File.join(@baddir,'file');
      FileUtils.chmod 0000, @baddir
      MarkusLogger.const_set(:MARKUS_LOGGING_ERRORLOGFILE, file)
      assert_raise MarkusLoggerConfigurationError do
        logger = MarkusLogger.instance
      end
    end

    should "01raise exception if logfile is in a directory with no writing permissions" do
      FileUtils.mkdir_p @baddir unless File.directory?(@baddir)
      file = File.join(@baddir,'file');
      FileUtils.chmod 0000, @baddir
      MarkusLogger.const_set(:MARKUS_LOGGING_LOGFILE, file)
      assert_raise MarkusLoggerConfigurationError do
        logger = MarkusLogger.instance
      end
    end

    should "01raise exception if logfile is a file with no writing permissions" do
      badfile = File.open( @badfile,'w')
      badfile.chmod 0000
      MarkusLogger.const_set(:MARKUS_LOGGING_LOGFILE, @badfile)
      assert_raise MarkusLoggerConfigurationError do
        logger = MarkusLogger.instance
      end
    end

    should "01raise exception if error_logfile is a file with no writing permissions" do
      badfile = File.open( @badfile,'w')
      badfile.chmod 0000
      MarkusLogger.const_set(:MARKUS_LOGGING_ERRORLOGFILE, @badfile)
      assert_raise MarkusLoggerConfigurationError do
        logger = MarkusLogger.instance
      end
    end

    should "01raise exception when new is called" do
      assert_raise NoMethodError do
        logger = MarkusLogger.new
      end
    end

    should "01raise exception when the threshold size is == 0" do
      MarkusLogger.const_set(:MARKUS_LOGGING_SIZE_THRESHOLD, 0)
      assert_raise MarkusLoggerConfigurationError do
         @logger = MarkusLogger.instance
      end
    end
    
    should "01raise exception when the threshold size is < 0" do
      MarkusLogger.const_set(:MARKUS_LOGGING_SIZE_THRESHOLD, -1)
      assert_raise MarkusLoggerConfigurationError do
         @logger = MarkusLogger.instance
      end
    end
    
    should "01raise exception when the number of old logfiles to keep is < 0" do
      MarkusLogger.const_set(:MARKUS_LOGGING_OLDFILES, -1)
      assert_raise MarkusLoggerConfigurationError do
         @logger = MarkusLogger.instance
      end
    end
    
    should "01raise exception when the number of old logfiles to keep is == 0" do
      MarkusLogger.const_set(:MARKUS_LOGGING_OLDFILES, 0)
      assert_raise MarkusLoggerConfigurationError do
         @logger = MarkusLogger.instance
      end
    end

    should "01raise exception when the rotation interval is not daily, weekly or monthly" do
      MarkusLogger.const_set(:MARKUS_LOGGING_ROTATE_BY_INTERVAL, true)
      MarkusLogger.const_set(:MARKUS_LOGGING_ROTATE_INTERVAL, 'lalala')
      assert_raise MarkusLoggerConfigurationError do
        @logger = MarkusLogger.instance
      end
    end

    should "03only be one instance of MarkusLogger" do
      log_a = MarkusLogger.instance
      log_b = MarkusLogger.instance
      assert_same log_a, log_b
    end

    should "03the valid_file? method be private" do
      logger = MarkusLogger.instance
      assert_raise NoMethodError do
        logger.valid_file?(@infolog)
      end
    end

    should "03initialize correctly and raise no exceptions" do
      assert_nothing_raised do
        logger = MarkusLogger.instance
      end
   end

    should "03raise exception if log level is above the FATAL level" do
      log_level = MarkusLogger::FATAL + 1
      assert_raise ArgumentError do
        logger = MarkusLogger.instance
        logger.log("test", log_level)
      end
    end

    should "03raise exception if log level is below the DEBUG level" do
      log_level = MarkusLogger::DEBUG - 1
      assert_raise ArgumentError do
        logger = MarkusLogger.instance
        logger.log("test", log_level)
      end
    end

    should "03rotate infologs when @size bytes of data is reached" do
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

    should "03rotate errorlogs when @size bytes of data is reached" do
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
end
