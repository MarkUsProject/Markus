# -*- encoding: binary -*-
#
# Each Raindrops object is a container that holds several counters.
# It is internally a page-aligned, shared memory area that allows
# atomic increments, decrements, assignments and reads without any
# locking.
#
#   rd = Raindrops.new 4
#   rd.incr(0, 1)   -> 1
#   rd.to_ary       -> [ 1, 0, 0, 0 ]
#
# Unlike many classes in this package, the core Raindrops class is
# intended to be portable to all reasonably modern *nix systems
# supporting mmap().  Please let us know if you have portability
# issues, patches or pull requests at mailto:raindrops-public@yhbt.net
class Raindrops

  # Used to represent the number of +active+ and +queued+ sockets for
  # a single listen socket across all threads and processes on a
  # machine.
  #
  # For TCP listeners, only sockets in the TCP_ESTABLISHED state are
  # accounted for.  For Unix domain listeners, only CONNECTING and
  # CONNECTED Unix domain sockets are accounted for.
  #
  # +active+ connections is the number of accept()-ed but not-yet-closed
  # sockets in all threads/processes sharing the given listener.
  #
  # +queued+ connections is the number of un-accept()-ed sockets in the
  # queue of a given listen socket.
  #
  # These stats are currently only available under \Linux
  class ListenStats < Struct.new(:active, :queued)

    # the sum of +active+ and +queued+ sockets
    def total
      active + queued
    end
  end unless defined? ListenStats

  # call-seq:
  #	Raindrops.new(size, io: nil)	-> raindrops object
  #
  # Initializes a Raindrops object to hold +size+ counters.  +size+ is
  # only a hint and the actual number of counters the object has is
  # dependent on the CPU model, number of cores, and page size of
  # the machine.  The actual size of the object will always be equal
  # or greater than the specified +size+.
  # If +io+ is provided, then the Raindrops memory will be backed by
  # the specified file; otherwise, it will allocate anonymous memory.
  # The IO object must respond to +truncate+, as this is used to set
  # the size of the file.
  # If +zero+ is provided, then the memory region is zeroed prior to
  # returning. This is only meaningful if +io+ is also provided; in
  # that case it controls whether any existing counter values in +io+
  # are retained (false) or whether it is entirely zeroed (true).
  def initialize(size, io: nil, zero: false)
    # This ruby wrapper exists to handle the keyword-argument handling,
    # which is otherwise kind of awkward in C. We delegate the keyword
    # arguments to the _actual_ initialize implementation as positional
    # args.
    initialize_cimpl(size, io, zero)
  end

  autoload :Linux, 'raindrops/linux'
  autoload :Struct, 'raindrops/struct'
  autoload :Middleware, 'raindrops/middleware'
  autoload :Aggregate, 'raindrops/aggregate'
  autoload :LastDataRecv, 'raindrops/last_data_recv'
  autoload :Watcher, 'raindrops/watcher'
end
require 'raindrops_ext'
