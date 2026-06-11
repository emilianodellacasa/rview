# frozen_string_literal: true

require 'spec_helper'
require 'tmpdir'
require 'fileutils'

RSpec.describe Rview::GitWatcher do
  let(:tmpdir) do
    dir = Dir.mktmpdir
    system('git', '-C', dir, 'init', out: File::NULL, err: File::NULL)
    system('git', '-C', dir, 'config', 'user.email', 'test@test.com', out: File::NULL)
    system('git', '-C', dir, 'config', 'user.name', 'Test', out: File::NULL)
    dir
  end

  after { FileUtils.rm_rf(tmpdir) }

  subject(:watcher) { described_class.new(tmpdir) }

  describe '#refresh' do
    context 'with a clean repo' do
      it 'returns empty files list' do
        File.write(File.join(tmpdir, 'README.md'), "# Test\n")
        system('git', '-C', tmpdir, 'add', '.', out: File::NULL)
        system('git', '-C', tmpdir, 'commit', '-m', 'init', out: File::NULL, err: File::NULL)

        files, _diffs = watcher.refresh
        expect(files).to be_an(Array)
        expect(files).to be_empty
      end
    end

    context 'with a modified file' do
      it 'detects modified files' do
        File.write(File.join(tmpdir, 'foo.rb'), "original\n")
        system('git', '-C', tmpdir, 'add', '.', out: File::NULL)
        system('git', '-C', tmpdir, 'commit', '-m', 'init', out: File::NULL, err: File::NULL)

        File.write(File.join(tmpdir, 'foo.rb'), "modified\n")

        files, _diffs = watcher.refresh
        expect(files.map(&:path)).to include('foo.rb')
      end
    end

    it 'returns data on the first call and nil while clean' do
      files, diffs = watcher.refresh
      expect(files).to be_an(Array)
      expect(diffs).to be_a(Hash)
      expect(watcher.refresh).to be_nil
    end

    it 'returns data again after mark_dirty' do
      watcher.refresh
      watcher.mark_dirty
      expect(watcher.refresh).to be_an(Array)
    end

    it 'returns data when forced even while clean' do
      watcher.refresh
      expect(watcher.refresh(force: true)).to be_an(Array)
    end
  end

  describe '#start' do
    after { watcher.stop }

    it 'falls back to refreshing on every call when the listener cannot start' do
      allow(Listen).to receive(:to).and_raise(StandardError)
      watcher.start
      watcher.refresh
      expect(watcher.refresh).to be_an(Array)
    end

    it 'becomes dirty after a file change' do
      skip 'inotify timing is flaky on CI' if ENV['CI']

      watcher.refresh # consume the initial dirty flag
      watcher.start
      sleep 0.3 # let inotify watches settle

      File.write(File.join(tmpdir, 'foo.rb'), "new\n")

      result = nil
      50.times do
        result = watcher.refresh
        break if result

        sleep 0.1
      end
      expect(result).to be_an(Array)
    end

    it 'becomes dirty after a git index change' do
      skip 'inotify timing is flaky on CI' if ENV['CI']

      File.write(File.join(tmpdir, 'foo.rb'), "new\n")
      watcher.refresh # consume the initial dirty flag
      watcher.start
      sleep 0.3

      system('git', '-C', tmpdir, 'add', '.', out: File::NULL)

      result = nil
      50.times do
        result = watcher.refresh
        break if result

        sleep 0.1
      end
      expect(result).to be_an(Array)
    end
  end

  describe '#cached_diff' do
    it 'returns nil for unknown path' do
      expect(watcher.cached_diff('nonexistent.rb')).to be_nil
    end

    it 'returns diff after refresh' do
      File.write(File.join(tmpdir, 'foo.rb'), "original\n")
      system('git', '-C', tmpdir, 'add', '.', out: File::NULL)
      system('git', '-C', tmpdir, 'commit', '-m', 'init', out: File::NULL, err: File::NULL)
      File.write(File.join(tmpdir, 'foo.rb'), "modified\n")

      watcher.refresh
      expect(watcher.cached_diff('foo.rb')).to be_a(String)
    end
  end
end
