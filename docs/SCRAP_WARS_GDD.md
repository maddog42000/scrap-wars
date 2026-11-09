# SCRAP WARS
## Developer Handoff Package: Android Vertical Slice / Playable Test Demo

**Document version:** 1.0  
**Project status:** Production specification, ready for implementation  
**Working title:** SCRAP WARS  
**Target platform:** Android phones and tablets  
**Engine:** Godot 4.7.2, 2D renderer  
**Primary language:** GDScript  
**Orientation:** Landscape  
**Initial release format:** Installable debug APK for testing  
**Distribution format later:** Signed Android App Bundle (AAB)  
**Core mode:** Offline single-player campaign against AI machines

---

# 1. DELIVERY CONTRACT

Build a complete, playable Android game demo, not a mock-up, menu prototype, animation reel, or collection of disconnected scenes.

The player must be able to:

1. Launch the game.
2. Enter the garage.
3. Select a chassis and equip real components from an inventory.
4. Move components between valid attachment points and rotate compatible parts.
5. See live machine statistics update.
6. Save the machine.
7. Enter a battle against an AI-controlled machine.
8. Watch both machines move and fight using the same physics and component rules.
9. Damage and disable individual components.
10. Win or lose through defined battle conditions.
11. Receive scrap and equipment rewards.
12. Return to the garage, upgrade or rebuild, and fight again.
13. Close and reopen the app without losing progress.

**No placeholder content is permitted in the final demo.** Every visible icon, sprite, machine, enemy, background, sound, animation, menu, button, reward, and tutorial panel must be a finished original asset or a clearly polished procedural visual created for this game. Do not ship grey boxes, “TODO” labels, empty buttons, temporary stock art, debug labels, or unimplemented menu entries.

The demo must be delivered as:
- A complete Godot project folder that opens in Godot 4.7.2.
- An installable Android APK built from that project.
- A ZIP containing the complete project and all source assets.
- A short README with import, run, export, and testing instructions.
- A known-issues list, if any.
- A test report confirming the acceptance criteria in this document.

The APK must be built from the exact project included in the ZIP. Record the Godot version, Android target settings, build date, and project commit/version in the README.

---

# 2. PRODUCT VISION

SCRAP WARS is a landscape, side-view, physics-based machine-building arena game. Players assemble improvised combat machines from modular chassis, locomotion systems, weapons, armor, and utility components. Once a battle starts, the machines fight automatically. The player wins through engineering choices rather than direct combat controls.

The reference category is vehicle-building arena combat, with CATS: Crash Arena Turbo Stars as a genre reference. Study the appeal of short automated battles, readable machine silhouettes, component loot, and quick rebuild loops. Do not copy its characters, artwork, UI, exact component designs, names, sounds, progression presentation, or other protected expression. All SCRAP WARS assets and interface designs must be original.

## Design pillars

1. **Build freedom:** Components create visibly different machines and strategies.
2. **Physics that matters:** Mass, center of mass, traction, leverage, collision, and weapon placement influence outcomes.
3. **Readable combat:** A player can understand why a machine won or lost.
4. **Fast replay loop:** Battles are short and the player can quickly rebuild.
5. **Rewarding collection:** New components change possible builds, not just numbers.
6. **Mobile clarity:** Large touch targets, landscape UI, readable type, and strong silhouettes.
7. **Offline-first:** The complete demo works without accounts, internet, ads, or network services.

## Player fantasy

“I built this ridiculous machine, and it actually works.”

The garage is the main creative space. The arena proves whether the design works.

---

# 3. DEMO SCOPE: EXACT CONTENT

The first demo is a polished vertical slice, not the full long-term game.

## Required playable content

| Content | Exact demo quantity |
|---|---:|
| Chassis | 3 |
| Locomotion components | 4 |
| Weapons | 4 |
| Armor components | 3 |
| Utility/booster components | 2 |
| AI machine archetypes | 5 |
| Campaign battles | 12 |
| Arenas | 2 |
| Machine build save slots | 3 |
| Component rarity tiers | 3 |
| Upgrade levels per component | 5 |
| Tutorial steps | 6 |
| Battle result types | Victory, defeat, timeout |
| Local currencies | 1: Scrap |
| Player profile | 1 local profile |

