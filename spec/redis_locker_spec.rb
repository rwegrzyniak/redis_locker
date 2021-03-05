# frozen_string_literal: true

RSpec.describe RedisLocker do
  it "has a version number" do
    expect(RedisLocker::VERSION).not_to be nil
  end

  describe "configuration by configure with a block" do
    let(:redis) { instance_double(Redis) }
    after do
      RedisLocker.instance_variable_set('@configuration', nil)
    end
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
  TEST_RETURNED_VALUE = 123
  describe '#lock_every_method_call' do
    class TestedClass
      include RedisLocker
      lock_every_method_call strategy: :exception
      def id
        10
      end
      def test
        TEST_RETURNED_VALUE
      end
      def test_with_arguments(first, keyword_arg: )
        first + keyword_arg
      end
      def multithread_test
        until $stop_thread do
          sleep 0.1
        end
        puts "stopped"
      end
      def stop_multithread_test
        sleep 0.2
        $stop_thread = true
        TEST_RETURNED_VALUE
      end
    end

    before do
      configure_with_redis_mock
    end

    let(:test_object) { TestedClass.new }
    context "only locked method called" do
      it "returns same value as method without locker" do
        expect(test_object.test).to eq(TEST_RETURNED_VALUE)
      end

      it "passes arguments to orginal method" do
        expect(test_object.test_with_arguments(TEST_RETURNED_VALUE, keyword_arg: TEST_RETURNED_VALUE)).to eq(2*TEST_RETURNED_VALUE)
      end

      it "raise_error when method is locked" do
        object_locker = test_object.instance_variable_get('@model_locker')
        another_method_locker_instance = RedisLocker::MethodLocker.new(object_locker, :test)
        another_method_locker_instance.lock
        expect{test_object.test}.to raise_error(RedisLocker::Errors::Locked)
        another_method_locker_instance.unlock
      end
    end
    context "another method called in same time" do
      it "doesnt lock other methods" do
        $stop_thread = false
        t = Thread.new { test_object.multithread_test}
        expect{ test_object.stop_multithread_test }.to_not raise_exception
        t.join
      end
    end
    it "locks object" do
      $stop_thread = false
      t = Thread.new { test_object.multithread_test}
      expect(test_object.instance_variable_get('@model_locker').locked?).to be true
      test_object.stop_multithread_test
      t.join
    end
  end
end
