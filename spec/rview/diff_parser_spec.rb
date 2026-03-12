# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Rview::DiffParser do
  describe '.parse_status' do
    it 'returns empty array for nil input' do
      expect(described_class.parse_status(nil)).to eq([])
    end

    it 'returns empty array for empty input' do
      expect(described_class.parse_status('')).to eq([])
      expect(described_class.parse_status("   \n")).to eq([])
    end

    it 'parses a modified file' do
      result = described_class.parse_status(" M lib/foo.rb\n")
      expect(result.length).to eq(1)
      expect(result.first.path).to eq('lib/foo.rb')
      expect(result.first.status_code).to eq('M')
    end

    it 'parses a staged added file' do
      result = described_class.parse_status("A  new_file.rb\n")
      expect(result.length).to eq(1)
      expect(result.first.path).to eq('new_file.rb')
      expect(result.first.status_code).to eq('A')
    end

    it 'parses a deleted file' do
      result = described_class.parse_status(" D old_file.rb\n")
      expect(result.length).to eq(1)
      expect(result.first.path).to eq('old_file.rb')
      expect(result.first.status_code).to eq('D')
    end

    it 'parses untracked files' do
      result = described_class.parse_status("?? untracked.rb\n")
      expect(result.length).to eq(1)
      expect(result.first.path).to eq('untracked.rb')
      expect(result.first.status_code).to eq('?')
    end

    it 'parses renamed files' do
      result = described_class.parse_status("R  old.rb -> new.rb\n")
      expect(result.length).to eq(1)
      expect(result.first.path).to eq('new.rb')
      expect(result.first.original_path).to eq('old.rb')
      expect(result.first.status_code).to eq('R')
    end

    it 'parses multiple files' do
      input = " M lib/foo.rb\n?? spec/bar_spec.rb\nA  new.rb\n"
      result = described_class.parse_status(input)
      expect(result.length).to eq(3)
    end
  end

  describe '.colorize' do
    it 'returns empty array for nil input' do
      expect(described_class.colorize(nil)).to eq([])
    end

    it 'returns empty array for empty input' do
      expect(described_class.colorize('')).to eq([])
    end

    it 'classifies added lines' do
      result = described_class.colorize("+added line\n")
      expect(result.first[1]).to eq(:diff_add)
    end

    it 'classifies removed lines' do
      result = described_class.colorize("-removed line\n")
      expect(result.first[1]).to eq(:diff_remove)
    end

    it 'classifies hunk headers' do
      result = described_class.colorize("@@ -1,3 +1,4 @@\n")
      expect(result.first[1]).to eq(:diff_hunk)
    end

    it 'classifies diff headers' do
      result = described_class.colorize("diff --git a/foo.rb b/foo.rb\n")
      expect(result.first[1]).to eq(:diff_header)
    end

    it 'classifies +++ and --- as headers, not add/remove' do
      result = described_class.colorize("--- a/foo.rb\n+++ b/foo.rb\n")
      expect(result[0][1]).to eq(:diff_header)
      expect(result[1][1]).to eq(:diff_header)
    end

    it 'classifies context lines as normal' do
      result = described_class.colorize(" context line\n")
      expect(result.first[1]).to eq(:normal)
    end

    it 'returns [line, style] pairs' do
      result = described_class.colorize("+foo\n-bar\n")
      expect(result[0]).to eq(['+foo', :diff_add])
      expect(result[1]).to eq(['-bar', :diff_remove])
    end
  end
end
