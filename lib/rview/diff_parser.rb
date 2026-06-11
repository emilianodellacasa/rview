# frozen_string_literal: true

module Rview
  class DiffParser
    # Parsed representation of a single file's status
    FileStatus = Struct.new(:path, :status_code, :original_path)

    # Parse `git status --porcelain` output into FileStatus objects
    # @param raw [String] raw porcelain output
    # @return [Array<FileStatus>]
    def self.parse_status(raw)
      return [] if raw.nil? || raw.strip.empty?

      raw.lines.filter_map do |line|
        line = line.chomp
        next if line.empty?

        # Porcelain format: XY PATH or XY ORIG -> PATH
        xy = line[0, 2]
        rest = line[3..]

        status_code = determine_status_code(xy)

        if rest.include?(' -> ')
          parts = rest.split(' -> ', 2)
          FileStatus.new(path: parts[1], status_code: status_code, original_path: parts[0])
        else
          FileStatus.new(path: rest, status_code: status_code, original_path: nil)
        end
      end
    end

    # Colorize a raw diff string by applying style hints per line type
    # Returns array of [line, style_key] pairs for rendering
    # @param raw_diff [String]
    # @return [Array<Array>] array of [line_text, style_key] pairs
    def self.colorize(raw_diff)
      return [] if raw_diff.nil? || raw_diff.strip.empty?

      raw_diff.lines.map do |line|
        line = line.chomp
        style = classify_line(line)
        [line, style]
      end
    end

    # Status letters in display priority; the value tells whether the letter
    # also counts when it appears in the worktree (Y) column.
    STATUS_PRIORITY = { 'R' => true, 'D' => true, 'A' => false, 'M' => true, 'C' => false, 'U' => true }.freeze

    def self.determine_status_code(code)
      return '?' if code == '??'

      letter, = STATUS_PRIORITY.find { |l, both_columns| code[0] == l || (both_columns && code[1] == l) }
      letter || code.strip
    end
    private_class_method :determine_status_code

    def self.classify_line(line)
      return :diff_add    if line.start_with?('+') && !line.start_with?('+++')
      return :diff_remove if line.start_with?('-') && !line.start_with?('---')
      return :diff_hunk   if line.start_with?('@@')
      return :diff_header if line.start_with?('diff ', 'index ', '---', '+++', 'new file', 'deleted file')

      :normal
    end
    private_class_method :classify_line
  end
end
