# frozen_string_literal: true

require 'spec_helper'
require 'tmpdir'
require 'fileutils'

RSpec.describe 'App integration', :integration do
  let(:tmpdir) do
    dir = Dir.mktmpdir
    system('git', '-C', dir, 'init', out: File::NULL, err: File::NULL)
    system('git', '-C', dir, 'config', 'user.email', 'test@test.com', out: File::NULL)
    system('git', '-C', dir, 'config', 'user.name', 'Test', out: File::NULL)
    dir
  end

  after { FileUtils.rm_rf(tmpdir) }

  it 'detects a modified file in the full cycle' do
    # Create initial commit
    File.write(File.join(tmpdir, 'app.rb'), "puts 'hello'\n")
    system('git', '-C', tmpdir, 'add', '.', out: File::NULL)
    system('git', '-C', tmpdir, 'commit', '-m', 'init', out: File::NULL, err: File::NULL)

    # Modify file
    File.write(File.join(tmpdir, 'app.rb'), "puts 'world'\n")

    app = Rview::App.new(repo_path: tmpdir, width: 120, height: 40)
    app.init

    tick = Rview::Messages::RefreshTick.new
    app.update(tick)

    app.instance_variable_get(:@watcher).stop

    # The watcher should have picked up the modification
    files = app.instance_variable_get(:@file_list).files
    paths = files.map(&:path)
    expect(paths).to include('app.rb')
  end

  it 'renders a view with file list content after update' do
    File.write(File.join(tmpdir, 'changed.rb'), "x = 1\n")
    system('git', '-C', tmpdir, 'add', '.', out: File::NULL)
    system('git', '-C', tmpdir, 'commit', '-m', 'init', out: File::NULL, err: File::NULL)

    File.write(File.join(tmpdir, 'changed.rb'), "x = 2\n")

    app = Rview::App.new(repo_path: tmpdir, width: 120, height: 40)
    app.init

    tick = Rview::Messages::RefreshTick.new
    app.update(tick)
    app.instance_variable_get(:@watcher).stop

    output = app.view
    expect(output).to be_a(String)
    expect(output.length).to be > 0
  end
end
