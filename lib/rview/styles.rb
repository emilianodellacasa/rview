# frozen_string_literal: true

module Rview
  module Styles
    # Catppuccin Mocha palette
    ROSEWATER = '#f5e0dc'
    FLAMINGO  = '#f2cdcd'
    PINK      = '#f5c2e7'
    MAUVE     = '#cba6f7'
    RED       = '#f38ba8'
    MAROON    = '#eba0ac'
    PEACH     = '#fab387'
    YELLOW    = '#f9e2af'
    GREEN     = '#a6e3a1'
    TEAL      = '#94e2d5'
    SKY       = '#89dceb'
    SAPPHIRE  = '#74c7ec'
    BLUE      = '#89b4fa'
    LAVENDER  = '#b4befe'
    TEXT      = '#cdd6f4'
    SUBTEXT1  = '#bac2de'
    SUBTEXT0  = '#a6adc8'
    OVERLAY2  = '#9399b2'
    OVERLAY1  = '#7f849c'
    OVERLAY0  = '#6c7086'
    SURFACE2  = '#585b70'
    SURFACE1  = '#45475a'
    SURFACE0  = '#313244'
    BASE      = '#1e1e2e'
    MANTLE    = '#181825'
    CRUST     = '#11111b'

    def self.file_list_style
      { border: :rounded, border_fg: OVERLAY1, padding: [0, 1] }
    end

    def self.diff_view_style
      { border: :rounded, border_fg: OVERLAY1, padding: [0, 1] }
    end

    def self.focused_border_style
      { border: :rounded, border_fg: MAUVE }
    end

    def self.status_bar_style
      { background: SURFACE0, foreground: SUBTEXT0, padding: [0, 1] }
    end

    def self.selected_item_style
      { background: SURFACE1, foreground: LAVENDER, bold: true }
    end

    def self.diff_add_style
      { foreground: GREEN }
    end

    def self.diff_remove_style
      { foreground: RED }
    end

    def self.diff_hunk_style
      { foreground: TEAL }
    end

    def self.diff_header_style
      { foreground: MAUVE, bold: true }
    end

    def self.status_modified_style
      { foreground: YELLOW }
    end

    def self.status_added_style
      { foreground: GREEN }
    end

    def self.status_deleted_style
      { foreground: RED }
    end

    def self.status_untracked_style
      { foreground: OVERLAY2 }
    end

    def self.status_renamed_style
      { foreground: PEACH }
    end

    # Map status code to colored indicator
    STATUS_INDICATORS = {
      'M' => 'M',
      'A' => 'A',
      'D' => 'D',
      '?' => '?',
      'R' => 'R',
      'C' => 'C',
      'U' => 'U'
    }.freeze
  end
end
