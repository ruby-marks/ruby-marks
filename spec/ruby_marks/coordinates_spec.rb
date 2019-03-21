require 'spec_helper'

describe RubyMarks::Coordinates do
  describe '#width' do
    subject { described_class.new(x1: 10, x2: 20).width }

    it { is_expected.to eq(11) }
  end

  describe '#height' do
    subject { described_class.new(y1: 10, y2: 20).height }

    it { is_expected.to eq(11) }
  end

  describe '#middle_horizontal' do
    subject { described_class.new(x1: 10, x2: 20).middle_horizontal }

    it { is_expected.to eq(15) }
  end

  describe '#middle_vertical' do
    subject { described_class.new(y1: 10, y2: 20).middle_vertical }

    it { is_expected.to eq(15) }
  end

  describe '#center' do
    subject { described_class.new(x1: 10, y1: 10, x2: 20, y2: 20).center }

    it { is_expected.to include(x: 15, y: 15) }
  end
end
