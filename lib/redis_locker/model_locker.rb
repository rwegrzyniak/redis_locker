module RedisLocker
  class ModelLocker < RedisLocker::Locker
    include RedisConnection

    attr_reader :key_string


    def initialize(model_instance)
      raise Errors::NotModel unless model_instance.respond_to?(:id)

      @key_string = "LOCKER:#{model_instance.class}:#{model_instance.id}"
      super
    end

    def lock
      return false if locked?

      redis.sadd(@key_string, @instance_hash)
    end

    def lock!
      raise Errors::AlreadyLocked if locked?

      lock
    end

    def locked?
      redis.scard(@key_string) > 1 # it has to have NULL_SET_VALUE, otherwise redis will free key
    end

    def unlock
      return true unless locked?

      redis.srem(@key_string, @instance_hash)
    end

    private

  end
end
