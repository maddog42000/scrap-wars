# SCRAP WARS contributor / agent instructions

## Project facts

- Godot **4.7.2**, 2D, landscape 1280×720, GL Compatibility.
- Offline-first; player progress is local JSON. Do not add accounts, online multiplayer, cloud saves, ads, or external APIs unless the owner explicitly changes scope.
- The current game is a working development milestone, not a finished production demo. `docs/KNOWN_ISSUES.md` and `docs/TEST_REPORT.md` are the source of truth for verified status and limitations.

## When the owner requests an art replacement

1. Read `docs/ART_ASSET_PIPELINE.md` before touching assets. It is the canonical filename, folder, logical-size, pivot, and animation guide.
2. Replace an already-wired image **at the same path and with the same basename/extension** under `assets/art/`. Do not create empty/grey placeholder art. If a new slot is needed, register it in `scripts/art_assets.gd`, wire the display node, retain the current procedural drawing as its fallback, and update the guide/manifest.
3. For supported animated machine/component/arena/menu-background art, use a Godot `SpriteFrames` resource at the same semantic key under `assets/animations/<key>.tres`. Edit its frames/speed in Godot. The animation loader takes priority over the matching static PNG. Button backgrounds currently support base/state PNGs, not SpriteFrames animation.
4. Artwork changes are visual-only: do not change physics shapes, mount origins, damage, mass, component IDs, game logic, saves, or campaign data to make a picture fit. Align the image canvas/pivot to the documented mount.
5. Use original or properly licensed artwork; document source/license/provenance in `LICENSES/ASSET_LICENSES.txt` before adding third-party material.
6. Do not remove or replace the procedural fallback without explicit approval. No replacement art files are currently included; the asset folders contain readmes, not mock images.

## Validation

At minimum run from the project root:

```sh
godot --headless --path . --editor --quit
godot --headless --path . -- --asset-pipeline-test
godot --headless --path . -- --rotation-test
godot --headless --path . -- --battle-controls-test
timeout 25s godot --headless --path . -- --auto-combat-test
```

The crank-focused `--physics-test` currently fails stable locomotion; see `docs/TEST_REPORT.md`. Headless success is not rendered/mobile QA. Do not claim APK availability, Android compatibility, or device verification unless an APK is actually exported and tested on hardware. Keep `docs/TEST_REPORT.md` and `docs/KNOWN_ISSUES.md` truthful when validation changes.
