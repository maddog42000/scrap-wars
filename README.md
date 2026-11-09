# SCRAP WARS — Mobile UX, Auto-Combat & Replaceable Art Pipeline

Editable Godot **4.7.2** project continuing the original Garage and campaign milestones. The current build includes an offline profile; a three-slot socket builder; persisted combat mount rotation; five-level component upgrades; twelve campaign battles with five AI archetypes and two arenas; battle pause/speed/restart controls; and event-driven battle audio/VFX. Procedural `CPUParticles2D` produce impact sparks, hit smoke, component-break bursts, engine exhaust, rocket trails and blasts. Original generated audio loops follow engine/weapon state; metallic impacts, rocket launches and explosions fire at combat events and respect stored SFX volume. The wheel-driven auto-combat regression passes; the crank-focused test remains unstable and is explicitly reported as a known issue.

This is verified project progress, **not** a claim that the full production demo is finished. An Android APK was not exported and the game was not run on a physical Android device.

## Open and run

1. Install **Godot 4.7.2**.
2. Open `project.godot` in Godot and run the project. Display target is 1280 × 720 landscape, canvas-items stretch, GL Compatibility.
3. From the main menu, enter **Campaign**, select an available battle, review the opponent and arena, then tap **BATTLE**. Battles are automatic after the countdown. Use Replay, Garage, or Continue/Campaign on the result card.
4. In **Garage**, select a build slot and chassis, tap an owned part, then tap a compatible socket. Use Rotate/Remove on an occupied socket; the selected part’s saved 90° rotation now drives its arena mount/physics orientation. Locked catalog parts become unlockable through first-clear campaign bundles. Save locally or run a Test Build.
5. The fresh local profile starts with the standard wheel and drill. Victories unlock parts in stages. Three build slots, upgrades, scrap, campaign progress, settings and owned components persist in `user://scrap_wars_save.json`; a prior version is kept in `user://scrap_wars_save.bak`.

The project contains 3 chassis; 4 locomotion components; 4 weapons; 3 armor components; 2 utility modules; 5 AI archetypes; 12 campaign opponents in three chapters; 2 arenas; 3 build slots; three component rarity tiers; five upgrade levels; six tutorial steps; and victory, defeat and timeout result paths.

## Headless checks

Run from this folder:

```sh
godot --headless --path . --editor --quit
godot --headless --path . -- --asset-pipeline-test
godot --headless --path . -- --ui-smoke-test
godot --headless --path . -- --battle-smoke-test
godot --headless --path . -- --physics-test
godot --headless --path . -- --rotation-test
godot --headless --path . -- --battle-controls-test
timeout 25s godot --headless --path . -- --auto-combat-test
```

The asset-pipeline smoke test checks stable keys and missing-resource fallback. Temporary generated PNG and one-frame SpriteFrames resources were imported and loaded/mounted through the real runtime catalog, then removed; no test art remains in the replacement folders. The UI/campaign smoke test checks builder compatibility, JSON rotation save/load, all 12 authored builds, locked items and reward calculations; its menu harness remains open after emitting its assertions, so bound it with `timeout 7s`. `--rotation-test` runs a non-destructive arena regression with rotated player/AI mounts. `--battle-controls-test` verifies slow/fast/normal speed, pause/resume and restart-state restoration. `--auto-combat-test` runs a wheel-driven autonomous match and requires actual movement, damage and an end condition; the latest run passed by player ring-out at 8.5 seconds. `--physics-test` prints crank contact/rotation and VFX/audio counters, but its latest crank-focused fixture rang out from unstable movement and is **not a crank-locomotion pass**. Headless checks cannot establish that sounds were audible or that rendered effects look correct on a handset. In the campaign battle scene, `--campaign-battle=1` through `--campaign-battle=12` supports bounded startup checks.

All automated checks are headless. They verify game data and Godot runtime behavior; they are not a substitute for rendered UI review or touch testing on Android.

## Project layout

- `scripts/main.gd`: main menu, Garage, Inventory, Campaign, opponent preview, Settings, Tutorial and test routes.
- `scripts/game_state.gd`: catalog, chassis/socket rules, campaign opponents/rewards, validation, stats, upgrades and versioned local JSON persistence.
- `scripts/art_assets.gd`: the single registry for optional art paths, button skins, and SpriteFrames animation resources; missing assets retain procedural fallbacks.
- `scripts/garage_preview.gd`: original procedural machine/socket preview.
- `scripts/battle.gd`, `scripts/vehicle.gd`: arena, campaign flow, shared player/AI physics, component damage and battle outcomes.
- `scripts/battle_fx.gd`: reusable procedural particles, SFX playback/mixing and runtime effect diagnostics.
- `scripts/projectile.gd`, `scripts/module_draw.gd`, `scripts/hammer_draw.gd`, `scripts/crank_draw.gd`: projectile, equipment and mechanism behavior/visuals.
- `scenes/main.tscn`, `scenes/battle.tscn`, `scenes/projectile.tscn`: screen entry, arena and projectile scenes.
- `docs/SCRAP_WARS_GDD.md` and `docs/ASSET_ANIMATION_UI_AUDIO_CHECKLIST.md`: source specifications preserved in the project.
- `docs/TEST_REPORT.md`, `docs/KNOWN_ISSUES.md`, and `docs/ASSET_ANIMATION_MANIFEST.md`: verified status and remaining work.
- `docs/ART_ASSET_PIPELINE.md`: canonical replacement paths, naming conventions, target sizes/pivots, animation setup and fallback behavior.
- `assets/art/` and `assets/animations/`: organized optional image/animation folders; no fake or blank image placeholders are included.
- `assets/audio/`: original generated MP3s for engine/rotary loops and metal/rocket/blast events.
- `LICENSES/`: DejaVu Sans license and source/asset provenance notes.

Default machine/UI graphics and particle textures remain project-authored procedural rendering; optional external replacement art is wired but not yet supplied. No stock sprites or particle images are used. Audio is generated for this project and its provenance is documented in `LICENSES/ASSET_LICENSES.txt`. The font licensing text is included in `LICENSES/DejaVu-Fonts-LICENSE.txt`.

## Milestone limits and platform status

This milestone does **not** yet meet every item in the GDD’s final production delivery contract. The crank-leg mechanism uses linked rigid bodies and floor contacts, but its latest physics fixture showed excessive rotation and a ring-out; it is not a stable movement option yet. Art remains development-stage procedural graphics until replacement files are supplied; optional image and SpriteFrames paths with documented names/fallbacks are ready under `assets/art/` and `assets/animations/`. Static PNG loading, missing-file fallback, and a temporary one-frame SpriteFrames load/mount were headlessly tested; actual sprite composition, authored animation quality, and rendered/mobile/touch QA are not tested. Battle SFX and core combat particles are connected, but production mixing, music, UI/menu sounds, haptics and several checklist-specific cues (crank/booster loops, swing, victory/defeat) remain. Drill and Rotary Saw are rotating contact-sensor weapons (the Hammer head and rockets have physical bodies). Campaign battle scenes and AI builds were instantiated in headless checks, but all twelve fights have not each been observed through a complete match on a device.

No Android SDK/export toolchain and no device were available for this run. **No APK is included. Android compatibility, installation, orientation on-device, offline resume and performance are Not tested.** See `docs/KNOWN_ISSUES.md` and `docs/TEST_REPORT.md` for the exact remaining gaps.
