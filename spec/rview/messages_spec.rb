# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Rview::Messages do
  describe Rview::Messages::RefreshTick do
    it 'stores time' do
      t = Time.now
      msg = described_class.new(t)
      expect(msg.time).to eq(t)
    end

    it 'defaults to current time' do
      before = Time.now
      msg = described_class.new
      after = Time.now
      expect(msg.time).to be_between(before, after)
    end
  end

  describe Rview::Messages::GitStatusUpdated do
    it 'stores files' do
      files = ['foo.rb', 'bar.rb']
      msg = described_class.new(files)
      expect(msg.files).to eq(files)
    end
  end

  describe Rview::Messages::DiffUpdated do
    it 'stores filename and content' do
      msg = described_class.new('foo.rb', '+added line')
      expect(msg.filename).to eq('foo.rb')
      expect(msg.content).to eq('+added line')
    end
  end

  describe Rview::Messages::DebounceTick do
    it 'stores time' do
      t = Time.now
      msg = described_class.new(t)
      expect(msg.time).to eq(t)
    end

    it 'defaults to current time' do
      before = Time.now
      msg = described_class.new
      after = Time.now
      expect(msg.time).to be_between(before, after)
    end
  end
end
