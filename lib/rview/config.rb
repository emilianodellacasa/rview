# frozen_string_literal: true

require 'yaml'

module Rview
  class Config
    FILE_NAME = '.rview.yml'

    DEFAULT_TOOLING_PATHS = {
      coverage: ['coverage/.last_run.json'].freeze,
      smells: ['gl-code-quality-report.json', 'tmp/gl-code-quality-report.json'].freeze,
      security: ['gl-sast-report.json', 'tmp/gl-sast-report.json'].freeze
    }.freeze

    def self.load(repo_path)
      raw = begin
        YAML.safe_load_file(File.join(repo_path, FILE_NAME))
      rescue Errno::ENOENT, Psych::SyntaxError
        nil
      end
      new(raw.is_a?(Hash) ? raw : {})
    end

    def initialize(raw = {})
      @raw = raw
    end

    # Candidate report paths (relative to the repo) for :coverage, :smells or :security.
    # Accepts a string or an array of strings in the config; anything else falls
    # back to the defaults for that metric.
    def tooling_paths(key)
      tooling = @raw['tooling']
      value = tooling.is_a?(Hash) ? tooling[key.to_s] : nil
      candidates = Array(value).select { |p| p.is_a?(String) && !p.empty? }
      candidates.empty? ? DEFAULT_TOOLING_PATHS.fetch(key) : candidates
    end
  end
end
