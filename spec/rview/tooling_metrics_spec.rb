# frozen_string_literal: true

require 'spec_helper'
require 'tmpdir'

RSpec.describe Rview::ToolingMetrics do
  let(:repo_path) { Dir.mktmpdir('rview-repo') }
  let(:data_dir) { Dir.mktmpdir('rview-data') }
  let(:baseline) { Rview::BaselineStore.new(repo_path, data_dir: data_dir) }

  subject(:metrics) { described_class.new(repo_path, baseline: baseline) }

  after do
    FileUtils.remove_entry(repo_path)
    FileUtils.remove_entry(data_dir)
  end

  def write_report(relative_path, content)
    path = File.join(repo_path, relative_path)
    FileUtils.mkdir_p(File.dirname(path))
    File.write(path, content)
    path
  end

  describe '#read' do
    it 'returns nil for every metric when no report exists' do
      expect(metrics.read).to eq(coverage: nil, smells: nil, security: nil)
    end

    it 'reads coverage from result.line' do
      write_report('coverage/.last_run.json', '{"result":{"line":96.23}}')
      expect(metrics.read[:coverage]).to eq(previous: 96.23, current: 96.23)
    end

    it 'falls back to result.covered_percent for older SimpleCov output' do
      write_report('coverage/.last_run.json', '{"result":{"covered_percent":88.1}}')
      expect(metrics.read[:coverage]).to eq(previous: 88.1, current: 88.1)
    end

    it 'counts issues in a CodeClimate code quality report' do
      write_report('gl-code-quality-report.json', '[{"description":"a"},{"description":"b"},{"description":"c"}]')
      expect(metrics.read[:smells]).to eq(previous: 3, current: 3)
    end

    it 'reads smells from tmp/gl-code-quality-report.json when the root file is absent' do
      write_report('tmp/gl-code-quality-report.json', '[{"description":"a"}]')
      expect(metrics.read[:smells]).to eq(previous: 1, current: 1)
    end

    it 'returns nil for a code quality report that is not an array' do
      write_report('gl-code-quality-report.json', '{"description":"a"}')
      expect(metrics.read[:smells]).to be_nil
    end

    it 'counts vulnerabilities in a GitLab SAST report' do
      write_report('gl-sast-report.json', '{"version":"15.0.4","vulnerabilities":[{},{}],"scan":{}}')
      expect(metrics.read[:security]).to eq(previous: 2, current: 2)
    end

    it 'reports zero (not N/A) for an empty vulnerabilities array' do
      write_report('gl-sast-report.json', '{"vulnerabilities":[]}')
      expect(metrics.read[:security]).to eq(previous: 0, current: 0)
    end

    it 'returns nil for malformed JSON' do
      write_report('gl-code-quality-report.json', '[not json')
      expect(metrics.read[:smells]).to be_nil
    end

    it 'returns nil for an unexpected JSON shape' do
      write_report('coverage/.last_run.json', '{"result":"oops"}')
      expect(metrics.read[:coverage]).to be_nil
    end

    it 'picks up new values when the report file changes and it is marked dirty' do
      path = write_report('gl-code-quality-report.json', '[{},{},{}]')
      metrics.read

      File.write(path, '[{}]')
      FileUtils.touch(path, mtime: Time.now + 5)
      metrics.mark_dirty
      expect(metrics.read[:smells]).to eq(previous: 3, current: 1)
    end

    it 'returns cached values while the report file is unchanged' do
      write_report('gl-code-quality-report.json', '[{},{},{}]')
      metrics.read
      expect(metrics.read[:smells]).to eq(previous: 3, current: 3)
    end

    it 'does not touch the filesystem again until marked dirty' do
      path = write_report('gl-code-quality-report.json', '[{},{},{}]')
      metrics.read

      File.write(path, '[{}]')
      FileUtils.touch(path, mtime: Time.now + 5)
      expect(metrics.read[:smells]).to eq(previous: 3, current: 3) # cached, not re-read
    end

    it 're-reads when forced even while clean' do
      path = write_report('gl-code-quality-report.json', '[{},{},{}]')
      metrics.read

      File.write(path, '[{}]')
      FileUtils.touch(path, mtime: Time.now + 5)
      expect(metrics.read(force: true)[:smells]).to eq(previous: 3, current: 1)
    end

    it 'reads reports from the paths configured in .rview.yml' do
      write_report('.rview.yml', <<~YAML)
        tooling:
          coverage: reports/cov.json
      YAML
      write_report('reports/cov.json', '{"result":{"line":77.5}}')
      write_report('coverage/.last_run.json', '{"result":{"line":10.0}}')

      expect(metrics.read[:coverage]).to eq(previous: 77.5, current: 77.5)
    end
  end
end
