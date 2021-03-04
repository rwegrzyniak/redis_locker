module RedisLocker
  module Errors

    class Error < StandardError; end

    class NotModel < Error
      def message
        "Model doesn't have id method"
      end
    end

    class AlreadyLocked < Error; end

    class ModelLocked < Error; end

    class NotValidRedisConnection < Error; end

    class UnknownStrategy < Error; end

    class Locked < Error; end

    class MaxRetryCountAchieved < Error; end
  end
end
