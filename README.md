# rview

A real-time TUI (Terminal User Interface) for viewing Git changes in your repository, with syntax highlighting and keyboard navigation.

## Features

- Real-time refresh of file list and diff on every tick
- Colorized diff view for each modified file
- Keyboard navigation and mouse support
- Two-panel layout: file list | diff
- Tooling box with code coverage, code smells and security issues, with trend deltas vs the last recorded value
- Catppuccin Mocha color theme

## Requirements

- Ruby 3.4+
- Git

## Installation

```bash
git clone https://github.com/yourusername/rview
cd rview
bundle install
gem build rview.gemspec
gem install ./rview-0.1.0.gem
```

## Usage

Run `rview` from any directory:

```bash
# Monitor the current directory
rview

# Or specify a path
rview /path/to/repo
```

Must be run inside a Git repository, otherwise it will exit with an error.

## Keybindings

| Key | Action |
|-----|--------|
| `j` / `↓` | Next file (or scroll down in diff) |
| `k` / `↑` | Previous file (or scroll up in diff) |
| `enter` | Move focus to diff panel |
| `tab` | Toggle focus between file list and diff |
| `r` | Force refresh |
| `q` / `ctrl+c` | Quit |

## Layout

```
╭─────────────────╮╭──────────────────────────────────────╮
│  M lib/app.rb   ││  diff --git a/lib/app.rb ...          │
│> A new_file.rb  ││  @@ -1,3 +1,5 @@                     │
│  D old.rb       ││   context line                        │
│                 ││  +added line                          │
│                 ││  -removed line                        │
╰─────────────────╯╰──────────────────────────────────────╯
╭─────────────────────────────────────────────────────────╮
│ Coverage: 96.2% ▲ +1.2 │ Smells: 14 ▼ -3 │ Security: N/A │
╰─────────────────────────────────────────────────────────╯
╭─────────────────────────────────────────────────────────╮
│ ↑/↓ j/k  navigate │ tab  switch panel │ r  refresh │ q  quit │
╰─────────────────────────────────────────────────────────╯
```

## Tooling box

The box between the panels and the status bar shows three quality metrics for the watched repository. rview never runs the tools itself — it only reads report files when they exist (first match wins):

| Metric | Report files | Format | How to generate |
|--------|--------------|--------|-----------------|
| Coverage | `coverage/.last_run.json` | SimpleCov | Run your test suite with [SimpleCov](https://github.com/simplecov-ruby/simplecov) |
| Smells | `gl-code-quality-report.json`, `tmp/gl-code-quality-report.json` | [CodeClimate](https://docs.gitlab.com/ee/ci/testing/code_quality.html) (GitLab Code Quality) | e.g. `codeclimate analyze -f json > gl-code-quality-report.json`, or download the `codequality` artifact from your GitLab pipeline |
| Security | `gl-sast-report.json`, `tmp/gl-sast-report.json` | [GitLab SAST](https://docs.gitlab.com/ee/user/application_security/sast/) | `semgrep scan --config auto --gitlab-sast --output gl-sast-report.json`, or download the SAST artifact from your GitLab pipeline |

A missing or unparsable report shows `N/A`. Next to each value, a delta (`▲` / `▼` / `=`) compares it against the previous distinct value, persisted per repository in `$XDG_DATA_HOME/rview/` (default `~/.local/share/rview/`). The delta stays visible until the metric changes again. Green means the metric improved (coverage up, smells/security down), red means it got worse.

### Configuring report paths

The report locations can be overridden with a `.rview.yml` file in the root of the watched repository. Each metric accepts a single path or a list of candidate paths (relative to the repository, first existing wins); metrics not listed keep their defaults:

```yaml
tooling:
  coverage: reports/coverage/.last_run.json
  smells:
    - ci/gl-code-quality-report.json
    - gl-code-quality-report.json
  security: reports/gl-sast-report.json
```

The file is read once at startup — restart rview after changing it.

> **Tip**: if your test suite writes the SimpleCov report on every run, a partial run (a single file or example) overwrites the total with a misleading value and pollutes the delta baseline. This repository redirects SimpleCov output to `tmp/coverage-partial/` for partial runs (see `spec/spec_helper.rb`) so `coverage/.last_run.json` only reflects full-suite runs.

### Status indicators

| Symbol | Meaning |
|--------|---------|
| `M` | Modified |
| `A` | Added (staged) |
| `D` | Deleted |
| `R` | Renamed |
| `?` | Untracked |
| `U` | Merge conflict |

## Development

```bash
# Run tests
bundle exec rspec

# Run linter
bundle exec rubocop

# Run both
bundle exec rake
```

## License

See [LICENSE](LICENSE).
