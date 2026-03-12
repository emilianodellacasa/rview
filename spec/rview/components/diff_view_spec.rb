# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Rview::Components::DiffView do
  subject(:view) { described_class.new(width: 80, height: 24) }

  describe '#set_diff' do
    it 'stores content and resets scroll' do
      lines = [['+added', :diff_add], ['-removed', :diff_remove]]
      view.set_diff('foo.rb', lines)
      expect(view.filename).to eq('foo.rb')
      expect(view.scroll_offset).to eq(0)
    end
  end

  describe '#view' do
    context 'when empty' do
      it 'shows placeholder' do
        expect(view.view).to include(described_class::PLACEHOLDER)
      end
    end

    context 'with content' do
      before do
        lines = [['+added line', :diff_add], ['-removed line', :diff_remove]]
        view.set_diff('foo.rb', lines)
      end

      it 'shows filename' do
        expect(view.view).to include('foo.rb')
      end

      it 'shows diff content' do
        output = view.view
        expect(output).to include('+added line')
      end
    end
  end

  describe '#scroll_down / #scroll_up' do
    it 'adjusts scroll offset within bounds' do
      lines = (1..50).map { |i| ["line #{i}", :normal] }
      view.set_diff('big.rb', lines)

      view.scroll_down(5)
      expect(view.scroll_offset).to eq(5)

      view.scroll_up(3)
      expect(view.scroll_offset).to eq(2)
    end

    it 'does not scroll below 0' do
      view.set_diff('foo.rb', [['line', :normal]])
      view.scroll_up(100)
      expect(view.scroll_offset).to eq(0)
    end
  end
end
