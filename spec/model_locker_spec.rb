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
        expect { described_class.new(dummy_object) }.to_not raise_error(RedisLocker::Errors::NotModel)
      end
    end
  end
end
