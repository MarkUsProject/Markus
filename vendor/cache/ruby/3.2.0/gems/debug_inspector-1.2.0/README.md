[![Build Status](https://github.com/banister/debug_inspector/actions/workflows/test.yml/badge.svg)](https://github.com/banister/debug_inspector/actions/workflows/test.yml)
[![Gem Version](https://img.shields.io/gem/v/debug_inspector.svg)](https://rubygems.org/gems/debug_inspector)

debug_inspector
===============

_A Ruby wrapper for the Ruby 2.0+ debug_inspector C API_

The `debug_inspector` C extension and API were designed and built by [Koichi Sasada](https://github.com/ko1), this project
is just a gemification of his work.

**NOTES:**

* **Do not use this library outside of debugging situations**.
* This library makes use of the debug inspector API which was new in CRuby 2.0.0.
* Only works on CRuby 2+ and TruffleRuby. Requiring it on unsupported Rubies will result in a no-op.

Usage
-----

```ruby
require 'debug_inspector'

# Open debug context
# Passed `dc' is only active in a block
DebugInspector.open { |dc|
  # backtrace locations (returns an array of Thread::Backtrace::Location objects)
  locs = dc.backtrace_locations

  # you can get depth of stack frame with `locs.size'
  locs.size.times do |i|
    # binding of i-th caller frame (returns a Binding object or nil)
    p dc.frame_binding(i)

    # iseq of i-th caller frame (returns a RubyVM::InstructionSequence object or nil)
    p dc.frame_iseq(i)

    # class of i-th caller frame
    p dc.frame_class(i)
  end
}
```

Development
-----------

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`.
To release a new version, update the version number in `version.rb` and in `debug_inspector.gemspec`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

Contact
-------

Problems or questions contact me at [github](http://github.com/banister)

License
-------

The `debug_inspector` is released under the [MIT License](https://opensource.org/licenses/MIT).
