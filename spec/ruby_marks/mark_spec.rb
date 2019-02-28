require 'spec_helper'

module RubyMarks
  describe Mark do
    describe '#marked?' do
      context 'When not image_str' do
        let(:mark) { described_class.new(image_str: nil) }

        subject { mark.marked? RubyMarks.intensity_percentual }

        it { is_expected.to be_nil }
      end

      context 'When image_str is present' do
        let(:intensity) { spy(:intensity) }
        let(:mark) { described_class.new(image_str: double) }

        before { allow(mark).to receive(:intensity).and_return(intensity) }

        it 'checks if intensity >= intensity_percentage' do
          mark.marked? RubyMarks.intensity_percentual

          expect(intensity).to have_received(:>=).with(RubyMarks.intensity_percentual)
        end
      end
    end

    describe '#intensity' do
      context 'When not image_str' do
        let(:mark) { described_class.new(image_str: nil) }

        subject { mark.intensity }

        it { is_expected.to be_nil }
      end

      context 'When image_str is present' do
        let(:image_str) { spy(:mark_str) }

        before do
          allow(image_str).to receive(:count).with('.').and_return(51_658)
          allow(image_str).to receive(:size).and_return(191_280_3)
        end

        subject { described_class.new(image_str: image_str).intensity }

        it { is_expected.to eq(image_str.count('.') * 100 / image_str.size) }
      end
    end
  end
end
