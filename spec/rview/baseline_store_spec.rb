# frozen_string_literal: true

require 'spec_helper'
require 'tmpdir'

RSpec.describe Rview::BaselineStore do
  let(:repo_path) { Dir.mktmpdir('rview-repo') }
  let(:data_dir) { Dir.mktmpdir('rview-data') }

  subject(:store) { described_class.new(repo_path, data_dir: data_dir) }

  after do
    FileUtils.remove_entry(repo_path)
    FileUtils.remove_entry(data_dir)
  end

  describe '#update' do
    it 'returns previous == current on first observation' do
      expect(store.update(:smells, 10)).to eq(previous: 10, current: 10)
    end

    it 'keeps the baseline unchanged when the value does not change' do
      store.update(:smells, 10)
      expect(store.update(:smells, 10)).to eq(previous: 10, current: 10)
    end

    it 'shifts current to previous when the value changes' do
      store.update(:smells, 10)
      expect(store.update(:smells, 7)).to eq(previous: 10, current: 7)
    end

    it 'persists the baseline across instances' do
      store.update(:smells, 10)
      store.update(:smells, 7)

      other = described_class.new(repo_path, data_dir: data_dir)
      expect(other.update(:smells, 7)).to eq(previous: 10, current: 7)
    end

    it 'returns nil and writes nothing for a nil value' do
      expect(store.update(:coverage, nil)).to be_nil
      expect(Dir.children(data_dir)).to be_empty
    end

    it 'tracks metrics independently' do
      store.update(:smells, 10)
      store.update(:coverage, 95.5)
      expect(store.update(:smells, 12)).to eq(previous: 10, current: 12)
      expect(store.update(:coverage, 95.5)).to eq(previous: 95.5, current: 95.5)
    end

    it 'uses distinct store files for distinct repos' do
      other_repo = Dir.mktmpdir('rview-repo-other')
      begin
        store.update(:smells, 10)
        described_class.new(other_repo, data_dir: data_dir).update(:smells, 3)
        expect(Dir.children(data_dir).length).to eq(2)
      ensure
        FileUtils.remove_entry(other_repo)
      end
    end

    it 'does not resurrect entries removed from disk by another writer' do
      store.update(:smells, 10)
      store.update(:coverage, 90.0)

      # An external edit removes the smells entry from the store file.
      file = File.join(data_dir, Dir.children(data_dir).first)
      data = JSON.parse(File.read(file))
      data.delete('smells')
      File.write(file, JSON.pretty_generate(data))

      store.update(:coverage, 91.0)

      fresh = described_class.new(repo_path, data_dir: data_dir)
      expect(fresh.update(:smells, 13)).to eq(previous: 13, current: 13)
    end

    it 'treats a corrupt store file as empty' do
      store.update(:smells, 10)
      Dir.children(data_dir).each { |f| File.write(File.join(data_dir, f), '{not json') }

      other = described_class.new(repo_path, data_dir: data_dir)
      expect(other.update(:smells, 10)).to eq(previous: 10, current: 10)
    end
  end
end
