# frozen_string_literal: true

require 'spec_helper'
require 'tmpdir'

RSpec.describe Rview::Config do
  let(:repo_path) { Dir.mktmpdir('rview-repo') }

  after { FileUtils.remove_entry(repo_path) }

  def write_config(content)
    File.write(File.join(repo_path, described_class::FILE_NAME), content)
  end

  describe '.load' do
    it 'returns the default paths when .rview.yml is missing' do
      config = described_class.load(repo_path)
      expect(config.tooling_paths(:coverage)).to eq(['coverage/.last_run.json'])
      expect(config.tooling_paths(:smells)).to eq(['gl-code-quality-report.json', 'tmp/gl-code-quality-report.json'])
      expect(config.tooling_paths(:security)).to eq(['gl-sast-report.json', 'tmp/gl-sast-report.json'])
    end

    it 'reads custom paths from the tooling section' do
      write_config(<<~YAML)
        tooling:
          coverage: reports/coverage.json
          smells: reports/rubocop.json
          security: reports/brakeman.json
      YAML

      config = described_class.load(repo_path)
      expect(config.tooling_paths(:coverage)).to eq(['reports/coverage.json'])
      expect(config.tooling_paths(:smells)).to eq(['reports/rubocop.json'])
      expect(config.tooling_paths(:security)).to eq(['reports/brakeman.json'])
    end

    it 'accepts a list of candidate paths' do
      write_config(<<~YAML)
        tooling:
          smells:
            - ci/rubocop.json
            - rubocop.json
      YAML

      config = described_class.load(repo_path)
      expect(config.tooling_paths(:smells)).to eq(['ci/rubocop.json', 'rubocop.json'])
    end

    it 'falls back to defaults for metrics not present in the file' do
      write_config(<<~YAML)
        tooling:
          coverage: reports/coverage.json
      YAML

      config = described_class.load(repo_path)
      expect(config.tooling_paths(:coverage)).to eq(['reports/coverage.json'])
      expect(config.tooling_paths(:smells)).to eq(['gl-code-quality-report.json', 'tmp/gl-code-quality-report.json'])
    end

    it 'falls back to defaults when the YAML is malformed' do
      write_config('tooling: [unclosed')
      config = described_class.load(repo_path)
      expect(config.tooling_paths(:coverage)).to eq(['coverage/.last_run.json'])
    end

    it 'falls back to defaults for non-string values' do
      write_config(<<~YAML)
        tooling:
          coverage: 42
      YAML

      config = described_class.load(repo_path)
      expect(config.tooling_paths(:coverage)).to eq(['coverage/.last_run.json'])
    end
  end
end
