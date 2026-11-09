# SCRAP WARS — Replaceable Art & Animation Pipeline

## The simple replacement workflow

1. Open the project root in Godot 4.7.2.
2. Find the asset's exact path in the manifest below.
3. Replace the file in place, keeping its basename and `.png` extension. Keep its transparent background and canvas centered on the pivot described below.
4. Let Godot reimport the file, then run the game. A new project load is enough; no script edit is needed for a replacement at an already-wired path.
5. For animation, open the matching `.tres` SpriteFrames resource in Godot and edit its frames/speed. Do not rename the semantic key or folder.

If the named image/animation is absent or fails to load, SCRAP WARS retains its current procedural drawing/native control style. The physics shapes, mount positions, button text, interaction logic and save format are independent from visual artwork. A replacement is visual only; it does not change the component's gameplay behavior.

## Folder responsibilities

```text
assets/art/ui/buttons/                 named image skins for selected high-level controls
assets/art/ui/backgrounds/             menu background
assets/art/ui/illustrations/           menu feature illustration
assets/art/machines/chassis/           chassis body art; collision remains in vehicle.gd
assets/art/components/locomotion/      wheel/booster/crank part art
assets/art/components/weapons/         weapon head art
assets/art/components/armor/           armor plate art
assets/art/components/utility/         utility module art
assets/art/arenas/                     whole 1280x720 arena backgrounds; collision remains in battle.gd
assets/animations/<same semantic key>.tres
```

Art files are kept separate from `scripts/`, `scenes/`, `docs/`, licenses, and audio. Never overwrite a GDScript file with image data. Do not rename files without also intentionally changing the catalog in `scripts/art_assets.gd`.

## Static image manifest

All listed image paths are optional. Use PNG with alpha (recommended); do not change the `.png` suffix. The size column is a **logical display target**, not a required source resolution: author at 2× or 3× for sharp mobile scaling, preserve the listed aspect ratio, and keep the subject centered. Trim transparent margins only when the pivot still lines up with the mount.

| Asset key / purpose | Replaceable PNG | Logical display size | Anchor / notes |
|---|---|---:|---|
| CH-01 body | `assets/art/machines/chassis/ch-01.png` | 144×56 in battle | Center on chassis physics origin. |
| CH-02 body | `assets/art/machines/chassis/ch-02.png` | 150×44 | Center on chassis physics origin. |
| CH-03 body | `assets/art/machines/chassis/ch-03.png` | 166×72 | Center on chassis physics origin. |
| MV-01 basic wheel | `assets/art/components/locomotion/mv-01.png` | 52×52 | Center on wheel axle; physical wheel rotation rotates the image. |
| MV-02 traction wheel | `assets/art/components/locomotion/mv-02.png` | 52×52 | Center on wheel axle. |
| MV-03 booster module | `assets/art/components/locomotion/mv-03.png` | 52×52 when shown as a drive component | Center on drive socket. |
| MV-04 crank component / Garage preview | `assets/art/components/locomotion/mv-04.png` | 68×68 in Garage preview | Center on drive socket. In the arena, use the separate physical crank parts below. |
| Crank axle | `assets/art/components/locomotion/crank-axle.png` | 28×28 | Center on axle pin. |
| Crank leg/foot | `assets/art/components/locomotion/crank-leg.png` | 24×60 | Center on eccentric hinge; leg/floor physics is unchanged. |
| WP-01 Drill | `assets/art/components/weapons/wp-01.png` | 34×34 in battle | Center on spinning tool head. |
| WP-02 Rotary Saw | `assets/art/components/weapons/wp-02.png` | 40×40 in battle | Center on spinning blade. |
| WP-03 Hammer | `assets/art/components/weapons/wp-03.png` | 60×42 | Center on physical hammer head; physical hinge/collider unchanged. |
| WP-04 Rocket launcher | `assets/art/components/weapons/wp-04.png` | 48×24 | Center on launcher mount; long axis points along the weapon's local X axis. |
| AR-01 plate | `assets/art/components/armor/ar-01.png` | ~46×22 | Center on the armor rigid body. Front socket is displayed vertically. |
| AR-02 plate | `assets/art/components/armor/ar-02.png` | ~46×22 | Same mount/pivot convention. |
| AR-03 plate | `assets/art/components/armor/ar-03.png` | ~46×22 | Same mount/pivot convention. |
| UT-01 shock absorber | `assets/art/components/utility/ut-01.png` | 36×18 | Center on utility rigid body. |
| UT-02 counterweight | `assets/art/components/utility/ut-02.png` | 36×36 | Center on utility rigid body. |
| Foundry background | `assets/art/arenas/foundry-floor.png` | 1280×720 | Full-frame background; floor/ramp collision geometry stays in code. |
| Scrap Pit background | `assets/art/arenas/scrap-pit.png` | 1280×720 | Full-frame background; ramps and collision stay in code. |
| Main menu background | `assets/art/ui/backgrounds/main-menu.png` | 1280×720 | Full-frame; menu controls render over it. |
| Featured machine | `assets/art/ui/illustrations/featured-machine.png` | 320×116 | Fits the feature panel; menu copy/buttons remain separate. |

