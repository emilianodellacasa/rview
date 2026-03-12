# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Rview::Components::StatusBar do
  subject(:bar) { described_class.new }

  describe '#view' do
    it 'contains key binding labels' do
      output = bar.view
      expect(output).to include('j/k')
      expect(output).to include('tab')
      expect(output).to include('quit')
    end

    it 'includes branch when set' do
      bar.branch = 'main'
      expect(bar.view).to include('main')
    end

    it 'includes message when set' do
      bar.message = 'Loading...'
      expect(bar.view).to include('Loading...')
    end
  end
end
