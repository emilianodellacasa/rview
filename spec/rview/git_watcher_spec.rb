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

    it 'always returns a result' do
      files, diffs = watcher.refresh
      expect(files).to be_an(Array)
      expect(diffs).to be_a(Hash)
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
