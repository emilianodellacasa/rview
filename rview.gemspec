# frozen_string_literal: true

require_relative 'lib/rview/version'

Gem::Specification.new do |spec|
  spec.name    = 'rview'
  spec.version = Rview::VERSION
  spec.summary = 'Terminal UI for viewing git changes'
  spec.authors = ['Emiliano']
  spec.required_ruby_version = '>= 4.0'
  spec.metadata['rubygems_mfa_required'] = 'true'

  spec.files         = Dir['lib/**/*.rb']
  spec.executables   = ['rview']
  spec.require_paths = ['lib']

  spec.add_dependency 'bubbletea'
  spec.add_dependency 'lipgloss'
end
