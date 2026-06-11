# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Rview::Components::ToolingBox do
  subject(:box) { described_class.new }

  describe '#view' do
    it 'shows N/A for every metric when no data is available' do
      output = box.view
      expect(output).to include('Coverage')
      expect(output).to include('Smells')
      expect(output).to include('Security')
      expect(output.scan('N/A').length).to eq(3)
    end

    it 'shows the coverage value with an upward delta' do
      box.metrics = { coverage: { previous: 90.0, current: 92.5 } }
      output = box.view
      expect(output).to include('92.5%')
      expect(output).to include('▲')
      expect(output).to include('+2.5')
    end

    it 'shows a downward delta for decreasing smells' do
      box.metrics = { smells: { previous: 14, current: 11 } }
      output = box.view
      expect(output).to include('11')
      expect(output).to include('▼')
      expect(output).to include('-3')
    end

    it 'shows = for an unchanged metric' do
      box.metrics = { security: { previous: 0, current: 0 } }
      output = box.view
      expect(output).to include('Security: 0')
      expect(output).to include('=')
    end

    it 'shows = for a coverage change below display precision' do
      box.metrics = { coverage: { previous: 86.38, current: 86.36 } }
      output = box.view
      expect(output).to include('86.4%')
      expect(output).to include('=')
      expect(output).not_to include('▼')
    end

    it 'renders all three metrics side by side' do
      box.metrics = {
        coverage: { previous: 90.0, current: 92.5 },
        smells: { previous: 10, current: 14 },
        security: { previous: 1, current: 0 }
      }
      output = box.view
      coverage_segment, smells_segment, security_segment = output.split('│')
      expect(coverage_segment).to include('92.5%').and include('▲ +2.5')
      expect(smells_segment).to include('14').and include('▲ +4')
      expect(security_segment).to include('0').and include('▼ -1')
    end
  end
end
