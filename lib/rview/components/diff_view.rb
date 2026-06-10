# frozen_string_literal: true

module Rview
  module Components
    class DiffView
      attr_reader :filename

      PLACEHOLDER = '(select a file to view diff)'

      def initialize(width: 80, height: 24)
        @width = width
        @height = height
        @filename = nil
        @focused = false
        @viewport = Bubbles::Viewport.new(width: width, height: viewport_height)
        @viewport.horizontal_step = 4
      end

      def resize(width:, height:)
        @width = width
        @height = height
        @viewport.width = width
        @viewport.height = viewport_height
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
        @viewport.y_offset = 0 if filename != @filename
        @filename = filename
        @viewport.content = colorized_lines.map { |line, style| colorize_line(line, style) }.join("\n")
      end

      def update(msg)
        @viewport.update(msg)
      end

      def scroll_down(lines = 1)
        @viewport.scroll_down(lines)
      end

      def scroll_up(lines = 1)
        @viewport.scroll_up(lines)
      end

      def scroll_offset
        @viewport.y_offset
      end

      def view
        return PLACEHOLDER if @viewport.content.empty?

        percent = (@viewport.scroll_percent * 100).to_i
        header = @filename ? "── #{@filename} #{percent}%" : ''
        [header, @viewport.view].join("\n")
      end

      private

      def viewport_height
        [@height - 2, 1].max
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
    end
  end
end
