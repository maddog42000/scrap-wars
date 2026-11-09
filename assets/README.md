# SCRAP WARS asset folders

Existing original audio and the bundled font remain under `audio/` and `fonts/`. Optional art replacements go under `art/`; optional Godot `SpriteFrames` resources go under `animations/`.

```text
assets/
  art/
    ui/buttons/                 # button backgrounds; text remains a Godot label
    ui/backgrounds/             # menu backgrounds
    ui/illustrations/           # menu/workshop showcase art
    machines/chassis/           # CH-01.png, CH-02.png, CH-03.png
    components/locomotion/      # MV-01.png ... MV-04.png; crank-axle.png; crank-leg.png
    components/weapons/         # WP-01.png ... WP-04.png
    components/armor/           # AR-01.png ... AR-03.png
    components/utility/         # UT-01.png, UT-02.png
    arenas/                     # foundry-floor.png, scrap-pit.png
  animations/                   # matching semantic paths, ending in .tres SpriteFrames resources
  audio/                        # existing SFX
  fonts/                        # existing font
```

There are deliberately **no blank image placeholders** in the art folders. Read `../docs/ART_ASSET_PIPELINE.md` before adding assets: it lists exact active paths, expected logical sizes, image rules, animation setup, fallbacks, and replacement steps. Static art is optional: where no matching file exists, the current procedural drawing/native style continues to render.
