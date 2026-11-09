# SCRAP WARS — Replaceable Art Pipeline & Regression Test Report

**Test date:** 2026-11-08 (sandbox clock)  
**Milestone:** Replaceable image/animation path wiring with procedural fallbacks; prior Garage/Campaign/mobile UX/audio-VFX systems retained  
**Engine observed:** Godot 4.7.2.stable.official.ed1daf0bf  
**Host:** Linux sandbox, headless Godot runtime  
**Project:** `/home/ubuntu/SCRAP_WARS_Physics_Proof`  
**Android device/model/version:** Not tested  
**APK/build identifier:** No APK exported

## Tests actually run

| Test | Result | Evidence / limit |
|---|---|---|
| Godot editor/import startup | PASS | `godot --headless --path . --editor --quit` completed without reported script/resource errors during final checks. Godot loaded the project at 4.7.2. |
| Optional art paths / fallback / SpriteFrames loader | PASS (headless) | `ART_ASSET_PIPELINE_TEST` confirmed all keys mapped, missing PNG/animation fallbacks, and then loaded a temporary generated 4×4 PNG plus a one-frame SpriteFrames `.tres` at CH-01 (`sample_texture_loaded=true sample_frames_loaded=true sample_animation_mounted=true`). All temporary resources and import sidecars were removed. No final art was supplied and no rendered visual QA was done. |
| UI scene construction | PASS (headless only) | Smoke output included `UI_SCREEN_OK` for garage, inventory, campaign, preview, settings, tutorial, and garage after return. No rendered UI or touch device was used. |
| Builder compatibility and persistence data path | PASS (automated) | `incompatible_rejected=true`, `compatible_install=true`, `rotation_saved=true`, `restored_valid=true`. The test wrote a 90° weapon rotation, invoked the actual JSON save and load methods, then confirmed the rotation was restored. Six Scrapbox sockets; valid starter build measured mass 14.0, core 320, drive ~142.86, traction 100, damage 9, armor 0, stability 91.2. |
| Saved rotation applied to arena physics | PASS (headless regression) | In an isolated project copy, a seeded on-disk profile with 90°/180°/270° rotations was loaded by GameState and started in the real battle scene. `ROTATION_ARENA_TEST player_mounts=true ai_mounts=true ... ROTATION_ARENA_TEST_PASS result=true`. Verified player weapon/hammer mount, wheel phase, crank phase, armor, shock module, sensor transform and rocket direction; verified rotated AI weapon, wheel, armor and utility using the same vehicle setup code. A self-contained, non-destructive `--rotation-test` mode now reproduces the arena assertion. No rendered/device visual inspection was done. |
| Fresh-profile locked catalog | PASS (automated) | Forced owned list to MV-01/WP-01 for the smoke test; `LOCKED_INVENTORY_TEST card=true unlock_hint=true` for WP-02. Test state was restored afterward. |
| Twelve data-authored campaign builds | PASS (automated) | `CAMPAIGN_DATA_CHECK battles=12 valid_builds=true archetypes=5 arenas=2 boss_nodes=3`; each build was checked against items available before that fight. |
| Campaign battle scenes 1–12 | PASS (bounded startup) | Each numbered battle scene emitted `CAMPAIGN_OPPONENT ... valid=true`, with no logged script/runtime errors during its bounded startup run. Chapters 1–2 assigned Foundry; battles 9–12 assigned Scrap Pit. This was a scene/configuration pass, **not** twelve completed battle playthroughs. |
| Final boss crank configuration | PASS (data/startup) | Battle 12’s logged loadout contained `MV-04@L5`; other late-campaign builds use the same physical component construction path as player builds. |
| Campaign first-clear/replay/economy rules | PASS (automated) | `REWARD_TEST first_clear=true scrap=43 components=[MV-02,MV-03,WP-02] repeat_win=0 defeat=10 draw=15`. This verifies the reward calculation and unlock list in a simulated first-clear state, not a human UI claim flow. |
| Selected Garage build into battle | PASS (startup/configuration) | Observed `BATTLE_LOADOUT chassis=CH-01 slot=1 parts=MV-01,MV-01,WP-01 configured=true`; selected IDs are passed to the player machine. |
| Physics proof, damage and crank-leg movement | FAIL / partial | Latest `--physics-test` emitted `crank_cumulative_rotation_rad=2180.85` (~347 turns) and `max_crank_leg_floor_contacts=3`, confirming the linked crank/foot contacts the floor; however, the test machine traveled 6,403.7 px and rang out in a defeat at displayed `duration_s=0.0`. This is unstable and does **not** pass reliable crank-powered locomotion. Crank motor dynamics require further tuning before this feature is production-ready. |
| Autonomous full-battle regression | PASS (headless, 20-second test harness) | Most recent run: player advance 363.9 px, AI advance 842.5 px, 9/16 hit callbacks, raw damage counters 144/81, and a natural player ring-out at 8.5 seconds; `ended=true`, `BATTLE_END DEFEAT`, `AUTO_COMBAT_TEST_PASS result=true`. This regression uses the standard wheel-driven starter build; it does not verify the battle reward-claim flow. |
| Pause, resume, battle speed and restart | PASS (headless regression) | `BATTLE_CONTROL_TEST slow=true fast=true normal=true pause=true resume=true`; after scene restart, `restart_restores_speed_pause_and_scene=true`. This tests control logic/state restoration, not touch-target visuals or handset input. |
| Saved mount-rotation arena regression | PASS (headless) | `ROTATION_ARENA_TEST player_mounts=true ai_mounts=true ... ROTATION_ARENA_TEST_PASS result=true`. Confirms rotated build data reaches player and AI arena mounts; rendered orientation remains Not tested. |
| Combat VFX and SFX event integration | PASS (headless runtime counters) | Latest physics run emitted 3 weapon impacts, 3 rocket-launch cues, 1 explosion, 1 component-break event, 18 procedural CPU-particle emitters, and 8 one-shot audio starts; `all_sfx_assets_loaded=true`. Player/AI engine resources loaded; the player engine loop started. Final suite logs contained no script/resource/ObjectDB leak warnings. Counts describe this controlled run. |
| Local profile persistence | PARTIAL | Save/restore path and JSON backup code are present; test smoke explicitly restored modified build/profile state. Full fresh-process restart and deliberate corrupt-file recovery were Not tested in this milestone. |
| Main-menu/garage/inventory/campaign rendered screen review | Not tested in this pass | An earlier headless smoke verified screen construction; current milestone checks did not use rendered screenshots, pointer/touch interaction, or Android. |
| Entire 12-battle campaign through results | Not tested | Scenes and data validated across all 12; one autonomous wheel-driven test match reached a ring-out result. Do not interpret scene-start validation as a completed twelve-fight playtest or as reward-claim verification. |
| Rendered layout, aspect ratios, mobile touch operation | Not tested | Headless control construction only; no screenshot-based visual QA, mouse play session or Android touch test. |
| Android export/APK install/orientation/offline resume/performance | **Not tested** | No Android SDK/export templates/device toolchain or physical device was available (`adb`, `sdkmanager`, `avdmanager`, and `gradle` were not found). No APK was built. The source project sets Godot handheld orientation to enum `0`; Godot 4.7.2 constants identify that as Landscape, but actual device orientation is Not tested. |
| Generated SFX decode/resource load and playback requests | PASS (headless) | Five project-specific MP3s decoded/imported; engine and rotary loops loaded/started, and hit/launch/blast event playback was requested. `sfx_volume` is applied to loop and one-shot players. This checks Godot resource loading and playback state only; audio was not heard on speakers/headphones. |
| Audio mix, sound quality, Android playback, music/UI cues and haptics | Not tested / partial | No physical audio-output device was used. Music, UI/menu interaction sounds, dedicated crank/booster/hammerswing/victory/defeat cues, haptics, final loudness balance and Android audio focus/resume remain unimplemented or untested. |
| Rendered particle appearance/performance | Not tested | CPU particles were instantiated and counted in headless Godot, but pixels, overdraw, frame-time impact and handset visuals were not inspected. |

