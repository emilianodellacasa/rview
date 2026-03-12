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
      end

      def resize(width:, height:)
        @width = width
        @height = height
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

        visible_files = @files[@scroll_offset, visible_lines] || []
        lines = visible_files.each_with_index.map do |file_status, idx|
          actual_idx = idx + @scroll_offset
          symbol = STATUS_SYMBOLS[file_status.status_code] || ' '
          prefix = actual_idx == @selected_index ? '> ' : '  '
          "#{prefix}#{symbol} #{file_status.path}"
        end

        lines.join("\n")
      end

      private

      def visible_lines
        [@height - 2, 1].max
      end

      def clamp_scroll
        return if @files.empty?

        max_scroll = [@files.length - visible_lines, 0].max
        @scroll_offset = @scroll_offset.clamp(0, max_scroll)

        if @selected_index < @scroll_offset
          @scroll_offset = @selected_index
        elsif @selected_index >= @scroll_offset + visible_lines
          @scroll_offset = @selected_index - visible_lines + 1
        end
      end
    end
  end
end
