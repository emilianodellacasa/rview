# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Rview::Components::FileList do
  let(:file_statuses) do
    [
      Rview::DiffParser::FileStatus.new(path: 'foo.rb', status_code: 'M', original_path: nil),
      Rview::DiffParser::FileStatus.new(path: 'bar.rb', status_code: 'A', original_path: nil),
      Rview::DiffParser::FileStatus.new(path: 'baz.rb', status_code: 'D', original_path: nil)
    ]
  end

  subject(:list) { described_class.new(width: 30, height: 24) }

  describe '#move_down / #move_up' do
    before { list.update_files(file_statuses) }

    it 'moves cursor down' do
      list.move_down
      expect(list.selected_index).to eq(1)
    end

    it 'moves cursor up' do
      list.move_down
      list.move_up
      expect(list.selected_index).to eq(0)
    end

    it 'clamps at top boundary' do
      list.move_up
      expect(list.selected_index).to eq(0)
    end

    it 'clamps at bottom boundary' do
      3.times { list.move_down }
      expect(list.selected_index).to eq(2)
    end
  end

  describe '#selected_file' do
    before { list.update_files(file_statuses) }

    it 'returns the currently selected file' do
      expect(list.selected_file.path).to eq('foo.rb')
    end

    it 'returns the moved-to file' do
      list.move_down
      expect(list.selected_file.path).to eq('bar.rb')
    end
  end

  describe '#view' do
    context 'with no files' do
      it 'shows empty state message' do
        expect(list.view).to include('no changes')
      end
    end

    context 'with files' do
      before { list.update_files(file_statuses) }

      it 'shows file paths' do
        output = list.view
        expect(output).to include('foo.rb')
        expect(output).to include('bar.rb')
      end

      it 'shows cursor on selected item' do
        output = list.view
        expect(output).to include('> ')
      end

      it 'shows status symbols' do
        output = list.view
        expect(output).to include('M')
      end
    end
  end

  describe '#focus / #blur' do
    it 'tracks focused state' do
      list.focus
      expect(list.focused?).to be true
      list.blur
      expect(list.focused?).to be false
    end
  end
end
