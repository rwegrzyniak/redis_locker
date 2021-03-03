RSpec.describe RedisLocker::ModelLocker do

  describe '#initialize' do
    context "object passed doesnt has :id method" do
      let(:dummy_object) { Class.new.new }
      it "raises error" do
        expect { described_class.new(dummy_object) }.to raise_error(RedisLocker::Errors::NotModel)
      end
    end
    context "object passed has :id method" do
      let(:dummy_object) {
        Class.new do
          def id
            10
          end
        end.new
      }
      it "doesn't raise error" do
        expect { described_class.new(dummy_object) }.to_not raise_error
      end
    end
  end
  configure_with_redis_mock
  describe "#lock" do
    let(:dummy_object) {
      Class.new do
        def id
          10
        end
      end.new
    }
    subject { described_class.new(dummy_object) }
    before do
    end
    context "object locked first time" do
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
  describe "#lock!" do
    let(:dummy_object) {
      Class.new do
        def id
          10
        end
      end.new
    }
    subject { described_class.new(dummy_object) }
    before do
    end
    context "object locked first time" do
      it "returns true" do
        expect(subject.lock!).to be true
      end
    end
    context "object locked second time" do
      it "returns false" do
        subject.lock
        expect { subject.lock! }.to raise_error(RedisLocker::Errors::AlreadyLocked)
      end
    end
  end
  describe "#locked?" do
    let(:dummy_object) {
      Class.new do
        def id
          10
        end
      end.new
    }
    subject { described_class.new(dummy_object) }
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
  end
  describe "#unlock" do
    let(:dummy_object) {
      Class.new do
        def id
          10
        end
      end.new
    }
    subject { described_class.new(dummy_object) }
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
  end
end
