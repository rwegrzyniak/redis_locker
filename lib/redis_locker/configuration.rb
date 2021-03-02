module RedisLocker
  class Configuration
    class NotValidRedisConnection < StandardError; end
    attr_reader :redis_connection

    def redis_connection=(redis_conn)
      raise NotValidRedisConnection unless redis_conn.is_a?(Redis)

      @redis_connection = redis_conn
    end
  end
end