Do not expand the demo scope by adding online multiplayer, guilds, chat, accounts, cloud saves, battle passes, ads, or a live-service backend. Those are future features.

## Chassis

**CH-01 Scrapbox**
- General-purpose rectangular chassis.
- Balanced mass and durability.
- Four standard attachment points: front weapon, rear utility, upper armor, lower armor.
- Two drive mount points.

**CH-02 Needle**
- Lightweight narrow chassis.
- Lower durability, higher acceleration potential.
- Front weapon, rear utility, two side armor points, two drive mounts.
- Lower center-of-mass profile.

**CH-03 Bulwark**
- Heavy armored chassis.
- High durability and mass.
- Front weapon, upper armor, two side armor points, rear utility, two drive mounts.
- Slower acceleration and greater resistance to being pushed.

All chassis must have unique silhouettes, finished sprites, collision geometry, attachment-point metadata, and garage thumbnails.

## Locomotion components

**MV-01 Standard Wheel**
- Reliable general-purpose wheel.
- Moderate traction and speed.
- Uses a powered wheel joint/motor.

**MV-02 Grip Wheel**
- Higher traction, lower top speed.
- More resistant to slipping under load.

**MV-03 Booster**
- Applies a short forward impulse on a cooldown.
- Has a visible exhaust effect and a distinct sound.
- Limited charges or cooldown per battle; specify one consistent rule in implementation.

**MV-04 Crank Leg**
- Signature locomotion component.
- A rotating eccentric crank drives a hinged leg through a repeating cycle.
- The foot must contact the floor and apply force to move the chassis.
- It must not be a decorative spinning wheel or a sprite animation that moves the machine without physics.
- Include a visible crank axle, connecting rod, hinged leg, and foot.
- Build and test it as a real jointed mechanism. If the full linkage proves unstable, use a simplified motorized crank with a hinged leg and controlled ground-contact force, but preserve visible mechanical movement and physical interaction.

## Weapons

**WP-01 Drill**
- Close-range contact weapon.
- Rotating head.
- Applies repeated damage while in contact.
- Strong against a target it can keep pressed against.

**WP-02 Rotary Saw**
- Close-range rotating blade.
- Repeated contact damage.
- Produces sparks and metal-hit audio.
- Visually distinct from the drill.

**WP-03 Hammer**
- Motorized or timed swinging arm.
- Wind-up, strike, and recovery phases.
- Deals burst damage and angular impulse on impact.
- Must have a visible swing animation tied to its actual weapon motion.

**WP-04 Rocket Launcher**
- Fires a physical projectile with a visible exhaust trail.
- Projectile has travel speed, impact damage, and a small area-of-effect blast.
- Has a reload/cooldown.
- Must not fire through the owner's chassis.

## Armor

**AR-01 Front Plow**
- Angled front armor.
- Helps deflect or redirect collisions.
- Has its own durability.

**AR-02 Reinforced Plate**
- General-purpose armor.
- Adds mass and component health.

**AR-03 Side Cage**
- Protects side-mounted parts from some impacts.
- Adds mass and occupies side attachment points.

## Utility

**UT-01 Shock Absorber**
- Reduces transmitted impact effects or improves stability using a documented physics implementation.
- Adds mass.

**UT-02 Counterweight**
- Adds configurable mass at its attachment location.
- Changes center of mass and stability.
- It is not a flat “power” bonus.

## AI archetypes

Each AI opponent must be assembled from the same valid chassis and component system available to the player. AI machines may use upgraded versions of available components but cannot use impossible attachment locations, hidden collision advantages, or secret physics multipliers.

1. **Rammer:** Bulwark, front plow, heavy drive setup, prioritizes forward contact.
2. **Skirmisher:** Needle, grip wheels, booster, attempts to approach quickly.
3. **Crusher:** Scrapbox or Bulwark, drill, reinforced armor.
4. **Spinner:** Scrapbox, rotary saw, counterweight; prioritizes stable contact.
5. **Siegebreaker:** Bulwark, rocket launcher, shock absorber; uses ranged pressure then closes distance.

AI behavior should be simple, robust, and deterministic enough for repeatable testing. Use the same physics rules as the player.

