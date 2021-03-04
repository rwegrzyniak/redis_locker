# frozen_string_literal: true
#
require "zeitwerk"

module RedisLocker
  STRATEGIES = %i[exception retry silently_die].freeze
  DEFAULT_RETRY_COUNT = 3
  DEFAULT_RETRY_INTERVAL = 1
  MODEL_LOCK_STRING = "model_lock"
  DEFAULT_STRATEGY = :exception
  class << self
    def configuration
      @configuration ||= Configuration.new
    end

    def configure
      yield(configuration)
    end
  end
end

loader = Zeitwerk::Loader.for_gem
loader.setup
loader.eager_load
