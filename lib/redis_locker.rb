# frozen_string_literal: true

require_relative "redis_locker/version"
require_relative "redis_locker/configuration"
require 'redis'
module RedisLocker
  class Error < StandardError; end
  class << self
    def configuration
      @configuration ||= Configuration.new
    end

    def configure
      yield(configuration)
    end
  end
end
