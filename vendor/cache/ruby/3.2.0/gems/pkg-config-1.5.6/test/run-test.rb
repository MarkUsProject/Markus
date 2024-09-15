#!/usr/bin/env ruby

$VERBOSE = true

base_dir = File.expand_path(File.join(File.dirname(__FILE__), ".."))
lib_dir = File.join(base_dir, "lib")
test_dir = File.join(base_dir, "test")

require 'test-unit'

$LOAD_PATH.unshift(lib_dir)

exit Test::Unit::AutoRunner.run(true)
