# frozen_string_literal: true

require 'spec_helper'
require 'tmpdir'
require 'fileutils'

RSpec.describe Rview::App do
  let(:tmpdir) do
    dir = Dir.mktmpdir
    system('git', '-C', dir, 'init', out: File::NULL, err: File::NULL)
    system('git', '-C', dir, 'config', 'user.email', 'test@test.com', out: File::NULL)
    system('git', '-C', dir, 'config', 'user.name', 'Test', out: File::NULL)
    File.write(File.join(dir, 'README.md'), "# Test\n")
    system('git', '-C', dir, 'add', '.', out: File::NULL)
    system('git', '-C', dir, 'commit', '-m', 'init', out: File::NULL, err: File::NULL)
    dir
  end

  after { FileUtils.rm_rf(tmpdir) }

  subject(:app) { described_class.new(repo_path: tmpdir, width: 120, height: 40) }

  describe '#init' do
    after { app.instance_variable_get(:@watcher).stop }

    it 'returns [model, tick_command]' do
      model, cmd = app.init
      expect(model).to be(app)
      expect(cmd).to be_a(Bubbletea::TickCommand)
    end
  end

  describe '#update with RefreshTick' do
    before { app.init }
    after { app.instance_variable_get(:@watcher).stop }

    it 'returns [model, tick_command]' do
      tick = Rview::Messages::RefreshTick.new
      model, cmd = app.update(tick)
      expect(model).to be(app)
      expect(cmd).to be_a(Bubbletea::TickCommand)
    end
  end

  describe '#update with key q' do
    before { app.instance_variable_get(:@watcher).stop }

    it 'returns quit command' do
      key_msg = Bubbletea::KeyMessage.new(key_type: Bubbletea::KeyMessage::KEY_RUNES, runes: [113])
      _model, cmd = app.update(key_msg)
      expect(cmd).to be_a(Bubbletea::QuitCommand)
    end
  end

  describe '#update with tab key' do
    let(:tab_msg) { Bubbletea::KeyMessage.new(key_type: Bubbletea::KeyMessage::KEY_TAB) }

    it 'toggles focus from file_list to diff_view' do
      expect(app.instance_variable_get(:@focus)).to eq(Rview::App::FOCUS_FILE_LIST)
      app.update(tab_msg)
      expect(app.instance_variable_get(:@focus)).to eq(Rview::App::FOCUS_DIFF_VIEW)
    end

    it 'toggles focus back' do
      app.update(tab_msg)
      app.update(tab_msg)
      expect(app.instance_variable_get(:@focus)).to eq(Rview::App::FOCUS_FILE_LIST)
    end
  end

  describe '#update with WindowSizeMessage' do
    it 'updates internal dimensions' do
      resize_msg = Bubbletea::WindowSizeMessage.new(width: 160, height: 50)
      app.update(resize_msg)
      expect(app.instance_variable_get(:@width)).to eq(160)
      expect(app.instance_variable_get(:@height)).to eq(50)
    end
  end

  describe '#view' do
    it 'returns a non-empty string' do
      expect(app.view).to be_a(String)
      expect(app.view).not_to be_empty
    end
  end
end