## Arenas

**AR-ARENA-01 Foundry Floor**
- Flat industrial floor.
- Side walls and clearly visible knockout boundaries.
- Background machinery, overhead lights, warning stripes, distant silhouettes.
- No moving hazards in the first demo.

**AR-ARENA-02 Scrap Pit**
- Flat central fighting floor with a shallow central depression or raised side platforms only if stable and fair.
- Strong visual identity distinct from Foundry Floor.
- Clearly visible arena boundaries.
- No random hazards in the first demo.

Both arenas must have finished backgrounds, floor art, collision geometry, lighting treatment, and camera framing.

## Campaign

12 battles, arranged in three chapters of four battles:
- Chapter 1: Yard Trials, battles 1–4.
- Chapter 2: Foundry Circuit, battles 5–8.
- Chapter 3: Scrap Pit Championship, battles 9–12.

Each battle has a named opponent, a defined machine build, a reward, and a difficulty target. Battle 4, 8, and 12 are chapter bosses with more challenging builds. Campaign progression unlocks the next battle after victory. A defeated battle can be replayed.

---

# 4. CORE GAME LOOP AND SCREEN FLOW

## Main loop

Main Menu → Garage → Build/Test → Battle Selection → Opponent Preview → Countdown → Automatic Battle → Results → Rewards → Garage.

The player must never get stuck in a screen without a working Back, Continue, or Home action.

## Required screens

### S-01 Main Menu
- Game logo and animated featured player machine.
- Play Campaign button.
- Garage button.
- Parts Inventory button.
- Settings button.
- Player scrap balance.
- Campaign progress indicator.
- All buttons functional.

### S-02 Garage
- Machine displayed large and centered.
- Chassis selector.
- Component inventory panel.
- Attachment-point highlights.
- Component drag/drop and tap-to-equip support.
- Rotate control for compatible parts.
- Remove/swap control.
- Machine stat panel.
- Save build button.
- Test Build button.
- Battle button.
- Scrap balance.
- Clear selected component details: name, description, mass, durability, cost, rarity, and function.

Touch interaction must work on phones. Do not require a mouse.

### S-03 Parts Inventory
- Categorized tabs: Chassis, Movement, Weapons, Armor, Utility.
- Owned and locked states.
- Component details.
- Upgrade action.
- Upgrade cost and current level.
- Clear indication when an item is equipped in a saved build.

### S-04 Campaign Map / Battle Select
- Three chapter panels.
- Twelve battle nodes.
- Locked, available, completed, and boss states.
- Opponent name, machine preview, reward, and difficulty.
- Replay completed battles.

### S-05 Opponent Preview
- Player machine and enemy machine.
- Arena name.
- Opponent archetype.
- Battle button.
- Return to garage button.

### S-06 Battle
- Landscape camera with both machines visible.
- Three-second countdown.
- Player and enemy health bars.
- Battle timer.
- Component damage feedback.
- Pause button.
- Speed control is optional; if included, it must not break physics or result validation.
- Clear arena boundaries and knockout area.

### S-07 Results
- Victory/defeat/timeout label.
- Scrap earned.
- Component reward, if awarded.
- Battle duration.
- Clear short explanation of the outcome, such as “Core destroyed,” “Pushed out of arena,” or “Time expired: opponent had more core health.”
- Replay, Continue, Garage, and Campaign buttons as appropriate.

### S-08 Settings
- Music volume.
- Sound effects volume.
- Haptics toggle.
- Reduced screen shake toggle.
- Reset tutorial option.
- Data reset option with a confirmation dialog.
- Back button.

### S-09 Tutorial
Six concise steps:
1. Choose a chassis.
2. Equip a movement component.
3. Equip a weapon.
4. Check mass and machine statistics.
5. Start a battle.
6. Collect scrap and improve a component.

Tutorial callouts must point to real UI controls. No fake buttons.

---

# 5. MACHINE BUILDER: FUNCTIONAL SPECIFICATION

## Attachment model

Every chassis defines named attachment sockets. Every component declares allowed socket types, local position, local rotation, mass, durability, and gameplay category.

