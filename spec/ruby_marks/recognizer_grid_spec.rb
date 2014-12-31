require "spec_helper"


describe RubyMarks::Recognizer do
  subject { described_class.new }
  let(:file) { fixture_path('grid.png') }

  before do
    subject.configure do |config|
      config.scan_mode = :grid
      config.edge_level = 4
      config.default_expected_lines = 5
      config.intensity_percentual = 45
      config.default_mark_height = 26
      config.default_mark_width = 26
      config.auto_ajust_block_width = :right
      config.default_block_width_tolerance = 10

      config.define_group :um do |group|
        group.expected_coordinates = {x1: 160, y1: 235, x2: 285, y2: 360}
      end

      config.define_group :dois do |group|
        group.expected_coordinates = {x1: 350, y1: 235, x2: 475, y2: 360}
      end

      config.define_group :tres do |group|
        group.expected_coordinates = {x1: 570, y1: 235, x2: 695, y2: 360}
      end

      config.define_group :quatro do |group|
        group.expected_coordinates = {x1: 790, y1: 235, x2: 915, y2: 360}
      end

      config.define_group :cinco do |group|
        group.expected_coordinates = {x1: 1010, y1: 235, x2: 1135, y2: 360}
      end
    end

    subject.file = file
  end

  describe "#flag_all_marks" do
    let(:expected_file) { subject.flag_all_marks }

    it { expect(expected_file.class).to eq(Magick::Image) }
  end

  describe "#scan" do
    let(:expected_hash) do
      {
        um:     { 1 => ['A'], 2 => ['A'], 3 => ['D'], 4 => ['B'], 5 => ['B'] },
        dois:   { 1 => ['B'], 2 => ['A'], 3 => ['A'], 4 => ['A'], 5 => ['D'] },
        tres:   { 1 => ['A'], 2 => ['B'], 3 => ['A'], 4 => ['A'], 5 => ['D'] },
        quatro: { 1 => ['B'], 2 => ['D'], 3 => ['A'], 4 => ['C'], 5 => ['C'] },
        cinco:  { 1 => ['C'], 2 => ['D'], 3 => ['A'], 4 => ['C'], 5 => ['C'] }
      }
    end

    it { expect(subject.scan).to eq(expected_hash) }
  end
end
