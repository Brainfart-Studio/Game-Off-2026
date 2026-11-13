# Contributing

## Who owns what

| Folder | Owner |
|---|---|
| `scripts/` | Brainfart |
| `scenes/` | Brainfart |
| `config/` | Brainfart |
| `addons/`, `test/`, `tools/`, `docs/` | Brainfart |
| `art/` | Loten |
| `audio/sfx/` | Keltfire |
| `audio/music/` | Brainfart |

Each person commits only to their own folders. Asset names, sizes, and frame counts are in [assets.md](assets.md).

## Branch flow

- Loten and Keltfire: branch from `development` as `art/<short-kebab-description>` or `sfx/<short-kebab-description>`, open a PR into `development`.
- Brainfart: feature branches (`feat/`, `fix/`, `docs/`, and so on) open PRs into `bfs/working`. After testing, `bfs/working` is merged into `development`.
- `development` is merged into `main` for releases. Pushes to `development` and `main` deploy to Itch.

## Git LFS

Images, audio, and fonts are stored with Git LFS. Install it before cloning:

```bash
git lfs install
git clone https://github.com/Brainfart-Studio/Game-Off-2026
```

If you cloned without it, run `git lfs install --local` and `git lfs pull` in the repo.

## PR checks

Every PR into `bfs/working`, `development`, or `main` runs the `PR checks / check` workflow:

1. Headless import, then a 300 frame run of the main scene (the title) and of the run scene. Any script or load error fails it.
2. The GdUnit4 test suite.
3. A web export.

A PR cannot be merged until the check passes.

## Running checks locally

You need Godot 4.7.2. Point `GODOT` at the executable:

```bash
GODOT=/path/to/godot tools/check.sh
```

```bash
GODOT=/path/to/godot tools/test.sh
```

`tools/test.sh` writes reports to `reports/`. Without `GODOT`, both scripts use `godot` from your PATH.

## Where tests go

`test/` mirrors `scripts/`. A test for `scripts/core/x.gd` is `test/core/x_test.gd`, and a test for `scripts/systems/player/y.gd` is `test/systems/player/y_test.gd`. Test files extend `GdUnitTestSuite`.
