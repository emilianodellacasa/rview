# frozen_string_literal: true

module Rview
  module Components
    class FileList
      attr_reader :files, :selected_index, :focused

      STATUS_SYMBOLS = {
        'M' => 'M',
        'A' => 'A',
        'D' => 'D',
        '?' => '?',
        'R' => 'R',
        'C' => 'C',
        'U' => 'U'
      }.freeze

      def initialize(width: 30, height: 24)
        @width = width
        @height = height
        @files = []
        @selected_index = 0
        @focused = false
        @scroll_offset = 0
        @viewport = Bubbles::Viewport.new(width: width, height: viewport_height)
      end

      def resize(width:, height:)
        @width = width
        @height = height
        @viewport.width = width
        @viewport.height = viewport_height
        clamp_scroll
      end

      def focus
        @focused = true
      end

      def blur
        @focused = false
      end

      def focused?
        @focused
      end

      def update_files(files)
        @files = files
        @selected_index = @selected_index.clamp(0, [@files.length - 1, 0].max)
        clamp_scroll
      end

      def move_down
        return if @files.empty?

        @selected_index = (@selected_index + 1).clamp(0, @files.length - 1)
        clamp_scroll
      end

      def move_up
        return if @files.empty?

        @selected_index = (@selected_index - 1).clamp(0, @files.length - 1)
        clamp_scroll
      end

      def selected_file
        @files[@selected_index]
      end

      def view
        return '(no changes)' if @files.empty?

        lines = @files.each_with_index.map do |file_status, idx|
          symbol = STATUS_SYMBOLS[file_status.status_code] || ' '
          prefix = idx == @selected_index ? '> ' : '  '
          colorize_entry("#{prefix}#{symbol} #{file_status.path}", file_status.status_code)
        end

        @viewport.content = lines.join("\n")
        @viewport.y_offset = @scroll_offset
        @viewport.view
      end

      private

      def colorize_entry(line, status_code)
        color = case status_code
                when 'M'      then Styles::GREEN
                when 'D'      then Styles::RED
                when 'A', '?' then Styles::SKY
                end
        return line unless color

        Lipgloss::Style.new.foreground(color).render(line)
      end

      def viewport_height
        [@height - 2, 1].max
      end

      def clamp_scroll
        return if @files.empty?

        max_scroll = [@files.length - viewport_height, 0].max
        @scroll_offset = @scroll_offset.clamp(0, max_scroll)

        if @selected_index < @scroll_offset
          @scroll_offset = @selected_index
        elsif @selected_index >= @scroll_offset + viewport_height
          @scroll_offset = @selected_index - viewport_height + 1
        end
      end
    end
  end
end
