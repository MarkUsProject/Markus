
class NArray
end

unless Math.respond_to?(:log2)
  def Math.log2(num)
    Math.log(num, 2)
  end
end

module Histogram
  DEFAULT_BIN_METHOD = :scott
  DEFAULT_QUARTILE_METHOD = :moore_mccabe

  class << self
    # returns (min, max)
    def minmax(obj)
      if obj.is_a?(Array)
        obj.minmax
      else
        mn = obj[0]
        mx = obj[0]
        obj.each do |val|
          if val < mn then mn = val end
          if val > mx then mx = val end
        end
        [mn, mx]
      end
    end

    # returns (mean, standard_dev)
    # if size == 0 returns [nil, nil]
    def sample_stats(obj)
      _len = obj.size
      return [nil, nil] if _len == 0
      _sum = 0.0 ; _sum_sq = 0.0
      obj.each do |val|
        _sum += val
        _sum_sq += val * val
      end
      std_dev = _sum_sq - ((_sum * _sum)/_len)
      std_dev /= ( _len > 1 ? _len-1 : 1 )
      sqrt_of_std_dev =
        begin
          Math.sqrt(std_dev)
        rescue Math::DomainError
          0.0
        end
      [_sum.to_f/_len, sqrt_of_std_dev]
    end

    # opts:
    #
    #     defaults:
    #     :method => :moore_mccabe, :tukey
    #     :sorted => false
    #
    def iqrange(obj, opts={})
      opt = {:method => DEFAULT_QUARTILE_METHOD, :sorted => false}.merge( opts )
      srted = opt[:sorted] ? obj : obj.sort
      sz = srted.size
      return 0 if sz == 1
      answer =
        case opt[:method]
        when :tukey
          hi_idx = sz / 2
          lo_idx = (sz % 2 == 0) ? hi_idx-1 : hi_idx
          median(srted[hi_idx..-1]) - median(srted[0..lo_idx])
        when :moore_mccabe
          hi_idx = sz / 2
          lo_idx = hi_idx - 1
          hi_idx += 1 unless sz.even?
          median(srted[hi_idx..-1]) - median(srted[0..lo_idx])
        else
          raise ArgumentError, "method must be :tukey or :moore_mccabe"
        end
      answer.to_f
    end

    # finds median on a pre-sorted array
    def median(sorted)
      return sorted[0] if sorted.size == 1
      (sorted[(sorted.size - 1) / 2] + sorted[sorted.size / 2]) / 2.0
    end
  end

  # returns(integer) takes :scott|:sturges|:fd|:middle
  #
  # middle is the median between the other three values
  #
  # Note: always returns 1 if all values are the same.
  #
  # inspired by {Richard Cotton's matlab
  # implementation}[http://www.mathworks.com/matlabcentral/fileexchange/21033-calculate-number-of-bins-for-histogram]
  # and the {histogram page on
  # wikipedia}[http://en.wikipedia.org/wiki/Histogram]
  def number_of_bins(methd=DEFAULT_BIN_METHOD, quartile_method=DEFAULT_QUARTILE_METHOD)
    return 1 if self.to_a.uniq.size == 1

    if methd == :middle
      [:scott, :sturges, :fd].map {|v| number_of_bins(v) }.sort[1]
    else
      nbins =
        case methd
        when :scott
          range = (self.max - self.min).to_f
          (mean, stddev) = Histogram.sample_stats(self)
          if stddev == 0.0
            1
          else
            range / ( 3.5*stddev*(self.size**(-1.0/3)) )
          end
        when :sturges
          1 + Math::log2(self.size)
        when :fd
          2 * Histogram.iqrange(self, :method => quartile_method) * (self.size**(-1.0/3))
        end
      if nbins > self.size || nbins.to_f.nan? || nbins <= 0
        nbins = 1
      end
      nbins.ceil.to_i
    end
  end

  # Returns [bins, freqs]
  #
  # histogram(bins, opts)
  # histogram(opts)
  #
  # Options:
  #
  #     :bins => :scott    Scott's method    range/(3.5σ * n^(-1/3))
  #              :fd       Freedman-Diaconis range/(2*iqrange *n^(-1/3)) (default)
  #              :sturges  Sturges' method   log_2(n) + 1 (overly smooth for n > 200)
  #              :middle   the median between :fd, :scott, and :sturges
  #              <Integer> give the number of bins
  #              <Array>   specify the bins themselves
  #
  #     :bin_boundary  => :avg      boundary is the avg between bins (default)
  #                       :min      bins specify the minima for binning
  #
  #     :bin_width => <float> width of a bin (overrides :bins)
  #     :min => <float> # explicitly set the min
  #     :max => <float> # explicitly set the max val
  #
  #     :other_sets => an array of other sets to histogram
  #
  # Examples
  #
  #    require 'histogram/array'
  #    ar = [-2,1,2,3,3,3,4,5,6,6]
  #    # these return: [bins, freqencies]
  #    ar.histogram(20)                  # use 20 bins
  #    ar.histogram([-3,-1,4,5,6], :bin_boundary => :avg) # custom bins
  #
  #    # returns [bins, freq1, freq2 ...]
  #    (bins, *freqs) = ar.histogram(30, :bin_boundary => :avg, :other_sets => [3,3,4,4,5], [-1,0,0,3,3,6])
  #    (ar_freqs, other1, other2) = freqs
  #
  #    # histogramming with weights
  #    w_weights.histogram(20, :weights => [3,3,8,8,9,9,3,3,3,3])
  #
  #    # with NArray
  #    require 'histogram/narray'
  #    NArray.float(20).random!(3).histogram(20)
  #       # => [bins, freqs]  # are both NArray.float objects
  #
  # Notes
  #
  # * The lowest bin will be min, highest bin the max unless array given.
  # * Assumes that bins are increasing.
  # * :avg means that the boundary between the specified bins is at the avg
  #   between the bins (rounds up )
  # * :min means that to fit in the bin it must be >= the bin and < the next
  #   (so, values lower than first bin are not included, but all values
  #   higher, than last bin are included.  Current implementation of custom
  #   bins is slow.
  # * If the number of bins must be determined and all values are the same,
  #   will use 1 bin.
  # * if other_sets are supplied, the same bins will be used for all the sets.
  #   It is useful if you just want a certain number of bins and for the sets
  #   to share the exact same bins. In this case returns [bins, freqs(caller),
  #   freqs1, freqs2 ...]
  # * Can also deal with weights.  :weights should provide parallel arrays to
  #   the caller and any :other_sets provided.
  def histogram(*args)
    make_freqs_proc = lambda do |obj, len|
      if obj.is_a?(Array)
        Array.new(len, 0.0)
      elsif obj.is_a?(NArray)
        NArray.float(len)
      end
    end

    case args.size
    when 2
      (bins, opts) = args
    when 1
      arg = args.shift
      if arg.is_a?(Hash)
        opts = arg
      else
        bins = arg
        opts = {}
      end
    when 0
      opts = {}
      bins = nil
    else
      raise ArgumentError, "accepts no more than 2 args"
    end

    opts = ({ :bin_boundary => :avg, :other_sets => [] }).merge(opts)

    bins = opts[:bins] if opts[:bins]
    bins = DEFAULT_BIN_METHOD unless bins

    bin_boundary = opts[:bin_boundary]
    other_sets = opts[:other_sets]

    bins_array_like = bins.kind_of?(Array) || bins.kind_of?(NArray) || opts[:bin_width]
    all = [self] + other_sets

    if bins.is_a?(Symbol)
      bins = number_of_bins(bins)
    end

    weights =
      if opts[:weights]
        have_frac_freqs = true
        opts[:weights][0].is_a?(Numeric) ? [ opts[:weights] ] : opts[:weights]
      else
        []
      end

    # we need to know the limits of the bins if we need to define our own bins
    if opts[:bin_width] || !bins_array_like
      calc_min, calc_max =
        unless opts[:min] && opts[:max]
          (mins, maxs) = all.map {|ar| Histogram.minmax(ar) }.transpose
          [mins.min, maxs.max]
        end
    end
    _min = opts[:min] || calc_min
    _max = opts[:max] || calc_max

    if opts[:bin_width]
      bins = []
      _min.step(_max, opts[:bin_width]) {|v| bins << v }
    end

    _bins = nil
    _freqs = nil
    if bins_array_like
      ########################################################
      # ARRAY BINS:
      ########################################################
      _bins =
        if bins.is_a?(Array)
          bins.map {|v| v.to_f }
        elsif bins.is_a?(NArray)
          bins.to_f
        end
      case bin_boundary
      when :avg
        freqs_ar = all.zip(weights).map do |xvals, yvals|

          _freqs = make_freqs_proc.call(xvals, bins.size)

          break_points = []
          (0...(bins.size)).each do |i|
            bin = bins[i]
            break if i == (bins.size - 1)
            break_points << avg_ints(bin,bins[i+1])
          end
          (0...(xvals.size)).each do |i|
            val = xvals[i]
            height = have_frac_freqs ? yvals[i] : 1
            if val < break_points.first
              _freqs[0] += height
            elsif val >= break_points.last
              _freqs[-1] += height
            else
              (0...(break_points.size-1)).each do |i|
                if val >= break_points[i] && val < break_points[i+1]
                  _freqs[i+1] += height
                  break
                end
              end
            end
          end
          _freqs
        end
      when :min
        freqs_ar = all.zip(weights).map do |xvals, yvals|

          #_freqs = VecI.new(bins.size, 0)
          _freqs = make_freqs_proc.call(xvals, bins.size)
          (0...(xvals.size)).each do |i|
            val = xvals[i]
            height = have_frac_freqs ? yvals[i] : 1
            last_i = 0
            last_found_j = false
            (0...(_bins.size)).each do |j|
              if val >= _bins[j]
                last_found_j = j
              elsif last_found_j
                break
              end
            end
            if last_found_j ; _freqs[last_found_j] += height ; end
          end
          _freqs
        end
      end
    else
      ########################################################
      # NUMBER OF BINS:
      ########################################################
      # Create the scaling factor
      dmin = _min.to_f
      min_equals_max = _max == _min
      conv = min_equals_max ? 0 : bins.to_f/(_max - _min)

      _bins =
        if self.is_a?(Array)
          Array.new(bins)
        elsif self.is_a?(NArray)
          NArray.float(bins)
        end

      freqs_ar = all.zip(weights).map do |xvals, yvals|

        # initialize arrays
        _freqs = make_freqs_proc.call(xvals, bins)
        _len = size

        # Create the histogram:
        (0...(xvals.size)).each do |i|
          val = xvals[i]
          height = have_frac_freqs ? yvals[i] : 1
          index = ((val-_min)*conv).floor
          if index == bins
            index -= 1
          end
          _freqs[index] += height
        end
        _freqs
      end

      # Create the bins:
      iconv = 1.0/conv
      case bin_boundary
      when :avg
        if min_equals_max
          set_bin_value = self.to_a.inject(0.0) {|sum, val| sum + val } / self.size
        end
        (0...bins).each do |i|
          _bins[i] = min_equals_max ? set_bin_value : ((i+0.5) * iconv) + dmin
        end
      when :min
        if min_equals_max
          set_bin_value = self.min
        end
        (0...bins).each do |i|
          _bins[i] = min_equals_max ? set_bin_value : (i * iconv) + dmin
        end
      end
    end
    [_bins] + freqs_ar
  end

  def avg_ints(one, two) # :nodoc:
    (one.to_f + two.to_f) / 2.0
  end

end



