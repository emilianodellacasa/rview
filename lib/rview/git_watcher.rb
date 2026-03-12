# frozen_string_literal: true

require 'open3'

module Rview
  class GitWatcher
    attr_reader :repo_path

    def initialize(repo_path = Dir.pwd)
      @repo_path = repo_path
      @mutex = Mutex.new
      @files = []
      @diffs = {}
    end

    def start; end

    def stop; end

    def refresh
      files = fetch_status
      diffs = {}
      files.each do |file_status|
        diffs[file_status.path] = fetch_diff(file_status.path)
      end

      @mutex.synchronize do
        @files = files
        @diffs = diffs
      end

      [files, diffs]
    end

    def cached_diff(path)
      @mutex.synchronize { @diffs[path] }
    end

    private

    def fetch_status
      stdout, _stderr, _status = Open3.capture3(
        'git', 'status', '--porcelain',
        chdir: @repo_path
      )
      DiffParser.parse_status(stdout)
    end

    def fetch_diff(path)
      stdout, _stderr, status = Open3.capture3(
        'git', 'diff', 'HEAD', '--', path,
        chdir: @repo_path
      )

      if status.success? && !stdout.strip.empty?
        stdout
      else
        stdout2, _stderr2, _status2 = Open3.capture3(
          'git', 'diff', '--', path,
          chdir: @repo_path
        )
        stdout2
      end
    end
  end
end
