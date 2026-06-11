# frozen_string_literal: true

require 'json'
require 'digest'
require 'fileutils'

module Rview
  class BaselineStore
    def self.default_data_dir
      base = ENV['XDG_DATA_HOME'] || File.join(Dir.home, '.local', 'share')
      File.join(base, 'rview')
    end

    def initialize(repo_path, data_dir: self.class.default_data_dir)
      @repo_path = File.expand_path(repo_path)
      @data_dir = data_dir
    end

    # Folds new_value into the stored baseline and returns { previous:, current: }.
    # Returns nil when new_value is nil so a missing report never disturbs the baseline.
    def update(key, new_value)
      return nil if new_value.nil?

      entry = data[key.to_s]
      if entry.nil?
        entry = write_entry(key, new_value, new_value)
      elsif entry['current'] != new_value
        entry = write_entry(key, entry['current'], new_value)
      end
      { previous: entry['previous'], current: entry['current'] }
    end

    private

    def data
      @data ||= read_store
    end

    def read_store
      JSON.parse(File.read(store_path))
    rescue Errno::ENOENT, JSON::ParserError
      {}
    end

    # Merge with the on-disk state at write time so a concurrent rview instance
    # (or an external edit) is not clobbered by our memoized snapshot.
    def write_entry(key, previous, current)
      entry = { 'previous' => previous, 'current' => current }
      @data = read_store.merge(key.to_s => entry)
      FileUtils.mkdir_p(@data_dir)
      File.write(store_path, JSON.pretty_generate(@data))
      entry
    end

    def store_path
      @store_path ||= File.join(@data_dir, "#{Digest::SHA256.hexdigest(@repo_path)[0, 16]}.json")
    end
  end
end
