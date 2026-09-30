# Validation — 2026-09-30

Engine: Godot 4.6.1 stable, macOS Apple M1, Compatibility renderer.

## Completed

- Full isolated Starter Kit runner passed in headless mode and in rendered mode. Foundation, persistence, persistence restart, theme, transitions, showcase and palette importer all passed.
- Foundation rendered suites: 757 assertions, zero failures. Headless foundation suites: 721 assertions, zero failures.
- Latest game suite: 43 assertions, zero failures, after final HUD sizing and mouse selection fixes. It imports a disposable project and isolates settings/save files.
- Real MainMenu → start signal → SceneManager fade → world/HUD. Settings and Controls opening, live EN/PT updates, pause/frozen simulation/resume, reward focus, keyboard navigation, synthetic controller confirm and synthetic mouse selection.
- Pillar collision prevents high-speed tunnelling; pillars block line of sight. Sword damage/death, arriving-enemy safety, invulnerability, reflection and trap windup verified.
- Boss victory → restart → death → restart → menu validated through actual scene transitions. Fresh health, relics, kills, boss phase, session and pause state checked.
- Three unshortened automated playthroughs use the actual world and HUD, normal health/damage, normal encounter durations and offered relics. The bot moves through the room and chooses/activates real reward buttons; it does not teleport, clear waves, increase health or reduce boss health.

| Seed | Outcome | Simulated gameplay time | Kills | Relics |
| --- | --- | --- | --- | --- |
| 7412 | Defeat | 163.2 s | 59 | Long blade, Vow of fury |
| 1907 | Defeat | 84.8 s | 25 | Echo blade |
| 9921 | Victory | 290.8 s | 122 | Echo blade, Long blade, Harvest flask, Amber heart |

Decision time is omitted by the bot; the winning simulation is about 4m51s of gameplay. Human movement/decisions are expected to bring successful runs into the 5–10 minute target. Three seeds are regression samples, not a statistically meaningful balance study.

Rendered images were inspected for menu, HUD/combat, relic choices in both languages, Controls, boss and results. Representative captures are in `docs/images/`. No parser errors, missing resources or recurring runtime errors remained in passing runs.

## Fixes found during validation

- Asset directories arrived read-only; owner write permission was needed for Godot import metadata.
- Native method-name collision in localization helper fixed before gameplay tests.
- Final sword hit could spawn an echo projectile after victory; terminal-state guard now prevents it.
- ProgressBar's initial theme minimum inflated thin HUD bars; deferred sizing after theme inheritance fixes it, with a regression assertion.
- Music loop endpoint now uses sample duration/rate, independent of WAV import compression.
- Forced engine termination while music plays can report audio-server references on Godot 4.6. Gameplay now stops playback before normal window/menu quit, waits 0.2 seconds for audio retirement and exits cleanly. Startup smoke test uses this actual quit flow.

## Not completed / human review

- Manual real-time playthrough and a physical controller test were not possible: native computer-use permissions were unavailable. Automated UI events and rendered inspection are not a substitute for these checks.
- Final difficulty, tactile feel and audio mix need human playtesting; the bot is deliberately fallible.
- Exported executables and itch.io/browser deployment were not built or tested. Export templates are a separate Godot prerequisite.
- Review the supplied asset license before public distribution; its explicit restriction on “AI creations” requires clarification for this AI-assisted project. The template also supplied no repository license.
