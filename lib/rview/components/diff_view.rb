# frozen_string_literal: true

module Rview
  module Components
    class DiffView
      attr_reader :filename, :scroll_offset, :height

      PLACEHOLDER = '(select a file to view diff)'

      def initialize(width: 80, height: 24)
        @width = width
        @height = height
        @filename = nil
        @lines = []
        @scroll_offset = 0
        @focused = false
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

      def set_diff(filename, colorized_lines)
        @scroll_offset = 0 if filename != @filename
        @filename = filename
        @lines = colorized_lines
        clamp_scroll
      end

      def scroll_down(lines = 1)
        @scroll_offset += lines
        clamp_scroll
      end

      def scroll_up(lines = 1)
        @scroll_offset = [@scroll_offset - lines, 0].max
      end

      def view
        return PLACEHOLDER if @lines.empty?

        visible = @lines[@scroll_offset, visible_lines] || []
        content = visible.map { |line, style| colorize_line(truncate_line(line), style) }.join("\n")
        total = @lines.length
        percent = total.zero? ? 100 : ((@scroll_offset + visible_lines).clamp(0, total) * 100 / total)

        header = @filename ? "── #{@filename} " : ''
        scroll_indicator = " #{percent}%"

        [header + scroll_indicator, content].join("\n")
      end

      private

      def visible_lines
        [@height - 2, 1].max
      end

      def truncate_line(line)
        return line if line.length <= @width

        "#{line[0, @width - 1]}…"
      end

      def colorize_line(line, style)
        color = case style
                when :diff_add    then Styles::GREEN
                when :diff_remove then Styles::RED
                when :diff_hunk   then Styles::TEAL
                when :diff_header then Styles::MAUVE
                else return line
                end
        Lipgloss::Style.new.foreground(color).render(line)
      end

      def clamp_scroll
        max = [@lines.length - visible_lines, 0].max
        @scroll_offset = @scroll_offset.clamp(0, max)
      end
    end
  end
end