## Reproduction commands

From the project folder:

```sh
godot --headless --path . --editor --quit
godot --headless --path . -- --asset-pipeline-test
timeout 7s godot --headless --path . -- --ui-smoke-test
godot --headless --path . -- --battle-smoke-test
godot --headless --path . -- --physics-test
godot --headless --path . -- --rotation-test
godot --headless --path . -- --battle-controls-test
timeout 25s godot --headless --path . -- --auto-combat-test
timeout 3s godot --headless --path . -- --campaign-battle=12
```

`--asset-pipeline-test` checks the stable asset-key registry and graceful missing-PNG/SpriteFrames fallback. Temporary generated PNG and one-frame SpriteFrames resources were also imported, loaded and mounted in this milestone, then removed. `--physics-test` runs for about eight seconds and prints physics/VFX/audio counters. Its current crank-focused fixture demonstrates floor contact but fails reliable locomotion because it rings out. `--auto-combat-test` runs a separate wheel-driven match and currently passes. The UI smoke harness prints its assertions but remains in the menu afterward; use `timeout 7s` for that command. A timeout-bounded campaign startup is not a completed match.

## Scope status

The editable project has a three-slot socket builder and local save flow; the full counted item catalog; visible locked states; five data-authored AI archetypes; twelve opponent definitions; three chapter bosses; first-clear equipment unlocks and one-time reward tracking; two arena configurations; a selected-build automatic battle setup; and passing wheel-driven autonomous combat and battle-control regressions. All twelve opponent configurations started successfully in Godot headless. The crank-focused fixture records real foot/floor contacts but is unstable and is not a passing locomotion proof.

Still short of GDD production acceptance: no APK or Android/device verification; art/effects remain procedural development assets; no completed visual/touch/audio-device QA; music, several checklist-specific SFX and haptics remain; Drill/Saw are sensor-based contact weapons; and twelve campaign fights have not each been run to a result. Refer to `KNOWN_ISSUES.md` for exact remaining scope.


## Additional final runtime spot-checks

Two more bounded live physics sessions were run after the twelve-scene startup sweep: battle 8 (`Anvil Prime`, Siegebreaker, WP-04 rocket launcher, Foundry boss) and battle 9 (`Dust Devil`, Spinner, Scrap Pit). Each ran for 8 seconds in headless Godot, printed its valid authored opponent/loadout, emitted no script/runtime errors, and ended only because the external timeout stopped the still-running match. These checks cover live startup in a rocket-focused build and the Scrap Pit ramp geometry; they do **not** demonstrate a completed fight or validate a rendered camera/UI.
