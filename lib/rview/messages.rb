# frozen_string_literal: true

module Rview
  module Messages
    # Sent on each timer tick to trigger polling
    class RefreshTick
      attr_reader :time

      def initialize(time = Time.now)
        @time = time
      end
    end

    # Sent when git status has changed
    class GitStatusUpdated
      attr_reader :files

      def initialize(files)
        @files = files
      end
    end

    # Sent when diff content is updated for a file
    class DiffUpdated
      attr_reader :filename, :content

      def initialize(filename, content)
        @filename = filename
        @content = content
      end
    end

    # Sent after debounce period to trigger refresh
    class DebounceTick
      attr_reader :time

      def initialize(time = Time.now)
        @time = time
      end
    end
  end
end