The Garage workbench also uses the chassis/component catalog images where those files exist. When a catalog image is missing, the original Garage preview is drawn instead.

## Button skins

The existing controls remain Godot `Button` nodes with real text and touch behavior. Optional button background files are read from `assets/art/ui/buttons/` for these keys: `play_campaign`, `enter_garage`, `start_battle`, `back`, `pause`, `resume`, `restart`, `slow`, and `fast`.

For example, `play_campaign.png` supplies one image for all states, or provide `play_campaign_normal.png`, `play_campaign_hover.png`, `play_campaign_pressed.png`, and `play_campaign_disabled.png`. State-specific files override the base image; a missing state uses the normal/base image. Leave a safe transparent border so the overlaid label is not clipped. The speed-down/up battle buttons display “−” and “+” while using the `slow` and `fast` art keys. Other buttons keep the existing native style until their key is explicitly mapped in `button_key_from_text()`.

Use a background treatment (no baked-in words) if the label should stay localized/readable. If you bake a label into the image, the Godot text will still render on top.

## Animation resources

The animation key matches the static asset key and resolves to:

```text
assets/animations/<asset-key>.tres
```

Examples: `assets/animations/machines/chassis/ch-01.tres`, `assets/animations/components/weapons/wp-02.tres`, `assets/animations/arenas/foundry-floor.tres`, and `assets/animations/ui/backgrounds/main-menu.tres`. Each `.tres` must be a Godot `SpriteFrames` resource with at least one non-empty animation; the first animation is played automatically. Its first frame is scaled to the same logical target size as that asset's static image. SpriteFrames should reference the frame images in your asset folders using relative `res://assets/...` references. Animation has priority over the static PNG when both exist. If the SpriteFrames resource is missing/empty, the loader tries the PNG and then the procedural fallback.

For simple button changes, use the button state PNGs above. The current runtime does **not** animate button backgrounds from SpriteFrames; animated menu background, arena, chassis, and component visuals use SpriteFrames.

## Fallback and physics separation

`ArtAssets` is an autoload (`scripts/art_assets.gd`) and the single registry of runtime paths. It only loads resources that exist. Procedural fallbacks remain in `vehicle.gd`, `wheel_draw.gd`, `crank_draw.gd`, `hammer_draw.gd`, `module_draw.gd`, `garage_preview.gd`, `battle.gd`, and `main.gd`. Replacing a sprite never edits collision shapes, PinJoint2D anchors, health, damage, mass, AI, input or save files. Keep visual pivots aligned to those existing physics origins.

## Adding a new asset slot later

Add a stable semantic key and exact path in `TEXTURE_PATHS` in `scripts/art_assets.gd`; call `ArtAssets.draw_texture()` (or `mount_animation_visual()`) at the relevant visual node; retain the old drawing as the `false`/missing-resource branch; add its path and logical dimensions to this guide; run the Godot import check and relevant gameplay smoke test. Avoid creating unexplained `new_final_v3.png` duplicates—replace the canonical file or deliberately version a new key.
