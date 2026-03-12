# rview

Un TUI (Terminal User Interface) in tempo reale per visualizzare le modifiche Git nel tuo repository, con evidenziazione della sintassi e navigazione da tastiera.

## Funzionalità

- Aggiornamento automatico della lista file al salvataggio (tramite `listen`)
- Visualizzazione del diff colorato per ogni file modificato
- Navigazione da tastiera e supporto mouse
- Layout a due pannelli: lista file | diff
- Tema colori Catppuccin Mocha

## Requisiti

- Ruby 4.0+
- Git

## Installazione

```bash
git clone https://github.com/tuoutente/rview
cd rview
bundle install
```

## Utilizzo

Avvia `rview` dalla root del repository Git che vuoi monitorare:

```bash
# Monitora la directory corrente
bundle exec bin/rview

# Oppure specifica un percorso
bundle exec bin/rview /path/to/repo
```

## Tasti

| Tasto | Azione |
|-------|--------|
| `j` / `↓` | File successivo (o scorri giù nel diff) |
| `k` / `↑` | File precedente (o scorri su nel diff) |
| `enter` | Passa il focus al pannello diff |
| `tab` | Alterna il focus tra lista file e diff |
| `q` / `ctrl+c` | Esci |

## Layout

```
┌─────────────────┬──────────────────────────────────────┐
│  Lista file     │  Diff del file selezionato           │
│                 │                                      │
│ > M lib/app.rb  │  diff --git a/lib/app.rb ...         │
│   A new_file.rb │  @@ -1,3 +1,5 @@                    │
│   D old.rb      │   context line                       │
│                 │  +added line                         │
│                 │  -removed line                       │
└─────────────────┴──────────────────────────────────────┘
  j/k: navigate  enter: select  tab: switch panel  q: quit
```

### Indicatori di stato

| Simbolo | Significato |
|---------|-------------|
| `M` | Modificato |
| `A` | Aggiunto (staged) |
| `D` | Eliminato |
| `R` | Rinominato |
| `?` | Untracked |
| `U` | Conflitto di merge |

## Sviluppo

```bash
# Esegui i test
bundle exec rspec

# Esegui il linter
bundle exec rubocop

# Esegui entrambi
bundle exec rake
```

## Licenza

Vedi [LICENSE](LICENSE).
