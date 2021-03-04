module RedisLocker
  class MethodLocker < RedisLocker::Locker
    include RedisConnection

    def initialize(model_locker, method_name)
      @model_locker = model_locker
      @key_string = "#{model_locker.key_string}:#{method_name}"
      super
    end

    def lock
      return false if locked?

      @model_locker.lock
      redis.sadd(@key_string, @instance_hash)
    end

    def lock!
      raise Errors::AlreadyLocked if locked?

      @model_locker.lock!
      lock
    end

    def locked?
      redis.scard(@key_string) > 1
    end

    def unlock
      return true unless locked?

      (redis.srem(@key_string, @instance_hash) && @model_locker.unlock)
    end

  end
end
