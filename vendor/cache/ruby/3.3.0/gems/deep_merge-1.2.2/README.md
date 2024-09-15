DeepMerge
=========

[![Gem Version](https://badge.fury.io/rb/deep_merge.svg)](http://badge.fury.io/rb/deep_merge)
[![CI](https://github.com/danielsdeleo/deep_merge/actions/workflows/ci.yaml/badge.svg)](https://github.com/danielsdeleo/deep_merge/actions/workflows/ci.yaml)

Deep Merge is a simple set of utility functions for Hash. It permits you to merge elements inside a hash together recursively. The manner by which it does this is somewhat arbitrary (since there is no defining standard for this) but it should end up being pretty intuitive and do what you expect.

You can learn a lot more about this by reading the test file. It's pretty well documented and has many examples of various merges from very simple to pretty complex.

The primary need that caused me to write this library is the merging of elements coming from HTTP parameters and related stored parameters in session. This lets a user build up a set of parameters over time, modifying individual items.

Deep Merge Core Documentation
=============================

`deep_merge!` method permits merging of arbitrary child elements. The two top level elements must be hashes. These hashes can contain unlimited (to stack limit) levels of child elements. These child elements to not have to be of the same types. Where child elements are of the same type, `deep_merge` will attempt to merge them together. Where child elements are not of the same type, `deep_merge` will skip or optionally overwrite the destination element with the contents of the source element at that level. So if you have two hashes like this:

    source = {:x => [1,2,3], :y => 2}
    dest =   {:x => [4,5,'6'], :y => [7,8,9]}
    dest.deep_merge!(source)
    Results: {:x => [1,2,3,4,5,'6'], :y => 2}

By default, `deep_merge!` will overwrite any unmergeables and merge everything else. To avoid this, use `deep_merge` (no bang/exclamation mark)

Options
-------

Options are specified in the last parameter passed, which should be in hash format:

    hash.deep_merge!({:x => [1,2]}, {:knockout_prefix => '--'})
    :preserve_unmergeables  DEFAULT: false
      Set to true to skip any unmergeable elements from source
    :knockout_prefix        DEFAULT: nil
      Set to string value to signify prefix which deletes elements from existing element
    :overwrite_arrays       DEFAULT: false
      Set to true if you want to avoid merging arrays
    :sort_merged_arrays     DEFAULT: false
      Set to true to sort all arrays that are merged together
    :unpack_arrays          DEFAULT: nil
      Set to string value to run "Array::join" then "String::split" against all arrays
    :merge_hash_arrays      DEFAULT: false
      Set to true to merge hashes within arrays
    :extend_existing_arrays DEFAULT: false
      Set to true to extend existing arrays, instead of overwriting them
    :keep_array_duplicates  DEFAULT: false
      Set to true to keep duplicate entries in arrays, instead of coalescing them
    :merge_nil_values       DEFAULT: false
      Set to true to merge nil hash values, overwriting a possibly non-nil value
    :merge_debug            DEFAULT: false
      Set to true to get console output of merge process for debugging

Selected Options Details
------------------------

**:knockout_prefix**

The purpose of this is to provide a way to remove elements from existing Hash by specifying them in a special way in incoming hash

    source = {:x => ['--1', '2']}
    dest   = {:x => ['1', '3']}
    dest.ko_deep_merge!(source)
    Results: {:x => ['2','3']}

Additionally, if the knockout_prefix is passed alone as a string, it will cause the entire element to be removed:

    source = {:x => '--'}
    dest   = {:x => [1,2,3]}
    dest.ko_deep_merge!(source)
    Results: {:x => ""}

**:overwrite_arrays**
The purpose of this is to provide a way to replace Arrays instead of having them merge together.

    source = {:x => ['1', '2']}
    dest   = {:x => ['3', '4']}
    dest.deep_merge!(source, {:overwrite_arrays => true})
    Results: {:x => ['1', '2']}

**:unpack_arrays**
The purpose of this is to permit compound elements to be passed in as strings and to be converted into discrete array elements

    irsource = {:x => ['1,2,3', '4']}
    dest   = {:x => ['5','6','7,8']}
    dest.deep_merge!(source, {:unpack_arrays => ','})
    Results: {:x => ['1','2','3','4','5','6','7','8'}

Why: If receiving data from an HTML form, this makes it easy for a checkbox to pass multiple values from within a single HTML element

**:merge_hash_arrays**

merge hashes within arrays

    source = {:x => [{:y => 1}]}
    dest   = {:x => [{:z => 2}]}
    dest.deep_merge!(source, {:merge_hash_arrays => true})
    Results: {:x => [{:y => 1, :z => 2}]}

**:extend_existing_arrays**

Push src elements to existing arrays, instead of overwriting them.

    source = { "property" => "4" }
    dest   = { "property" => ["1", "2", "3"] }
    dest.deep_merge!(source, {:extend_existing_arrays => true})
    Results: {"property" => ["1", "2", "3", "4"]}

**:keep_array_duplicates**

Keeps duplicate entries in arrays, instead of coalescing them.

Without this setting:

    source = { "property" => ["2", "3"] }
    dest   = { "property" => ["1", "2"] }
    dest.deep_merge!(source)
    Results: {"property" => ["1", "2", "3"]}

With this setting:

    source = { "property" => ["1", "2"] }
    dest   = { "property" => ["2", "3"] }
    dest.deep_merge!(source, {:keep_array_duplicates => true})
    Results: {"property" => ["1", "2", "2", "3"]}

**:merge_nil_values**

The purpose of this option is to allow nil hash values to be merged.  The prior behavior was to discard nil hash values and remains the default if not specified.

    source = {"item" => nil}
    dest   = {"item" => "existing"}
    dest.deep_merge!(source, {:merge_nil_values => true})
    Results: {"item" => nil}

There are many tests for this library - and you can learn more about the features and usages of deep_merge! by just browsing the test examples.

Using deep_merge in Rails
=========================

To avoid conflict with ActiveSupport, load deep_merge via:

    require 'deep_merge/rails_compat'

In a Gemfile:

    gem "deep_merge", :require => 'deep_merge/rails_compat'

The deep_merge methods will then be defined as

    Hash#deeper_merge
    Hash#deeper_merge!
    Hash#ko_deeper_merge!

Simple Example Code
===================

    require 'deep_merge'
    x = {:x => [3,4,5]}
    y = {:x => [1,2,3]}
    y.deep_merge!(x)
    # results: y = {:x => [1,2,3,4,5]}

Availability
============

`deep_merge` was written by Steve Midgley, and is now maintained by Daniel DeLeo. The official home of `deep_merge` on the internet is now https://github.com/danielsdeleo/deep_merge

Copyright (c) 2008-2016 Steve Midgley, released under the MIT license
