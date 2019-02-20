require 'spec_helper'

describe RubyMarks::ImageUtils do
  subject { described_class }

  describe '#calc_width' do
    it { expect(subject.calc_width(10, 20)).to eq(11) }
  end

  describe '#calc_height' do
    it { expect(subject.calc_height(10, 20)).to eq(11) }
  end

  describe '#calc_middle_horizontal' do
    it { expect(subject.calc_middle_horizontal(10, 11)).to eq(15) }
  end

  describe '#calc_middle_horizontal' do
    it { expect(subject.calc_middle_vertical(10, 11)).to eq(15) }
  end

  describe '#to_hex' do
    it 'return the white_color in hexa when receive 8 bits rgb' do
      expect(subject.to_hex(255, 255, 255)).to eq('#FFFFFF')
    end

    it 'return the white_color in hexa when receive 16 bits rgb' do
      expect(subject.to_hex(65_535, 65_535, 65_535)).to eq('#FFFFFF')
    end
  end
end
