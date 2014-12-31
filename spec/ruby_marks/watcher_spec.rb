require "spec_helper"

describe RubyMarks::Watcher do
  let(:watcher) { described_class }

  describe "#initialize" do
    context "invalid watcher" do
      subject { described_class.new(:some_invalid_watcher_name) }

      it { expect{subject}.to raise_error(ArgumentError) }
    end
  end
end
