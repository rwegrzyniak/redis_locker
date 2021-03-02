# frozen_string_literal: true
require 'zeitwerk'

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

loader = Zeitwerk::Loader.for_gem
loader.setup
loader.eager_load
