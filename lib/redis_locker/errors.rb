module RedisLocker
  module Errors

    class Error < StandardError; end

    class NotModel < Error
      def message
        "Model doesn't have id field"
      end
    end

    class AlreadyLocked < Error; end

    class ModelLocked < Error; end

    class NotValidRedisConnection < StandardError; end
  end
end
