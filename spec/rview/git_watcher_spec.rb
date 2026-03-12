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

  describe '#initialize' do
    it 'starts dirty for initial load' do
      expect(watcher.dirty?).to be true
    end
  end

  describe '#mark_dirty / #dirty?' do
    it 'marks as dirty and clears on refresh' do
      # Create a file to commit
      File.write(File.join(tmpdir, 'hello.rb'), "puts 'hello'\n")
      system('git', '-C', tmpdir, 'add', '.', out: File::NULL)
      system('git', '-C', tmpdir, 'commit', '-m', 'init', out: File::NULL, err: File::NULL)

      watcher.refresh_if_dirty # Clear initial dirty
      expect(watcher.dirty?).to be false

      watcher.mark_dirty
      expect(watcher.dirty?).to be true
    end
  end

  describe '#refresh_if_dirty' do
    context 'with an initial empty repo' do
      it 'returns empty files list for clean repo' do
        # Initialize with a commit
        File.write(File.join(tmpdir, 'README.md'), "# Test\n")
        system('git', '-C', tmpdir, 'add', '.', out: File::NULL)
        system('git', '-C', tmpdir, 'commit', '-m', 'init', out: File::NULL, err: File::NULL)

        result = watcher.refresh_if_dirty
        expect(result).not_to be_nil
        files, _diffs = result
        expect(files).to be_an(Array)
      end
    end

    context 'with a modified file' do
      it 'detects modified files' do
        File.write(File.join(tmpdir, 'foo.rb'), "original\n")
        system('git', '-C', tmpdir, 'add', '.', out: File::NULL)
        system('git', '-C', tmpdir, 'commit', '-m', 'init', out: File::NULL, err: File::NULL)

        File.write(File.join(tmpdir, 'foo.rb'), "modified\n")
        watcher.mark_dirty

        result = watcher.refresh_if_dirty
        expect(result).not_to be_nil
        files, _diffs = result
        paths = files.map(&:path)
        expect(paths).to include('foo.rb')
      end
    end

    it 'returns nil when not dirty' do
      # Clear initial dirty state
      File.write(File.join(tmpdir, 'x.rb'), "x\n")
      system('git', '-C', tmpdir, 'add', '.', out: File::NULL)
      system('git', '-C', tmpdir, 'commit', '-m', 'init', out: File::NULL, err: File::NULL)
      watcher.refresh_if_dirty

      expect(watcher.dirty?).to be false
      expect(watcher.refresh_if_dirty).to be_nil
    end
  end

  describe 'thread safety' do
    it 'handles concurrent mark_dirty calls without deadlock' do
      threads = 10.times.map do
        Thread.new { watcher.mark_dirty }
      end
      threads.each(&:join)
      expect(watcher.dirty?).to be true
    end
  end
end
