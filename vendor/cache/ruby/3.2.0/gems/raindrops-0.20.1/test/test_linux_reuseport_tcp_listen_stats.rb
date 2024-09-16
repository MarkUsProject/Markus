# -*- encoding: binary -*-
require "./test/rack_unicorn"
require 'test/unit'
require 'socket'
require 'raindrops'
$stderr.sync = $stdout.sync = true

class TestLinuxReuseportTcpListenStats < Test::Unit::TestCase
  include Raindrops::Linux
  include Unicorn::SocketHelper
  TEST_ADDR = ENV['UNICORN_TEST_ADDR'] || '127.0.0.1'
  DEFAULT_BACKLOG = 10

  def setup
    @socks = []
  end

  def teardown
    @socks.each { |io| io.closed? or io.close }
  end

  def new_socket_server(**kwargs)
    s = new_tcp_server TEST_ADDR, kwargs[:port] || 0, kwargs
    s.listen(kwargs[:backlog] || DEFAULT_BACKLOG)
    @socks << s
    [ s, s.addr[1] ]
  end

  def new_client(port)
    s = TCPSocket.new("127.0.0.1", port)
    @socks << s
    s
  end

  def test_reuseport_queue_stats
    listeners = 10
    _, port = new_socket_server(reuseport: true)
    addr = "#{TEST_ADDR}:#{port}"
    (listeners - 1).times do
      new_socket_server(reuseport: true, port: port)
    end

    listeners.times do |i|
      all = Raindrops::Linux.tcp_listener_stats
      assert_equal [0, i], all[addr].to_a
      new_client(port)
      all = Raindrops::Linux.tcp_listener_stats
      assert_equal [0, i+1], all[addr].to_a
    end
  end
end if RUBY_PLATFORM =~ /linux/
