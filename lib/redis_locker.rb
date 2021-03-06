# frozen_string_literal: true
#
require "zeitwerk"

module RedisLocker
  STRATEGIES = %i[exception retry silently_die].freeze
  DEFAULT_RETRY_COUNT = 3
  DEFAULT_RETRY_INTERVAL = 1
  MODEL_LOCK_STRING = "model_lock"
  DEFAULT_STRATEGY = :exception
  DEFAULT_EXCLUDED_METHODS = %i[id initialize].freeze
  class << self
    def configuration
      @configuration ||= Configuration.new
    end

    def configure
      yield(configuration)
    end

    def release_locks!
      configuration.redis_connection.del(configuration.redis_connection.keys("LOCKER:*"))
    end


  end

  def self.included(base_klass)
    base_klass.extend(ClassMethods)
    base_klass.include(InstanceMethods)
    interceptor = base_klass.const_set("#{base_klass.name.split('::').last}Interceptor", Module.new)
    base_klass.prepend interceptor
  end

  module ClassMethods
    def lock_every_method_call(strategy: DEFAULT_STRATEGY, retry_count: DEFAULT_RETRY_COUNT, retry_interval: DEFAULT_RETRY_INTERVAL,
                               exclude: DEFAULT_EXCLUDED_METHODS)
      interceptor = self.const_get("#{name.split('::').last}Interceptor")
      self.define_singleton_method(:method_added) do |method|
        return super(method) if exclude.include? method

        interceptor.define_method(method) do |*args, **opts, &block|
          returned_value = nil
          method_locker(method).with_redis_lock strategy: strategy, retry_count: retry_count, retry_interval: retry_interval do
            returned_value = super(*args, **opts, &block)
          end
          returned_value
        end
      end
    end

    def lock_method(method, strategy: DEFAULT_STRATEGY, retry_count: DEFAULT_RETRY_COUNT, retry_interval: DEFAULT_RETRY_INTERVAL)
      interceptor = self.const_get("#{name.split('::').last}Interceptor")
      interceptor.define_method(method) do |*args, **opts, &block|
        returned_value = nil
        method_locker(method).with_redis_lock strategy: strategy, retry_count: retry_count, retry_interval: retry_interval do
          returned_value = super(*args, **opts, &block)
        end
        returned_value
      end
    end
  end

  module InstanceMethods
    def method_locker(method)
      method_lockers[method] ||= RedisLocker::MethodLocker.new(model_locker, method)
    end

    def lock
      model_locker.lock
    end

    def lock!
      model_locker.lock!
    end

    def unlock
      model_locker.unlock
    end

    def with_redis_lock(strategy: RedisLocker::DEFAULT_STRATEGY, retry_count: RedisLocker::DEFAULT_RETRY_COUNT,
                        retry_interval: RedisLocker::DEFAULT_RETRY_INTERVAL, &block)
      model_locker.with_redis_lock(strategy: strategy, retry_count: retry_count, retry_interval: retry_interval, &block)
    end

    private

    def method_lockers
      @method_lockers ||= {}
    end

    def model_locker
      @model_locker ||= RedisLocker::ModelLocker.new(self)
    end
  end



end

loader = Zeitwerk::Loader.for_gem
loader.setup
loader.eager_load
