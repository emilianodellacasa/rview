# frozen_string_literal: true

require 'json'

module Rview
  class ToolingMetrics
    def initialize(repo_path, baseline: BaselineStore.new(repo_path), config: Config.load(repo_path))
      @repo_path = repo_path
      @baseline = baseline
      @config = config
      @cache = {}
    end

    # => { coverage: { previous:, current: } | nil, smells: ..., security: ... }
    def read
      {
        coverage: @baseline.update(:coverage, coverage),
        smells: @baseline.update(:smells, smells),
        security: @baseline.update(:security, security)
      }
    end

    private

    def coverage
      parse(:coverage, @config.tooling_paths(:coverage)) do |json|
        value = json.dig('result', 'line') || json.dig('result', 'covered_percent')
        value.is_a?(Numeric) ? value.to_f.round(2) : nil
      end
    end

    # CodeClimate / GitLab Code Quality report: a top-level array of issues.
    def smells
      parse(:smells, @config.tooling_paths(:smells)) do |json|
        json.is_a?(Array) ? json.length : nil
      end
    end

    # GitLab SAST report (e.g. semgrep --gitlab-sast): vulnerabilities array.
    def security
      parse(:security, @config.tooling_paths(:security)) do |json|
        vulnerabilities = json['vulnerabilities'] if json.is_a?(Hash)
        vulnerabilities.is_a?(Array) ? vulnerabilities.length : nil
      end
    end

    # mtime-cached defensive JSON read; any failure => nil (rendered as N/A).
    def parse(key, candidates)
      path = candidates.map { |c| File.join(@repo_path, c) }.find { |p| File.file?(p) }
      if path.nil?
        @cache.delete(key)
        return nil
      end

      mtime = File.mtime(path)
      cached = @cache[key]
      return cached[:value] if cached && cached[:path] == path && cached[:mtime] == mtime

      value = begin
        yield JSON.parse(File.read(path))
      rescue JSON::ParserError, TypeError
        nil
      end
      @cache[key] = { path: path, mtime: mtime, value: value }
      value
    rescue Errno::ENOENT
      nil
    end
  end
end
