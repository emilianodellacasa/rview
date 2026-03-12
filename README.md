# rview

A real-time TUI (Terminal User Interface) for viewing Git changes in your repository, with syntax highlighting and keyboard navigation.

## Features

- Real-time refresh of file list and diff on every tick
- Colorized diff view for each modified file
- Keyboard navigation and mouse support
- Two-panel layout: file list | diff
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
│ ↑/↓ j/k  navigate │ tab  switch panel │ r  refresh │ q  quit │
╰─────────────────────────────────────────────────────────╯
```

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