Component placement must:
- Snap to a valid socket.
- Show a valid-placement highlight.
- Show an invalid-placement response.
- Prevent incompatible components.
- Prevent two components occupying the same exclusive socket.
- Respect chassis-specific maximum load.
- Recalculate mass and center of mass.
- Update stats immediately.
- Save and restore exact component IDs, socket IDs, and rotation.

Support drag-and-drop and tap-to-select/tap-to-place. Include a visible remove/swap action.

## Build validation

A build is battle-ready only when:
- It has one chassis.
- It has at least one functional movement component.
- It has at least one weapon.
- It does not exceed the chassis load limit.
- Every component occupies a valid socket.
- No duplicate exclusive socket is occupied.

If a build is invalid, show the exact reason and a direct route to fix it.

## Machine statistics

Show:
- Total mass.
- Core health.
- Drive force / movement rating.
- Traction rating.
- Weapon damage rating.
- Armor rating.
- Stability indicator.

These are explanatory indicators, not a single combat-power score that determines the winner. The battle outcome must be simulated.

## Saved builds

Provide three local build slots. Each slot stores the chassis ID and installed component IDs/socket assignments/rotations. Loading a build must validate that all required parts are still owned and available.

---

# 6. PHYSICS AND COMBAT IMPLEMENTATION

This is the highest-risk system and must be prototyped before the full UI is built.

## Physics architecture

Use Godot 2D physics. Prefer RigidBody2D for the chassis and physical moving components, StaticBody2D for the arena floor/walls, and appropriate joints/motors for rotating and hinged mechanisms.

Use collision layers and masks consistently:
- Arena.
- Player chassis.
- Enemy chassis.
- Player components.
- Enemy components.
- Projectiles.
- Effects/non-colliding visuals.

Do not make every decorative bolt a rigid body. Use a small number of meaningful physical bodies and simple collision shapes.

Do not move RigidBody2D nodes by setting their position every frame. Use forces, impulses, joints, motors, and supported physics callbacks.

## Machine scene contract

Suggested machine scene:
- MachineRoot (Node2D)
  - ChassisBody (RigidBody2D)
    - ChassisCollision (CollisionShape2D)
    - ChassisSprite (Sprite2D)
  - ComponentMounts (Node2D)
  - ComponentInstances (Node2D)
  - MachineController (Node)
  - MovementController (Node)
  - WeaponController (Node)
  - DamageController (Node)
  - MachineEffects (Node2D)
  - AudioController (Node)
  - HealthDisplay (Node2D)

This is a suggested organization, not a requirement to use these exact node names if the implementation has a better documented architecture.

## Movement

Powered wheels must apply motor torque through a wheel joint or a controlled wheel body/joint. Grip differences must be represented through friction/traction and motor settings.

Booster applies a limited impulse in the machine's forward direction with a cooldown. Add a short exhaust animation and audio cue.

Crank Leg must use a rotating crank and hinged leg that visibly cycles and interacts with the floor. A stable simplified physical implementation is acceptable, but it must produce movement through ground interaction, not scripted teleportation.

## Weapon behavior

- Drill: repeated contact damage with a short damage interval; sparks on contact.
- Saw: repeated contact damage; spinning blade; sparks and metal-hit sound.
- Hammer: wind-up, strike, recovery; burst damage and impulse on impact.
- Rocket: physical projectile, cooldown, collision, impact damage, small blast radius, explosion effect.

Each weapon must have its own durability. When destroyed, it stops dealing damage and changes to its damaged visual state.

## Damage model

Every component has individual health. The chassis has core health.

Damage events include:
- Source component.
- Target component or chassis.
- Damage amount.
- Impact direction/force where applicable.
- Damage type.

Armor must protect the physical region it covers; it must not grant a global invisible defense bonus.

When a component reaches zero health:
- Disable its function.
- Play its destruction effect.
- Hide or detach it using a stable implementation.
- Update machine capability.
- Continue the battle if the chassis remains operational.

For the first demo, components may become disabled and remain attached rather than being physically detached if detachment causes instability. This must still be visually communicated.

## Battle end conditions

A battle ends when:
1. A machine's core health reaches zero.
2. A machine's chassis crosses the knockout boundary.
3. The timer expires.

