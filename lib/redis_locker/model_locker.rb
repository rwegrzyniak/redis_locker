module RedisLocker
  class ModelLocker
    include RedisConnection


    def initialize(model_instance)
      raise Errors::NotModel unless model_instance.respond_to?(:id)

      @model_string = "#{model_instance.class}:#{model_instance.id}"
    end

    def lock
      return false if locked?

      redis.hset(@model_string)
      true
    end

    def lock!
      raise Errors::AlreadyLocked if locked?

      redis.hset(@model_string)
      true
    end

    def locked?
      redis.key?(@model_string)
    end

  end
end
