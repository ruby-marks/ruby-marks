require 'spec_helper'

describe RubyMarks::Recognizer do
  subject { described_class.new }
  let(:file) { fixture_path('demo1.png') }

  before do
    subject.configure do |config|
      config.define_group :one do |group|
        group.expected_coordinates = { x1: 145, y1: 780, x2: 270, y2: 1290 }
      end

      config.define_group :two do |group|
        group.expected_coordinates = { x1: 370, y1: 780, x2: 500, y2: 1290 }
      end

      config.define_group :three do |group|
        group.expected_coordinates = { x1: 595, y1: 780, x2: 720, y2: 1290 }
      end

      config.define_group :four do |group|
        group.expected_coordinates = { x1: 820, y1: 780, x2: 950, y2: 1290 }
      end

      config.define_group :five do |group|
        group.expected_coordinates = { x1: 1045, y1: 780, x2: 1170, y2: 1290 }
      end
    end

    subject.file = file
  end

  describe '#filename' do
    it { expect(subject.filename).to eq(file) }
  end

  describe '#configure' do
    before do
      subject.configure do |config|
        config.threshold_level = 70
        config.default_marks_options = %w[1 2 3]

        config.define_group :one

        config.define_group :two do |group|
          group.marks_options = %w[X Y Z]
        end
      end
    end

    it { expect(subject.config.threshold_level).to eq(70) }
    it { expect(subject.groups[:one].marks_options).to eq(%w[1 2 3]) }
    it { expect(subject.groups[:two].marks_options).to eq(%w[X Y Z]) }
  end

  describe '#flag_all_marks' do
    let(:expected_file) { subject.flag_all_marks }

    it { expect(expected_file.class).to eq(Magick::Image) }
  end

  describe '#scan' do
    let(:expected_hash) do
      {
        one: { 1 => ['A'], 2 => ['B'], 3 => ['C'], 4 => ['D'], 5 => ['E'] },
        two: { 1 => ['A'], 2 => ['B'], 3 => ['C'], 4 => ['D'], 5 => ['E'] },
        three: { 2 => ['B'], 3 => ['D'], 4 => ['D'] }
      }
    end

    it 'scans fixture document' do
      result = subject.scan
      result.each_pair do |_group, lines|
        lines.delete_if { |_line, value| value.empty? }
      end
      result.delete_if { |_group, lines| lines.empty? }

      expect(result).to eq(expected_hash)
    end
  end

  describe '#add_watcher' do
    let(:file) { fixture_path('invalid.png') }

    context 'incorrect group watcher' do
      before do
        subject.file = file
        subject.add_watcher :incorrect_group_watcher
        subject.scan
      end

      it { expect(subject.raised_watchers).to include(:incorrect_group_watcher) }
    end

    context 'timeout  watcher' do
      before do
        subject.configure do |config|
          config.scan_timeout = 1
        end
        subject.file = file
        subject.add_watcher :timed_out_watcher
        subject.scan
      end

      it { expect(subject.raised_watchers).to include(:timed_out_watcher) }
    end
  end
end
