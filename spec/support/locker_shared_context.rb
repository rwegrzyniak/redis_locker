RSpec.shared_context "locker" do |*subject_constructor_arguments|
  describe "#with_redis_lock" do
    let(:dummy_object) {
      Class.new do
        def id
          10
        end
      end.new
    }
    subject { described_class.new(*subject_constructor_arguments) }
    describe "argument passing" do
      it "raises error when strategy is unknown" do
        expect{ subject.with_redis_lock(strategy: :some_unnknown_strategy)}.to raise_error(RedisLocker::Errors::UnknownStrategy)
      end
    end
    describe "exception strategy" do
      before do
        @success = false
      end
      context "object isnt locked" do
        before do
          subject.with_redis_lock strategy: :exception do
            @success = true
          end
        end
        it "executes passed block" do
          expect(@success).to be true
        end
        it "lefts object unlocked" do
          expect(subject.locked?).to be false
        end
      end
      context "object is locked" do
        before do
          subject.lock
        end
        after do
          subject.unlock
        end
        it "doesnt execute block" do
          expect(@success).to be false
        end
        it "raises exception" do
          expect { subject.with_redis_lock strategy: :exception do @success = true end }.to raise_error(RedisLocker::Errors::Locked)
        end
        it "leaves object locked" do
          begin
            subject.with_redis_lock { @success = true }
          rescue
            nil
          end
          expect(subject.locked?).to be true
        end
      end
    end

    describe "exception from block handling" do
      it "reraise any exception" do
        expect{ subject.with_redis_lock { raise Exception }}.to raise_error(Exception)
      end
      it "unlocks object" do
        expect{ subject.with_redis_lock { raise Exception }}.to raise_error(Exception)
        expect(subject.locked?).to be false
      end
    end

    describe "retry strategy" do
      before do
        @subject_for_retry_test = described_class.new(*subject_constructor_arguments)
        @subject_for_retry_test.instance_eval do
          @sleep_time = 0
          @tries_count = 0

          def reset
            @sleep_time = 0
            @tries_count = 0
          end

          def sleep(int)
            @sleep_time += int
          end

          def with_redis_lock(**args, &block)
            @tries_count += 1
            super(**args, &block)
          end

          def sleep_time
            @sleep_time
          end

          def tries_count
            @tries_count
          end
        end


        @success = false
      end
      context "object isnt locked" do
        before do
          @subject_for_retry_test.with_redis_lock strategy: :retry do
            @success = true
          end
        end
        it "executes passed block" do
          expect(@success).to be true
        end
        it "leaves object unlocked" do
          expect(@subject_for_retry_test.locked?).to be false
        end
      end

      context "object_id is locked" do
        before do
          @subject_for_retry_test.lock
        end
        after do
          @subject_for_retry_test.unlock
        end
        context "default retry_count and retry_interval" do
          before do
            begin
              @subject_for_retry_test.with_redis_lock strategy: :retry do
                @success = true
              end
            rescue
              nil
            end
          end
          it "tries #{RedisLocker::DEFAULT_RETRY_COUNT + 1} times" do
            expect(@subject_for_retry_test.tries_count).to eq(RedisLocker::DEFAULT_RETRY_COUNT + 1) # first try + N retries
          end
          it "sleeps #{RedisLocker::DEFAULT_RETRY_INTERVAL * RedisLocker::DEFAULT_RETRY_COUNT} seconds" do
            expect(@subject_for_retry_test.sleep_time).to eq((RedisLocker::DEFAULT_RETRY_COUNT) * RedisLocker::DEFAULT_RETRY_INTERVAL)
          end
          it "doesnt execute passed block" do
            expect(@success).to be false
          end
        end
        context "non default retry_count" do
          RETRY_COUNT = 8
          before do
            begin
              @subject_for_retry_test.with_redis_lock strategy: :retry, retry_count: RETRY_COUNT do
                @success = true
              end
            rescue
              nil
            end
          end
          it "tries #{ RETRY_COUNT + 1} times" do
            expect(@subject_for_retry_test.tries_count).to eq(RETRY_COUNT + 1) # first try + N retries
          end
          it "sleeps #{RedisLocker::DEFAULT_RETRY_INTERVAL * RETRY_COUNT} seconds" do
            expect(@subject_for_retry_test.sleep_time).to eq(RETRY_COUNT * RedisLocker::DEFAULT_RETRY_INTERVAL)
          end
          it "doesnt execute passed block" do
            expect(@success).to be false
          end
        end
        context "non default interval" do
          RETRY_INTERVAL = 8
          before do
            begin
              @subject_for_retry_test.with_redis_lock strategy: :retry, retry_interval: RETRY_INTERVAL do
                @success = true
              end
            rescue
              nil
            end
          end
          it "tries #{ RedisLocker::DEFAULT_RETRY_COUNT + 1} times" do
            expect(@subject_for_retry_test.tries_count).to eq(RedisLocker::DEFAULT_RETRY_COUNT + 1) # first try + N retries
          end
          it "sleeps #{RETRY_INTERVAL * RedisLocker::DEFAULT_RETRY_COUNT} seconds" do
            expect(@subject_for_retry_test.sleep_time).to eq(RedisLocker::DEFAULT_RETRY_COUNT * RETRY_INTERVAL)
          end
          it "doesnt execute passed block" do
            expect(@success).to be false
          end
        end
      end
    end
    describe "silently_die strategy" do
      before do
        @success = false
      end
      context "object isnt locked" do
        before do
          @result = subject.with_redis_lock strategy: :silently_die do
            @success = true
          end
        end
        it "executes passed block" do
          expect(@success).to be true
        end
        it "lefts object unlocked" do
          expect(subject.locked?).to be false
        end
        it "returns true" do
          expect(@result).to be true
        end
      end
      context "object is locked" do
        before do
          subject.lock
          @result = subject.with_redis_lock strategy: :silently_die do
            @success = true
          end
        end
        after do
          subject.unlock
        end
        it "doesnt execute block" do
          expect(@success).to be false
        end
        it "returns false" do
          expect(@result).to be false
        end
        it "leaves object locked" do
          expect(subject.locked?).to be true
        end
      end
    end
  end
end
