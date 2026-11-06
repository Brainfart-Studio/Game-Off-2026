# Game-Off-2026

## Folders

| Folder | Owner |
|---|---|
| `scripts/` | Brainfart |
| `scenes/` | Brainfart |
| `config/` | Brainfart |
| `art/` | Loten |
| `audio/sfx/` | Keltfire |
| `audio/music/` | Brainfart |

Each person commits only to their own folders.

## Branch flow

- Loten and Keltfire: `art/` and `sfx/` branches open PRs into `development`.
- Brainfart: feature branches open PRs into `bfs/working`, then `bfs/working` is merged into `development`.
- `development` is merged into `main` for releases.

## Docs

- [Assets](docs/assets.md)
- [Contributing](docs/contributing.md)
- [Architecture](docs/architecture.md)
- [Events](docs/events.md)
- [Tuning](docs/tuning.md)
