# Game-specific composition

| File | Responsibility |
| --- | --- |
| `entry.tscn`, `menu_flow.gd` | Decorate the existing MainMenu, register content, start a fresh session, request the game scene. Settings/Controls remain the original panels. |
| `world.tscn`, `world.gd` | Compose the pixel viewport, arena, HUD and original PauseMenu. Own restart/return policy. |
| `arena.gd` | Local run state machine, combat, four enemy roles, boss phases, encounter pacing, traps, relics and short-lived effects. |
| `room.gd` | Authored bounds/pillars, swept movement, projectile sight lines and obstacle navigation. No procedural dungeon generation. |
| `arena_view.gd` | Original sprites/tiles/animations, y-sorted pillars and actors, attack/telegraph/effect rendering. |
| `ui/game_ui.gd` | Native HUD, focused relic cards and results. Relic selection suspends the simulation; it does not set a second global pause state. |
| `content.gd` | EN/PT translations, item icons, ControlsManager registration. |
| `sound.gd`, `audio/` | Game cue bank and original synthesized WAVs. Playback uses AudioManager's existing players. |
| `crypt_palette.tres` | UIPalette resource selected by the foundation theme configuration. |

## Reused foundation

- SceneManager owns all transitions and input blocking. No local fade overlay.
- GameSession holds seed, seal, relics, elapsed time, kills and result. Restart calls `start()`; return to menu calls `finish()`.
- PauseManager remains the sole global pause writer, presented by the supplied PauseMenu.
- Existing MainMenu owns Settings and Controls, with standard mouse/keyboard/controller navigation.
- LocalizationManager receives game entries before menus load. All game UI reacts to language changes.
- SettingsManager owns persisted resolution, fullscreen, volume and language. SaveManager remains available but is intentionally unused: there are no in-progress saves or meta progression.
- AudioManager owns playback. The game sound bank configures `AudioStreamPolyphonic` on the manager's existing SFX player because the base exposes only UI cue methods; no extra AudioStreamPlayer or audio manager is created. UI sounds temporarily replace that stream, and gameplay restores it as needed.
- `menu_theme.tres` and UIPalette are inherited. Only game progress bars extend the shared theme using semantic roles.

No new autoloads, duplicate managers, save formats, global event buses or generic game-feel frameworks.

## Changes relative to the supplied template

- `project.godot`: game identity/entry scene, attack/roll input actions, Compatibility renderer and nearest pixel filtering.
- `ui/theme/theme_config.tres`: select the game palette.
- `export_presets.cfg`: project-local output path, exclude development documentation/audio generator.
- `tests/run_tests.py`: register the game suite, use the actual graceful-quit startup smoke test and allow a focused `--only` run.
- `README.md`, `.gitignore`: game instructions and development artifact exclusions. Original README preserved in `docs/STARTER_KIT.md`.
- `core/`, `scenes/`, shared menu scripts and the generated-theme wrapper are unchanged.

## Lifecycle and limits

Simulation arrays belong to one arena instance. Scene replacement discards them. Shots/zones are cleared immediately on terminal states; spawning ends at a fixed time and encounter completion waits for survivors. Enemies are capped per wave, boss adds are capped, and transient effects expire. No per-entity timers or tweens survive a run.

Balance values are in `arena.gd`: `SEAL_DURATION`, `SPAWN_END`, enemy health/speed tables, attack cadence and boss health. The included bot is useful for regressions and discovering stalls; human playtesting remains necessary to judge difficulty and feel.