On timeout, compare remaining core-health percentage. If tied within a small documented tolerance, use remaining total component health, then declare a draw if still tied. A draw must have a defined reward outcome and must not soft-lock the campaign.

Add a maximum battle duration. No battle may run forever.

## Camera

Use a camera that keeps both machines and the relevant arena boundaries visible. Add subtle impact shake, with a settings toggle. Do not shake so much that players lose track of the action.

---

# 7. AI SPECIFICATION

AI must build and fight using the same machine component data and physics rules as the player.

For the demo, AI may use simple tactical behavior:
- Rammer: maintain forward drive and seek contact.
- Skirmisher: use booster early, close distance, attack.
- Crusher: drive steadily and maintain weapon contact.
- Spinner: prioritize stable orientation and repeated contact.
- Siegebreaker: fire rockets when within valid range, then advance.

Do not make AI machines invulnerable, secretly heavier, or exempt from collision rules.

Enemy builds must be authored as data configurations using the same component IDs and socket validation used by player builds.

---

# 8. ART ASSET MANIFEST: NO PLACEHOLDERS

All assets below must be produced as original finished game assets. Each item must exist in the delivered project, be named consistently, and be used in-game. If a listed asset is intentionally combined into a sprite sheet, document the frame rectangles and pivots in an asset manifest.

## Machine and component art

| Asset ID | Required finished asset |
|---|---|
| spr_chassis_scrapbox | Scrapbox chassis side-view sprite |
| spr_chassis_needle | Needle chassis side-view sprite |
| spr_chassis_bulwark | Bulwark chassis side-view sprite |
| spr_wheel_standard | Standard wheel sprite |
| spr_wheel_grip | Grip wheel sprite |
| spr_booster | Booster body sprite |
| spr_crank_axle | Crank axle sprite |
| spr_crank_rod | Crank connecting rod sprite |
| spr_crank_leg | Crank leg sprite |
| spr_crank_foot | Crank foot sprite |
| spr_weapon_drill_base | Drill mount/body sprite |
| spr_weapon_drill_head | Drill rotating head sprite |
| spr_weapon_saw | Rotary saw assembly sprite |
| spr_weapon_hammer_base | Hammer mount sprite |
| spr_weapon_hammer_head | Hammer head sprite |
| spr_weapon_rocket | Rocket launcher sprite |
| spr_rocket_projectile | Rocket projectile sprite |
| spr_armor_plow | Front plow sprite |
| spr_armor_plate | Reinforced plate sprite |
| spr_armor_cage | Side cage sprite |
| spr_shock_absorber | Shock absorber sprite |
| spr_counterweight | Counterweight sprite |

Every component sprite must include a documented origin/pivot, collision shape, socket requirements, and visual scale. Avoid sprites that visually overlap or obscure critical weapon contact points.

## Machine states and damage art

For each of the three chassis, provide:
- Normal state.
- Damaged state.
- Critical/destroyed state or a clear damaged overlay.
- Garage thumbnail.

For components, provide normal and disabled/damaged states where visible. At minimum, weapon heads, wheels, booster, crank leg, and armor must visually communicate disabled/destroyed status.

## Backgrounds

| Asset ID | Required finished asset |
|---|---|
| bg_garage | Full garage background |
| bg_arena_foundry | Foundry arena background |
| bg_arena_scrap_pit | Scrap Pit arena background |
| spr_arena_floor_foundry | Foundry floor strip |
| spr_arena_floor_scrap | Scrap Pit floor strip |
| spr_arena_wall | Arena boundary/wall art |
| spr_garage_lamp | Garage lighting fixture |
| spr_garage_machine_detail | Background machinery detail set |

Backgrounds must be composed for 16:9 landscape and adapt to common Android landscape aspect ratios without stretching critical artwork.

## UI art

