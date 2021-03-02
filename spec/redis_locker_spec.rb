# frozen_string_literal: true

RSpec.describe RedisLocker do
  it "has a version number" do
    expect(RedisLocker::VERSION).not_to be nil
  end

  describe "configuration by configure with a block" do
    let(:redis) { instance_double(Redis) }
    it "allows to pass block" do
      expect { |b| RedisLocker.configure(&b) }.to yield_with_args
    end
    describe "setting redis connection" do
      context "proper redis client passed" do
        it "properly saves redis connection" do
          allow(redis).to receive(:is_a?).with(Redis).and_return(true)
          RedisLocker.configure do |config|
            config.redis_connection = redis
          end
          expect(RedisLocker.configuration.redis_connection).to eq(redis)
        end
      end
      context "invalid redis connection passed" do
        it "rasies an exception" do
          allow(redis).to receive(:is_a?).with(Redis).and_return(false)
          expect{
            RedisLocker.configure do |config|
              config.redis_connection = redis
            end
          }.to raise_error(RedisLocker::Errors::NotValidRedisConnection)
        end
      end
    end
  end
end
