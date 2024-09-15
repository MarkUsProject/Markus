# frozen_string_literal: true

require_relative "config/attr_accessors"
require_relative "config/attr_inheritance"
require_relative "config/attr_type_coercion"

module Net
  class IMAP

    # Net::IMAP::Config stores configuration options for Net::IMAP clients.
    # The global configuration can be seen at either Net::IMAP.config or
    # Net::IMAP::Config.global, and the client-specific configuration can be
    # seen at Net::IMAP#config.
    #
    # When creating a new client, all unhandled keyword arguments to
    # Net::IMAP.new are delegated to Config.new.  Every client has its own
    # config.
    #
    #   debug_client = Net::IMAP.new(hostname, debug: true)
    #   quiet_client = Net::IMAP.new(hostname, debug: false)
    #   debug_client.config.debug?  # => true
    #   quiet_client.config.debug?  # => false
    #
    # == Inheritance
    #
    # Configs have a parent[rdoc-ref:Config::AttrInheritance#parent] config, and
    # any attributes which have not been set locally will inherit the parent's
    # value.  Every client creates its own specific config.  By default, client
    # configs inherit from Config.global.
    #
    #   plain_client = Net::IMAP.new(hostname)
    #   debug_client = Net::IMAP.new(hostname, debug: true)
    #   quiet_client = Net::IMAP.new(hostname, debug: false)
    #
    #   plain_client.config.inherited?(:debug)  # => true
    #   debug_client.config.inherited?(:debug)  # => false
    #   quiet_client.config.inherited?(:debug)  # => false
    #
    #   plain_client.config.debug?  # => false
    #   debug_client.config.debug?  # => true
    #   quiet_client.config.debug?  # => false
    #
    #   # Net::IMAP.debug is delegated to Net::IMAP::Config.global.debug
    #   Net::IMAP.debug = true
    #   plain_client.config.debug?  # => true
    #   debug_client.config.debug?  # => true
    #   quiet_client.config.debug?  # => false
    #
    #   Net::IMAP.debug = false
    #   plain_client.config.debug = true
    #   plain_client.config.inherited?(:debug)  # => false
    #   plain_client.config.debug?  # => true
    #   plain_client.config.reset(:debug)
    #   plain_client.config.inherited?(:debug)  # => true
    #   plain_client.config.debug?  # => false
    #
    # == Versioned defaults
    #
    # The effective default configuration for a specific +x.y+ version of
    # +net-imap+ can be loaded with the +config+ keyword argument to
    # Net::IMAP.new.  Requesting default configurations for previous versions
    # enables extra backward compatibility with those versions:
    #
    #   client = Net::IMAP.new(hostname, config: 0.3)
    #   client.config.sasl_ir                  # => false
    #   client.config.responses_without_block  # => :silence_deprecation_warning
    #
    #   client = Net::IMAP.new(hostname, config: 0.4)
    #   client.config.sasl_ir                  # => true
    #   client.config.responses_without_block  # => :silence_deprecation_warning
    #
    #   client = Net::IMAP.new(hostname, config: 0.5)
    #   client.config.sasl_ir                  # => true
    #   client.config.responses_without_block  # => :warn
    #
    #   client = Net::IMAP.new(hostname, config: :future)
    #   client.config.sasl_ir                  # => true
    #   client.config.responses_without_block  # => :raise
    #
    # The versioned default configs inherit certain specific config options from
    # Config.global, for example #debug:
    #
    #   client = Net::IMAP.new(hostname, config: 0.4)
    #   Net::IMAP.debug = false
    #   client.config.debug?  # => false
    #
    #   Net::IMAP.debug = true
    #   client.config.debug?  # => true
    #
    # Use #load_defaults to globally behave like a specific version:
    #   client = Net::IMAP.new(hostname)
    #   client.config.sasl_ir              # => true
    #   Net::IMAP.config.load_defaults 0.3
    #   client.config.sasl_ir              # => false
    #
    # === Named defaults
    # In addition to +x.y+ version numbers, the following aliases are supported:
    #
    # [+:default+]
    #   An alias for +:current+.
    #
    #   >>>
    #   *NOTE*: This is _not_ the same as Config.default.  It inherits some
    #   attributes from Config.global, for example: #debug.
    # [+:current+]
    #   An alias for the current +x.y+ version's defaults.
    # [+:next+]
    #   The _planned_ config for the next +x.y+ version.
    # [+:future+]
    #   The _planned_ eventual config for some future +x.y+ version.
    #
    # For example, to raise exceptions for all current deprecations:
    #   client = Net::IMAP.new(hostname, config: :future)
    #   client.responses  # raises an ArgumentError
    #
    # == Thread Safety
    #
    # *NOTE:* Updates to config objects are not synchronized for thread-safety.
    #
    class Config
      # Array of attribute names that are _not_ loaded by #load_defaults.
      DEFAULT_TO_INHERIT = %i[debug].freeze
      private_constant :DEFAULT_TO_INHERIT

      # The default config, which is hardcoded and frozen.
      def self.default; @default end

      # The global config object.  Also available from Net::IMAP.config.
      def self.global; @global if defined?(@global) end

      # A hash of hard-coded configurations, indexed by version number.
      def self.version_defaults; @version_defaults end
      @version_defaults = {}

      # :call-seq:
      #  Net::IMAP::Config[number] -> versioned config
      #  Net::IMAP::Config[symbol] -> named config
      #  Net::IMAP::Config[hash]   -> new frozen config
      #  Net::IMAP::Config[config] -> same config
      #
      # Given a version number, returns the default configuration for the target
      # version.  See Config@Versioned+defaults.
      #
      # Given a version name, returns the default configuration for the target
      # version.  See Config@Named+defaults.
      #
      # Given a Hash, creates a new _frozen_ config which inherits from
      # Config.global.  Use Config.new for an unfrozen config.
      #
      # Given a config, returns that same config.
      def self.[](config)
        if    config.is_a?(Config)         then config
        elsif config.nil? && global.nil?   then nil
        elsif config.respond_to?(:to_hash) then new(global, **config).freeze
        else
          version_defaults.fetch(config) do
            case config
            when Numeric
              raise RangeError, "unknown config version: %p" % [config]
            when Symbol
              raise KeyError, "unknown config name: %p" % [config]
            else
              raise TypeError, "no implicit conversion of %s to %s" % [
                config.class, Config
              ]
            end
          end
        end
      end

      include AttrAccessors
      include AttrInheritance
      include AttrTypeCoercion

      # The debug mode (boolean)
      #
      # The default value is +false+.
      attr_accessor :debug, type: :boolean

      # method: debug?
      # :call-seq: debug? -> boolean
      #
      # Alias for #debug

      # Seconds to wait until a connection is opened.
      #
      # If the IMAP object cannot open a connection within this time,
      # it raises a Net::OpenTimeout exception.
      #
      # See Net::IMAP.new.
      #
      # The default value is +30+ seconds.
      attr_accessor :open_timeout, type: Integer

      # Seconds to wait until an IDLE response is received, after
      # the client asks to leave the IDLE state.
      #
      # See Net::IMAP#idle and Net::IMAP#idle_done.
      #
      # The default value is +5+ seconds.
      attr_accessor :idle_response_timeout, type: Integer

      # :markup: markdown
      #
      # Whether to use the +SASL-IR+ extension when the server and \SASL
      # mechanism both support it.
      #
      # See Net::IMAP#authenticate.
      #
      # | Starting with version | The default value is                     |
      # |-----------------------|------------------------------------------|
      # | _original_            | +false+ <em>(extension unsupported)</em> |
      # | v0.4                  | +true+  <em>(support added)</em>         |
      attr_accessor :sasl_ir, type: :boolean

      # :markup: markdown
      #
      # Controls the behavior of Net::IMAP#responses when called without a
      # block.  Valid options are `:warn`, `:raise`, or
      # `:silence_deprecation_warning`.
      #
      # | Starting with version   | The default value is           |
      # |-------------------------|--------------------------------|
      # | v0.4.13                 | +:silence_deprecation_warning+ |
      # | v0.5 <em>(planned)</em> | +:warn+                        |
      # | _eventually_            | +:raise+                       |
      attr_accessor :responses_without_block, type: [
        :silence_deprecation_warning, :warn, :raise,
      ]

      # Creates a new config object and initialize its attribute with +attrs+.
      #
      # If +parent+ is not given, the global config is used by default.
      #
      # If a block is given, the new config object is yielded to it.
      def initialize(parent = Config.global, **attrs)
        super(parent)
        update(**attrs)
        yield self if block_given?
      end

      # :call-seq: update(**attrs) -> self
      #
      # Assigns all of the provided +attrs+ to this config, and returns +self+.
      #
      # An ArgumentError is raised unless every key in +attrs+ matches an
      # assignment method on Config.
      #
      # >>>
      #   *NOTE:*  #update is not atomic.  If an exception is raised due to an
      #   invalid attribute value, +attrs+ may be partially applied.
      def update(**attrs)
        unless (bad = attrs.keys.reject { respond_to?(:"#{_1}=") }).empty?
          raise ArgumentError, "invalid config options: #{bad.join(", ")}"
        end
        attrs.each do send(:"#{_1}=", _2) end
        self
      end

      # :call-seq:
      #   with(**attrs) -> config
      #   with(**attrs) {|config| } -> result
      #
      # Without a block, returns a new config which inherits from self.  With a
      # block, yields the new config and returns the block's result.
      #
      # If no keyword arguments are given, an ArgumentError will be raised.
      #
      # If +self+ is frozen, the copy will also be frozen.
      def with(**attrs)
        attrs.empty? and
          raise ArgumentError, "expected keyword arguments, none given"
        copy = new(**attrs)
        copy.freeze if frozen?
        block_given? ? yield(copy) : copy
      end

      # :call-seq: load_defaults(version) -> self
      #
      # Resets the current config to behave like the versioned default
      # configuration for +version+.  #parent will not be changed.
      #
      # Some config attributes default to inheriting from their #parent (which
      # is usually Config.global) and are left unchanged, for example: #debug.
      #
      # See Config@Versioned+defaults and Config@Named+defaults.
      def load_defaults(version)
        [Numeric, Symbol, String].any? { _1 === version } or
          raise ArgumentError, "expected number or symbol, got %p" % [version]
        update(**Config[version].defaults_hash)
      end

      # :call-seq: to_h -> hash
      #
      # Returns all config attributes in a hash.
      def to_h; data.members.to_h { [_1, send(_1)] } end

      protected

      def defaults_hash
        to_h.reject {|k,v| DEFAULT_TO_INHERIT.include?(k) }
      end

      @default = new(
        debug: false,
        open_timeout: 30,
        idle_response_timeout: 5,
        sasl_ir: true,
        responses_without_block: :silence_deprecation_warning,
      ).freeze

      @global = default.new

      version_defaults[0.4] = Config[default.send(:defaults_hash)]

      version_defaults[0] = Config[0.4].dup.update(
        sasl_ir: false,
      ).freeze
      version_defaults[0.0] = Config[0]
      version_defaults[0.1] = Config[0]
      version_defaults[0.2] = Config[0]
      version_defaults[0.3] = Config[0]

      version_defaults[0.5] = Config[0.4].dup.update(
        responses_without_block: :warn,
      ).freeze

      version_defaults[:default] = Config[0.4]
      version_defaults[:current] = Config[0.4]
      version_defaults[:next]    = Config[0.5]

      version_defaults[:future]  = Config[0.5].dup.update(
        responses_without_block: :raise,
      ).freeze

      version_defaults.freeze
    end
  end
end
