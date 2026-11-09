# SCRAP WARS — Combat Audio & VFX Integration

## Implementation

`BattleFX` (`scripts/battle_fx.gd`, project autoload) owns reusable one-shot audio playback and procedural CPU-particle creation. Each particle emitter uses a small runtime-generated radial texture; no particle sprite assets or GPU-only particle material is required. Effects are added to the active battle scene and freed when their one-shot lifetime completes.

| Gameplay event | Feedback wired to event |
|---|---|
| Vehicle receives Drill, Saw, Hammer, rocket, splash or test damage | Gold/silver spark burst, drifting smoke, metallic impact SFX; severity scales particle intensity |
| Component reaches zero durability | Local scrap spark/smoke burst and lower-pitched metal impact cue |
| Rocket fires | Muzzle flash burst and rocket ignition/whoosh SFX at the launcher |
| Rocket travels | Continuous exhaust particles remain attached to the physical projectile |
| Rocket strikes a vehicle, floor or wall | Explosion/debris particles and scrap-blast SFX; collision and damage remain the existing physics event |
| Vehicle is alive | Continuous engine exhaust particles; engine loop pitch follows speed/crank state |
| Drill or Saw is equipped and enabled | Rotary-tool loop plays; damaged/removed weapon and end-of-battle state stop it |
| Battle ends | Vehicle engine/rotary loops stop; one-shot effects finish naturally in play |

Audio playback reads the saved `GameState.sfx_volume`. Player and AI loops use different levels. The generated MP3 streams are loaded at runtime, so a clean first asset scan can import them before the autoload requests them. `--physics-test` prints event totals and loaded/started loop states, then releases transient nodes before exiting.

## Included original sound assets

- `assets/audio/engine_rough_loop.mp3` — 6.03 seconds; looped engine idling/revving layer.
- `assets/audio/rotary_tool_loop.mp3` — 5.04 seconds; looped rotary cutter/drill layer.
- `assets/audio/metal_impact.mp3` — 1.12 seconds; impact/break cue.
- `assets/audio/rocket_launch.mp3` — 1.23 seconds; rocket ignition/launch cue.
- `assets/audio/scrap_blast.mp3` — 1.41 seconds; rocket/component blast cue.

Asset provenance and the unreviewed external generator service rights terms are recorded in `LICENSES/ASSET_LICENSES.txt`.

## Verified in Godot headless

Godot 4.7.2 editor import passed. One controlled physics run completed the battle and reported: 7 impacts, 3 rocket launches, 2 explosions, 1 component break, 28 particle emitters created, 13 one-shot audio starts, all one-shot SFX resources loaded, player engine/rotary loops loaded and started, and AI engine loop loaded. The test exited without script errors or shutdown resource-leak messages. The separate UI smoke emitted its builder/campaign/reward assertions, and the rotation regression passed.

These results establish event wiring, resource load and playback requests—not acoustic quality or visible pixels.

## Not tested / remaining

- Actual speaker/headphone listening, sound balance, clipping, localization and Android audio focus/resume.
- Rendered particle pixel review, particle overdraw/frame-time measurement and actual Android GPU/CPU performance.
- Menu/music beds, menu/button/equip/remove/campaign/result cues, wheel/crank/booster-specific loops, Hammer swing, distinct victory/defeat/reward sounds and haptics.
- Android export, APK installation and physical-device gameplay.
- Commercial-use/redistribution terms for generated sound outputs; confirm the current generator terms before distribution.
