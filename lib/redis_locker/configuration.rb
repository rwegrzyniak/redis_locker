module RedisLocker
  class Configuration
    attr_reader :redis_connection

    def redis_connection=(redis_conn)
      raise Errors::NotValidRedisConnection unless redis_conn.is_a?(Redis)

      @redis_connection = redis_conn
    end
  end
end
