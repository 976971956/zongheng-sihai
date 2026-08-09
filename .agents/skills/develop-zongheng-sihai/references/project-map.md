# Project map

## Fixed release targets

- Repository: `https://github.com/976971956/zongheng-sihai.git`
- Source branch: `main`
- Pages branch: `gh-pages`
- Live game: `https://976971956.github.io/zongheng-sihai/`
- Web export: `build/web/game/index.html`
- Pages wrapper: `build/web/index.html`

## Runtime structure

- `project.godot`: entry scene, autoloads, display and platform settings.
- `scenes/world_2d.tscn` and `scripts/world_2d.gd`: default 2D portrait game, HUD, interaction, battle overlays, inventory, quests, trade, and navigation.
- `scenes/main.tscn` and `scripts/main.gd`: full journal interface and alternate presentation of the same state.
- `scripts/game_state.gd`: save-compatible player state, combat, quests, rewards, inventory, dungeons, bounty, and trade rules.
- `scripts/game_data.gd`: locations, actors, enemies, items, quests, routes, and balance data.
- `scripts/actor_2d.gd`, `scripts/world_map_2d.gd`, `scripts/battle_stage_2d.gd`: visual world and combat presentation.
- `scripts/audio_director.gd`: region music, battle transitions, sound effects, mute persistence, and polyphony.
- `tests/*_test.gd`: headless regression coverage. Discover and run all matching tests instead of maintaining a hard-coded subset.

## Derived assets

- Run `tools/build_subset_font.py` whenever visible Chinese strings change, then include `assets/fonts/NotoSansCJKsc-GameSubset.otf`.
- Run `tools/build_audio.py` only when changing the generated original audio set.
- Export presets exclude tests, builders, previews, the full source font, and unused source art from shipped packages.

## Release commands

Run Godot commands with the project root as the working directory. Headless Godot may require access to its macOS user-data directory.

```text
godot --headless --editor --path . --quit-after 600
godot --headless --path . --quit-after 2
godot --headless --path . --script tests/<name>_test.gd
godot --headless --path . --export-release Web build/web/game/index.html
git push origin main
git subtree push --prefix build/web origin gh-pages
```

Keep commands non-interactive. Resolve exact targets with read-only checks before publishing.