| Asset ID | Required finished asset |
|---|---|
| ui_logo_scrap_wars | Original game logo |
| ui_button_primary | Primary button, normal/pressed/disabled |
| ui_button_secondary | Secondary button, normal/pressed/disabled |
| ui_panel | Reusable panel frame |
| ui_tab | Tab, selected/unselected |
| ui_currency_scrap | Scrap currency icon |
| ui_icon_chassis | Chassis category icon |
| ui_icon_movement | Movement category icon |
| ui_icon_weapon | Weapon category icon |
| ui_icon_armor | Armor category icon |
| ui_icon_utility | Utility category icon |
| ui_icon_upgrade | Upgrade icon |
| ui_icon_rotate | Rotate icon |
| ui_icon_remove | Remove component icon |
| ui_icon_save | Save build icon |
| ui_icon_battle | Battle icon |
| ui_icon_settings | Settings icon |
| ui_health_bar | Health bar frame and fill |
| ui_timer_frame | Battle timer frame |
| ui_rarity_common | Common rarity frame |
| ui_rarity_uncommon | Uncommon rarity frame |
| ui_rarity_rare | Rare rarity frame |
| ui_reward_card | Reward card frame |
| ui_lock | Locked state icon |
| ui_check | Completed state icon |
| ui_warning | Invalid build warning icon |
| ui_tutorial_pointer | Tutorial pointer/hand |
| ui_victory_emblem | Victory result emblem |
| ui_defeat_emblem | Defeat result emblem |
| ui_draw_emblem | Draw result emblem |

Use readable fonts with appropriate redistribution licenses. Include font license files in the ZIP.

## VFX assets

Create original effects:
- fx_sparks_small.
- fx_sparks_heavy.
- fx_metal_hit.
- fx_drill_contact.
- fx_saw_contact.
- fx_hammer_impact.
- fx_rocket_trail.
- fx_rocket_explosion.
- fx_booster_exhaust.
- fx_smoke_small.
- fx_smoke_heavy.
- fx_component_disabled.
- fx_victory_confetti or arena celebration effect.

These may be particle systems rather than image sequences, but they must be implemented and tuned in the game.

---

# 9. ANIMATION MANIFEST

Every animation must be connected to gameplay state, not merely played decoratively.

## Garage animations

1. Featured machine idle: subtle chassis bob, wheel movement, occasional mechanical movement.
2. Component equip: component moves/snaps into socket with a short scale/flash response.
3. Component remove: component detaches from socket and returns to inventory.
4. Invalid placement: brief red highlight and small rejection movement.
5. Wheel spin: wheel rotation responds to machine test movement.
6. Crank leg cycle: axle rotates, rod moves, leg cycles, foot contacts the floor.
7. Booster preview: brief exhaust burst.
8. Weapon preview: drill/saw rotate; hammer swings in a safe preview loop.

## Battle animations

1. Countdown: 3, 2, 1, FIGHT.
2. Wheel rotation tied to angular velocity.
3. Chassis suspension/bounce based on physical motion.
4. Crank-leg locomotion cycle tied to motor state.
5. Booster activation and exhaust.
6. Drill rotation and contact sparks.
7. Saw rotation and contact sparks.
8. Hammer wind-up, strike, recoil, recovery.
9. Rocket launch, trail, impact and explosion.
10. Collision recoil and small camera shake.
11. Light damage smoke.
12. Critical damage smoke/flame.
13. Component disabled/destroyed response.
14. Core destruction sequence.
15. Knockout/fall sequence if pushed beyond boundary.
16. Victory celebration.
17. Defeat result transition.

Animation timing should be tuned to the actual physics. A hammer strike must line up with the physical hitbox. A rocket effect must follow the projectile. Wheel speed must reflect movement speed.

---

# 10. AUDIO MANIFEST

All audio must be original or have a documented license permitting commercial use and redistribution.

Required sound effects:
- sfx_ui_button.
- sfx_component_equip.
- sfx_component_remove.
- sfx_invalid_placement.
- sfx_battle_countdown.
- sfx_battle_start.
- sfx_wheel_loop.
- sfx_crank_leg_loop.
- sfx_booster_burst.
- sfx_drill_loop.
- sfx_saw_loop.
- sfx_hammer_swing.
- sfx_hammer_impact.
- sfx_rocket_launch.
- sfx_rocket_impact.
- sfx_metal_collision_light.
- sfx_metal_collision_heavy.
- sfx_armor_hit.
- sfx_component_break.
- sfx_core_destroyed.
- sfx_victory.
- sfx_defeat.
- sfx_reward_collect.

Required music:
- music_menu_garage: one loop.
- music_battle: one loop.
- music_results: one short loop or stinger set.

