# frozen_string_literal: true

module Rview
  module Components
    # Centered "about" modal drawn over an already rendered base view.
    class InfoModal
      def initialize(width:, height:)
        @width = width
        @height = height
      end

      def overlay(base)
        modal_lines = render_modal.split("\n")
        modal_w = modal_lines.map { |l| Bubbles::ANSI.strip(l).length }.max || 0
        v_pad = [(@height - modal_lines.length) / 2, 0].max
        h_pad = [(@width - modal_w) / 2, 0].max

        base_lines = base.split("\n")
        modal_lines.each_with_index do |modal_line, index|
          row = v_pad + index
          next if row >= base_lines.length

          base_lines[row] = splice(base_lines[row], modal_line, h_pad, modal_w)
        end
        base_lines.join("\n")
      end

      private

      def render_modal
        title   = Lipgloss::Style.new.bold(true).foreground(Styles::MAUVE).render('rview')
        version = Lipgloss::Style.new.foreground(Styles::SUBTEXT0).render("v#{VERSION}")
        author  = Lipgloss::Style.new.foreground(Styles::TEXT).render(AUTHOR)
        url     = Lipgloss::Style.new.foreground(Styles::BLUE).render(HOMEPAGE)
        hint    = Lipgloss::Style.new.foreground(Styles::OVERLAY1).render('press any key to close')

        Lipgloss::Style.new
                       .border(:rounded)
                       .border_foreground(Styles::MAUVE)
                       .padding(1, 4)
                       .render([title, version, '', author, url, '', hint].join("\n"))
      end

      def splice(base_line, modal_line, h_pad, modal_w)
        base_visual = Bubbles::ANSI.strip(base_line)
        left_chunk  = base_visual[0, h_pad] || ''
        right_chunk = base_visual[(h_pad + modal_w)..] || ''
        left_chunk + modal_line + right_chunk
      end
    end
  end
end
