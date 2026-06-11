# frozen_string_literal: true

require 'open3'
require 'listen'

module Rview
  class GitWatcher
    # Listen's DEFAULT_IGNORED_FILES minus the .git entry, as a source string
    # so that exceptions for configured report paths can be spliced in.
    SILENCED_DIRS = '(?:\.svn|\.hg|\.rbx|\.bundle|bundle|vendor/bundle|log|tmp|vendor/ruby|\#.+\#|\.\#.+)(?:/|\z)'

    # Inside .git, allow only the paths that affect `git status` output
    # (git add, commit, checkout, branch), silencing the internals churn.
    GIT_INTERNALS = %r{\A\.git/
                       (?!(?:index|HEAD|ORIG_HEAD|MERGE_HEAD|FETCH_HEAD|packed-refs)\z
                          |refs(?:/|\z)
                          |info/exclude\z)}x

    attr_reader :repo_path

    def initialize(repo_path = Dir.pwd, report_paths: [], on_report_change: nil)
      @repo_path = repo_path
      @report_paths = report_paths
      @on_report_change = on_report_change
      @mutex = Mutex.new
      @files = []
      @diffs = {}
      @dirty = true # the first refresh after construction populates the UI
      @fallback_polling = false
    end

    def start
      Listen.logger = Logger.new(IO::NULL) # never write to the TUI's stderr
      @listener = Listen.to(@repo_path, ignore!: listen_ignores) do |modified, added, removed|
        handle_fs_events(modified + added + removed)
      end
      @listener.start
    rescue StandardError
      # e.g. inotify watch limit exceeded: degrade to the old
      # refresh-on-every-tick behavior, functionality preserved.
      @listener = nil
      @fallback_polling = true
    end

    # In fallback mode there are no events: callers must treat every tick as
    # potentially dirty (App does this for the tooling metrics too).
    def fallback_polling?
      @fallback_polling
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

    # Replaces Listen's default silencer (which ignores all of .git) and
    # carves out exceptions for configured tooling report paths that live
    # inside otherwise silenced directories (e.g. tmp/).
    def listen_ignores
      [
        Listen::Silencer::DEFAULT_IGNORED_EXTENSIONS, # editor swap/temp files
        silenced_dirs_regex,
        GIT_INTERNALS
      ]
    end

    def silenced_dirs_regex
      return /\A#{SILENCED_DIRS}/x if @report_paths.empty?

      exceptions = Regexp.union(@report_paths).source
      /\A(?!(?:#{exceptions})\z)#{SILENCED_DIRS}/x
    end

    # Every event marks the git state dirty; events touching a tooling
    # report additionally notify the metrics reader.
    def handle_fs_events(paths)
      mark_dirty
      return if @on_report_change.nil? || @report_paths.empty?

      root = File.join(File.expand_path(@repo_path), '')
      relative = paths.map { |path| File.expand_path(path).delete_prefix(root) }
      @on_report_change.call if relative.intersect?(@report_paths)
    end

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