Audio must have separate music and SFX volume settings. Looped sounds must stop when the associated component is disabled or the scene changes.

---

# 11. TECHNICAL PROJECT STRUCTURE

Use a modular project. The following is the required logical organization; developers may adjust filenames if they document the mapping.

res://
  project.godot
  README.md
  LICENSES/
  assets/
    art/
      machines/
      components/
      backgrounds/
      ui/
      vfx/
    audio/
      music/
      sfx/
    fonts/
  data/
    chassis/
    components/
    enemies/
    campaign/
    arenas/
  scenes/
    main/
    menu/
    garage/
    inventory/
    campaign/
    battle/
    results/
    components/
    machines/
    effects/
    ui/
  scripts/
    core/
    garage/
    building/
    physics/
    movement/
    weapons/
    damage/
    combat/
    ai/
    campaign/
    economy/
    save/
    settings/
    ui/
  tests/
    unit/
    integration/
    manual/
  docs/

## Data-driven components

Define components using Godot Resources or a consistent data format. Do not hardcode stats into UI scripts or individual battle scenes.

Each component definition must contain:
- Stable component ID.
- Display name.
- Description.
- Category.
- Rarity.
- Sprite references.
- Icon reference.
- Allowed socket types.
- Mass.
- Durability.
- Purchase/unlock cost.
- Upgrade levels and upgrade data.
- Physics properties.
- Gameplay behavior identifier.
- Audio and VFX references.

Use stable IDs in save data, not scene node paths or display names.

---

# 12. SAVE DATA AND OFFLINE BEHAVIOR

The demo must work entirely offline.

Persist:
- Scrap balance.
- Campaign unlocks and completed battles.
- Owned component IDs.
- Component upgrade levels.
- Three saved machine builds.
- Audio settings.
- Haptics and screen-shake settings.
- Tutorial completion.

Use a versioned save format with a schema version. Handle missing, invalid, or older save files safely. Write saves atomically where practical and keep a backup of the previous valid save.

The game must not require login, internet, ads, cloud services, or external APIs.

---

# 13. ANDROID BUILD AND PERFORMANCE

Target Android landscape.

Required:
- Touch-first controls.
- UI scaling for common phone/tablet aspect ratios.
- No mouse-only interactions.
- Offline launch.
- Persistent local saves.
- APK install and launch verification.
- No missing resource errors.
- No fatal errors in the Godot debugger.

Performance targets:
- Aim for 60 FPS on mid-range supported devices.
- Remain playable at 30 FPS on lower-end supported devices.
- Keep physics body counts controlled.
- Use simple collision shapes.
- Pool projectiles and frequently spawned effects if profiling shows allocation spikes.
- Limit simultaneous particles and audio voices.
- Avoid excessive per-frame scene-tree searches.
- Profile on an actual Android device, not only the desktop editor.

Build the APK from the included project. Document package name, version code, version name, minimum Android version, renderer, and export template version. Do not claim a tested device or performance result unless it was actually tested.

---

# 14. DEVELOPMENT ORDER AND GATES

## Gate 1: Physics proof

Build only:
- One arena floor and boundaries.
- Scrapbox chassis.
- Standard wheel pair.
- Crank-leg mechanism.
- Drill.
- Hammer.
- One enemy machine.

Prove:
- Chassis moves from wheel forces.
- Crank leg physically cycles and helps move the chassis.
- Machines collide and push each other.
- Weapons physically contact and cause damage.
- Component disabling works.
- Battle ends correctly.

Do not build the full garage until this gate passes.

## Gate 2: Construction system

Build the garage and modular attachment system. Player can equip, remove, rotate, save, and reload components. Validate builds.

## Gate 3: Complete battle loop

Add countdown, AI, health UI, battle result, rewards, and return-to-garage flow.

## Gate 4: Campaign and inventory

Add all exact demo content: 3 chassis, 4 locomotion, 4 weapons, 3 armor, 2 utility, 5 enemy archetypes, 12 battles, 2 arenas, 3 build slots, and 5 upgrade levels.

## Gate 5: Art, animation, sound and mobile polish

Replace all development visuals with the complete asset manifest. Add all required animations, VFX, and audio. Test all screens and touch interactions.

