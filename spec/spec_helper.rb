# frozen_string_literal: true

require "redis_locker"
require "redis"
require "mock_redis"

Dir[File.join(__dir__, 'support', '*.rb')].each { |file| require file; puts "loded #{file}" }

MockRedis.class_eval do
  def is_a?(klass)
    return true if klass.to_s == 'Redis'
    super
  end
end
def configure_with_redis_mock
  RedisLocker.configure do |config|
    config.redis_connection = MockRedis.new
  end
end

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end
