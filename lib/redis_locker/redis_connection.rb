# frozen_string_literal: true

module RedisLocker
  module RedisConnection
    private

    def redis
      @redis ||= RedisLocker.configuration.redis_connection
    end
  end
end
