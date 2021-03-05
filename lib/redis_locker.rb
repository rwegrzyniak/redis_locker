# frozen_string_literal: true
#
require "zeitwerk"

module RedisLocker
  STRATEGIES = %i[exception retry silently_die].freeze
  DEFAULT_RETRY_COUNT = 3
  DEFAULT_RETRY_INTERVAL = 1
  MODEL_LOCK_STRING = "model_lock"
  DEFAULT_STRATEGY = :exception
  DEFAULT_EXCLUDED_METHODS = %i[id initialize]
  class << self
    def configuration
      @configuration ||= Configuration.new
    end

    def configure
      yield(configuration)
    end
  end

  def self.included(base_klass)
    base_klass.extend(ClassMethods)
    base_klass.include(InstanceMethods)
    interceptor = const_set("#{base_klass.name}Interceptor", Module.new)
    interceptor.class_eval do
      def initialize(*args, **opts, &block)
        @model_locker = RedisLocker::ModelLocker.new(self)
        @method_lockers = {}
        super(*args, **opts, &block)
      end
    end
    base_klass.prepend interceptor
  end

  module ClassMethods
    def lock_every_method_call(strategy: DEFAULT_STRATEGY, retry_count: DEFAULT_RETRY_COUNT, retry_interval: DEFAULT_RETRY_INTERVAL,
                               exclude: DEFAULT_EXCLUDED_METHODS)
      interceptor = const_get("#{self.name}Interceptor")
      self.define_singleton_method(:method_added) do |method|
        return super(method) if exclude.include? method

        interceptor.define_method(method) do |*args, **opts, &block|
          returned_value = nil
          puts "locking #{method}"
          method_locker(method).with_redis_lock do
            returned_value = super(*args, **opts, &block)
          end
          puts "unlocked = #{method}"
          returned_value
        end
      end
    end
  end

  module InstanceMethods
    def method_locker(method)
      @method_lockers[method] ||= RedisLocker::MethodLocker.new(@model_locker, method)
    end
  end



end

loader = Zeitwerk::Loader.for_gem
loader.setup
loader.eager_load
