# frozen_string_literal: true

module Rview
  module Components
    class StatusBar
      KEY_HINTS = [
        ['↑/↓ j/k', 'navigate'],
        ['tab', 'switch panel'],
        ['r', 'refresh'],
        ['i', 'info'],
        ['q / ctrl+c', 'quit']
      ].freeze

      def initialize(width: 80)
        @width = width
        @branch = nil
        @message = nil
      end

      attr_writer :branch, :message, :width

      def view
        hints = KEY_HINTS.map { |key, desc| " #{key}  #{desc} " }.join('│')
        parts = [hints]
        parts.unshift(" ⎇  #{@branch} │") if @branch
        parts.push("  #{@message}") if @message
        left = parts.join

        right = " rview v#{Rview::VERSION} "
        padding = [@width - left.length - right.length, 0].max
        left + ' ' * padding + right
      end
    end
  end
end
