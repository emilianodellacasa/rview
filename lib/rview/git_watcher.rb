# frozen_string_literal: true

require 'open3'
require 'listen'

module Rview
  class GitWatcher
    # Replaces Listen's default silencer (which ignores all of .git) so that
    # index/HEAD/refs changes (git add, commit, checkout, branch) still wake
    # us up, while .git internals churn (objects, logs, locks) stays silenced.
    LISTEN_IGNORES = [
      Listen::Silencer::DEFAULT_IGNORED_EXTENSIONS, # editor swap/temp files
      # Listen's DEFAULT_IGNORED_FILES minus the .git entry:
      %r{\A(?:\.svn|\.hg|\.rbx|\.bundle|bundle|vendor/bundle|log|tmp|vendor/ruby|\#.+\#|\.\#.+)(/|\z)}x,
      # inside .git, allow only the paths that affect `git status` output:
      %r{\A\.git/
         (?!(?:index|HEAD|ORIG_HEAD|MERGE_HEAD|FETCH_HEAD|packed-refs)\z
            |refs(?:/|\z)
            |info/exclude\z)}x
    ].freeze

    attr_reader :repo_path

    def initialize(repo_path = Dir.pwd)
      @repo_path = repo_path
      @mutex = Mutex.new
      @files = []
      @diffs = {}
      @dirty = true # the first refresh after construction populates the UI
      @fallback_polling = false
    end

    def start
      Listen.logger = Logger.new(IO::NULL) # never write to the TUI's stderr
      @listener = Listen.to(@repo_path, ignore!: LISTEN_IGNORES) { |_mod, _add, _rem| mark_dirty }
      @listener.start
    rescue StandardError
      # e.g. inotify watch limit exceeded: degrade to the old
      # refresh-on-every-tick behavior, functionality preserved.
      @listener = nil
      @fallback_polling = true
    end

    def stop
      @listener&.stop
      @listener = nil
    end

    def mark_dirty
      @mutex.synchronize { @dirty = true }
    end

    def refresh(force: false)
      return nil unless force || take_dirty!

      files = fetch_status
      diffs = {}
      files.each do |file_status|
        diffs[file_status.path] = fetch_diff(file_status)
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

    # Consume the flag BEFORE fetching: an event landing during the fetch
    # re-dirties the watcher and gets picked up on the next tick.
    def take_dirty!
      @mutex.synchronize do
        dirty = @dirty || @fallback_polling
        @dirty = false
        dirty
      end
    end

    def fetch_status
      stdout, _stderr, _status = Open3.capture3(
        'git', 'status', '--porcelain',
        chdir: @repo_path
      )
      DiffParser.parse_status(stdout)
    end

    def fetch_diff(file_status)
      path = file_status.path

      case file_status.status_code
      when '?'
        stdout, _stderr, _status = Open3.capture3(
          'git', 'diff', '--no-index', File::NULL, path,
          chdir: @repo_path
        )
        stdout
      when 'A'
        stdout, _stderr, _status = Open3.capture3(
          'git', 'diff', '--cached', '--', path,
          chdir: @repo_path
        )
        stdout
      else
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
end
