# frozen_string_literal: true

require 'bubbletea'

module Rview
  class App
    include Bubbletea::Model

    TICK_INTERVAL = 0.5
    FOCUS_FILE_LIST = :file_list
    FOCUS_DIFF_VIEW = :diff_view

    def self.run(argv = [])
      repo_path = argv.first || Dir.pwd
      unless File.directory?(File.join(repo_path, '.git'))
        warn "rview: '#{repo_path}' non è un repository git"
        exit 1
      end
      app = new(repo_path: repo_path)
      Bubbletea.run(app)
    end

    def initialize(repo_path: Dir.pwd, width: 120, height: 40)
      @repo_path = repo_path
      @width = width
      @height = height
      @focus = FOCUS_FILE_LIST

      @file_list = Components::FileList.new(**left_outer_dims)
      @diff_view = Components::DiffView.new(**right_outer_dims)
      @status_bar = Components::StatusBar.new
      @watcher = GitWatcher.new(repo_path)

      @file_list.focus
    end

    def init
      @watcher.start
      [self, tick_cmd]
    end

    def update(msg)
      case msg
      when Messages::RefreshTick
        handle_tick
      when Bubbletea::KeyMessage
        handle_key(msg)
      when Bubbletea::MouseMessage
        handle_mouse(msg)
      when Bubbletea::WindowSizeMessage
        handle_resize(msg)
      else
        [self, nil]
      end
    end

    def view
      left_box = box_style(focused: @focus == FOCUS_FILE_LIST, **left_outer_dims).render(@file_list.view)
      right_box = box_style(focused: @focus == FOCUS_DIFF_VIEW, **right_outer_dims).render(@diff_view.view)

      panels = Lipgloss.join_horizontal(:top, left_box, right_box)
      status = status_bar_style.render(@status_bar.view)
      [panels, status].join("\n")
    end

    private

    def handle_tick
      result = @watcher.refresh
      if result
        files, diffs = result
        @file_list.update_files(files)
        selected = @file_list.selected_file
        if selected
          diff_content = diffs[selected.path] || ''
          colorized = DiffParser.colorize(diff_content)
          @diff_view.set_diff(selected.path, colorized)
        else
          @diff_view.set_diff(nil, [])
        end
      end
      [self, tick_cmd]
    end

    def handle_key(msg)
      case msg.to_s
      when 'q', 'ctrl+c'
        @watcher.stop
        [self, Bubbletea.quit]
      when 'r'
        [self, nil]
      when 'tab'
        toggle_focus
        [self, nil]
      when 'j', 'down'
        handle_nav_down
        [self, nil]
      when 'k', 'up'
        handle_nav_up
        [self, nil]
      when 'enter'
        if @focus == FOCUS_FILE_LIST
          @focus = FOCUS_DIFF_VIEW
          @file_list.blur
          @diff_view.focus
        end
        [self, nil]
      else
        [self, nil]
      end
    end

    def handle_mouse(_msg)
      [self, nil]
    end

    def handle_resize(msg)
      @width = msg.width
      @height = msg.height
      @file_list.resize(**left_outer_dims)
      @diff_view.resize(**right_outer_dims)
      [self, nil]
    end

    def handle_nav_down
      if @focus == FOCUS_FILE_LIST
        @file_list.move_down
        update_diff_for_selected
      else
        @diff_view.scroll_down
      end
    end

    def handle_nav_up
      if @focus == FOCUS_FILE_LIST
        @file_list.move_up
        update_diff_for_selected
      else
        @diff_view.scroll_up
      end
    end

    def toggle_focus
      if @focus == FOCUS_FILE_LIST
        @focus = FOCUS_DIFF_VIEW
        @file_list.blur
        @diff_view.focus
      else
        @focus = FOCUS_FILE_LIST
        @diff_view.blur
        @file_list.focus
      end
    end

    def update_diff_for_selected
      selected = @file_list.selected_file
      return unless selected

      diff_content = @watcher.cached_diff(selected.path) || ''
      colorized = DiffParser.colorize(diff_content)
      @diff_view.set_diff(selected.path, colorized)
    end

    def tick_cmd
      Bubbletea.tick(TICK_INTERVAL) { Messages::RefreshTick.new }
    end

    def left_outer_width
      @width / 2
    end

    def right_outer_width
      @width - left_outer_width
    end

    def box_inner_height
      # terminal height minus status bar box (3 rows) and main box borders (2)
      [@height - 5, 1].max
    end

    def left_outer_dims
      { width: left_outer_width - 2, height: box_inner_height }
    end

    def right_outer_dims
      { width: right_outer_width - 2, height: box_inner_height }
    end

    def status_bar_style
      Lipgloss::Style.new
        .border(:rounded)
        .border_foreground(Styles::TEAL)
        .foreground(Styles::SUBTEXT0)
        .width(@width - 2)
        .height(1)
    end

    def box_style(focused:, width:, height:)
      border_color = focused ? Styles::MAUVE : Styles::OVERLAY1
      Lipgloss::Style.new
        .border(:rounded)
        .border_foreground(border_color)
        .width(width)
        .height(height)
        .max_height(height)
    end
  end
end
