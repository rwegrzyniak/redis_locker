module RedisLocker
  class Locker
    NULL_SET_VALUE = -420
    def initialize(*_args)
      raise Errors::KeyStringNotSet unless @key_string.is_a?(String)

      setup_redis_set
      loop do
        @instance_hash = rand(36**8).to_s(36)
        break unless redis.sismember(@key_string, @instance_hash)
      end
    end

    def lock
      raise NotImplementedError, '#lock has to be implemented'
    end

    def lock!
      raise NotImplementedError, '#lock! has to be implemented'
    end

    def locked?
      raise NotImplementedError, '#locked? has to be implemented'
    end

    def with_redis_lock(strategy: RedisLocker::DEFAULT_STRATEGY, retry_count: RedisLocker::DEFAULT_RETRY_COUNT,
                        retry_interval: RedisLocker::DEFAULT_RETRY_INTERVAL, &block)
      raise Errors::UnknownStrategy unless RedisLocker::STRATEGIES.include? strategy

      return respond_to_lock(strategy: strategy, retry_count: retry_count, retry_interval: retry_interval, &block) if locked?

      lock_result = strategy == :exception ? lock! : lock # delegates throwing exception to lock!
      return unless lock_result

      begin
        yield if block
      rescue Exception => e
        unlock
        raise e
      end
      unlock # unlock returns true if everything is ok
    end

    private

    def respond_to_lock(**args, &block)
      raise Errors::Locked if args[:strategy] == :exception
      return false if args[:strategy] == :silently_die

      # otherwise strategy is retry
      args[:retry_count] -= 1
      raise Errors::MaxRetryCountAchieved if args[:retry_count].negative?

      sleep(args[:retry_interval])
      with_redis_lock(**args, &block)
    end

    def setup_redis_set
      return if redis.exists?(@key_string)

      redis.sadd(@key_string, NULL_SET_VALUE)
    end

  end
end
