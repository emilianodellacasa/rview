# frozen_string_literal: true

module Rview
  module Components
    class ToolingBox
      LABELS = { coverage: 'Coverage', smells: 'Smells', security: 'Security' }.freeze
      GOOD_WHEN_UP = { coverage: true, smells: false, security: false }.freeze

      def initialize(width: 80)
        @width = width
        @metrics = {}
      end

      attr_writer :width, :metrics

      def view
        " #{LABELS.map { |key, label| segment(key, label) }.join(' │ ')}"
      end

      private

      def segment(key, label)
        entry = @metrics[key]
        return "#{label}: #{dim('N/A')}" unless entry

        "#{label}: #{format_value(key, entry[:current])} #{delta(key, entry)}"
      end

      def format_value(key, value)
        key == :coverage ? format('%.1f%%', value) : value.to_s
      end

      def delta(key, entry)
        diff = entry[:current] - entry[:previous]
        diff = diff.round(1) if key == :coverage
        return dim('=') if diff.zero?

        arrow = diff.positive? ? '▲' : '▼'
        color = diff.positive? == GOOD_WHEN_UP[key] ? Styles::GREEN : Styles::STRONG_RED
        text = key == :coverage ? format('%+.1f', diff) : format('%+d', diff)
        Lipgloss::Style.new.foreground(color).render("#{arrow} #{text}")
      end

      def dim(text)
        Lipgloss::Style.new.foreground(Styles::OVERLAY1).render(text)
      end
    end
  end
end
