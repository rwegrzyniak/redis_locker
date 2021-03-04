RSpec.describe RedisLocker::MethodLocker do
  configure_with_redis_mock
  let(:dummy_object) {
    Class.new do
      def id
        10
      end
      def method; end

    end.new
  }
  let(:model_locker) {
    RedisLocker::ModelLocker.new(dummy_object)
  }
  subject { described_class.new(model_locker, :method) }

  describe "#lock" do
    before do

    end
    after do
      subject.unlock
    end
    context "method locked first time" do
      it "returns true" do
        expect(subject.lock).to be true
      end
    end
    context "object locked second time" do
      it "returns false" do
        subject.lock
        expect(subject.lock).to be false
      end
    end
  end
  describe "#locked?" do
    context "object isnt locked" do
      it "return false" do
        expect(subject.locked?).to be false
      end
    end
    context "object locked" do
      before do
        subject.lock
      end
      it "returns true" do
        expect(subject.locked?).to be true
      end
    end
    context "object locked by another instance" do
      before do
        another_instance = described_class.new(model_locker, :method)
        another_instance.lock
      end
      it "returns true" do
        expect(subject.locked?).to be true
      end
    end

  end
  describe "#unlock" do
    context "object isnt locked" do
      it "returns true" do
        expect(subject.unlock).to be true
      end
      it "keeps object unlocked" do
        subject.unlock
        expect(subject.locked?).to be false
      end
    end
    context "object locked" do
      before do
        subject.lock
      end
      it "returns true" do
        expect(subject.unlock).to be true
      end
      it "unlocks object" do
        subject.unlock
        expect(subject.locked?).to be false
      end
    end
    context "object locked by another_instance" do
      before do
        another_instance = described_class.new(model_locker, :method)
        another_instance.lock
      end
      it "returns false" do
        expect(subject.unlock).to be false
      end
      it "doesn't unlocks object" do
        subject.unlock
        expect(subject.locked?).to be true
      end
    end
  end

  it_should_behave_like "locker", RedisLocker::ModelLocker.new(Class.new { def id; 10; end}.new), :method
end