## Gate 6: Android packaging and QA

Build the APK, install it on a physical Android device, run the full acceptance checklist, fix failures, and package the final project ZIP.

---

# 15. ACCEPTANCE TESTS

The demo is complete only when all applicable tests pass.

## Launch and navigation
- App launches without internet.
- Main menu appears without missing assets.
- Every visible button works.
- Back navigation works on every screen.
- Landscape layout remains usable across tested aspect ratios.

## Garage
- Player can select all three chassis.
- Player can equip each owned component.
- Valid sockets accept compatible components.
- Invalid sockets reject incompatible components.
- Components can be removed and swapped.
- Rotatable components rotate correctly.
- Stats update immediately.
- Invalid builds cannot enter battle.
- Three build slots save and reload correctly.

## Physics
- Wheel drive moves the chassis through physics.
- Grip wheel behaves differently from standard wheel.
- Booster applies an impulse and respects cooldown.
- Crank leg visibly cycles and physically interacts with the floor.
- Different chassis masses affect acceleration and displacement.
- Collisions push, rotate, and destabilize machines.
- No machine teleports to fake movement.
- No battle can continue forever.

## Weapons and damage
- Drill deals repeated contact damage.
- Saw deals repeated contact damage.
- Hammer has a visible wind-up and physical strike.
- Rocket launches, collides, and explodes.
- Armor affects the region it physically protects.
- Component health reaches zero and disables the component.
- Chassis destruction ends the battle.

## AI and campaign
- All five AI archetypes load valid builds.
- AI uses the same physics rules as player.
- Twelve campaign battles unlock in order.
- Boss battles are clearly identified.
- Completed battles can be replayed.
- Rewards are correctly granted once per battle result according to the documented replay economy.

## Save and recovery
- Scrap persists after restart.
- Inventory persists after restart.
- Upgrades persist after restart.
- Campaign progress persists after restart.
- Saved builds persist after restart.
- Corrupted or missing save data does not crash the game.

## Android
- APK installs.
- APK launches.
- Touch input works.
- App can be backgrounded and resumed.
- No missing files or resources.
- No critical errors during a full campaign test.

---

# 16. REQUIRED DELIVERY PACKAGE

Deliver one ZIP with this structure:

SCRAP_WARS_ANDROID_DEMO/
  project/
    project.godot
    all scenes, scripts, assets, data and resources
  builds/
    SCRAP_WARS_demo.apk
  docs/
    SCRAP_WARS_GDD.md
    ASSET_MANIFEST.md
    ANIMATION_AUDIO_MANIFEST.md
    TEST_REPORT.md
    KNOWN_ISSUES.md
  README.md

The project folder must be complete and editable. The APK must be installable. The README must explain how to open the project in Godot 4.7.2, how to run it, and how to export a new APK.

The test report must list:
- Device model.
- Android version.
- Godot version.
- Build identifier.
- Tests passed.
- Tests failed.
- Known limitations.

Do not include a fabricated test report. If a test was not run, mark it “Not tested.”

---

# 17. DEVELOPER EXECUTION PROMPT

Build SCRAP WARS according to this specification. Treat this document as the source of truth.

Do not respond with only a plan. Begin implementation by proving the physics arena and machine locomotion. Deliver runnable project files at each agreed milestone.

Do not silently reduce scope. If a feature is technically unstable, explain the exact issue and propose the smallest reliable implementation that preserves the intended gameplay. Do not replace physical mechanics with decorative animation or fake stat comparisons.

Do not use placeholders in the final demo. Create and integrate every asset listed in the asset, animation, UI, and audio manifests. Use original assets or assets with documented redistribution and commercial-use rights. Include license files.

Do not add online multiplayer, accounts, ads, cloud saves, or paid services to the first demo.

Keep the project compatible with Godot 4.7.2. Use modular scenes, reusable scripts, stable component IDs, data-driven stats, versioned local saves, and documented project structure.

The final deliverable is a working Android game demo and its complete editable Godot project in one ZIP, plus a separate installable APK. The player must be able to build a machine, fight an AI opponent, receive rewards, upgrade or rebuild, and fight again.

A feature is not complete until it works in the exported Android APK, not merely in the editor.
