# frozen_string_literal: true

require_relative 'lib/rview/version'

Gem::Specification.new do |spec|
  spec.name    = 'rview'
  spec.version = Rview::VERSION
  spec.summary = 'Terminal UI for viewing git changes'
  spec.authors  = ['Emiliano Della Casa']
  spec.homepage = 'https://github.com/emilianodellacasa/rview'
  spec.required_ruby_version = '>= 3.2'
  spec.metadata['rubygems_mfa_required'] = 'true'

  spec.files         = Dir['lib/**/*.rb']
  spec.executables   = ['rview']
  spec.require_paths = ['lib']

  spec.add_dependency 'bubbles'
  spec.add_dependency 'bubbletea'
  spec.add_dependency 'bubblezone'
  spec.add_dependency 'git_diff_parser'
  spec.add_dependency 'lipgloss'
  spec.add_dependency 'listen'
end
