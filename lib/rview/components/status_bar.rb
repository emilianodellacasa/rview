# frozen_string_literal: true

module Rview
  module Components
    class StatusBar
      KEY_HINTS = [
        ['↑/↓ j/k', 'naviga'],
        ['tab', 'cambia pannello'],
        ['r', 'refresh'],
        ['q / ctrl+c', 'esci']
      ].freeze

      def initialize
        @branch = nil
        @message = nil
      end

      attr_writer :branch, :message

      def view
        hints = KEY_HINTS.map { |key, desc| " #{key}  #{desc} " }.join('│')
        parts = [hints]
        parts.unshift(" ⎇  #{@branch} │") if @branch
        parts.push("  #{@message}") if @message
        parts.join
      end
    end
  end
end
