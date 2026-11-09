# SCRAP WARS - Asset, Animation, UI and Audio Production Checklist

This checklist is the art/audio team's production tracker. All items are required for the finished vertical-slice demo. No grey-box, stock-placeholder, empty-button, or unlicensed asset may ship.

## Export rules
- Original art only, or assets with written license permission for commercial use and redistribution.
- Transparent PNG or WebP for sprites and UI.
- Prefer sprite sheets only when frame rectangles, pivots, frame rate, and animation names are documented.
- Consistent side-view camera, light direction, outline treatment, material palette, and scale.
- Include collision shapes and pivots in the component data documentation.
- Include font and audio license files.
- Design for landscape 16:9 composition with safe adaptation to wider/taller Android screens.

## Finished machine/component sprites
- [ ] spr_chassis_scrapbox
- [ ] spr_chassis_needle
- [ ] spr_chassis_bulwark
- [ ] spr_wheel_standard
- [ ] spr_wheel_grip
- [ ] spr_booster
- [ ] spr_crank_axle
- [ ] spr_crank_rod
- [ ] spr_crank_leg
- [ ] spr_crank_foot
- [ ] spr_weapon_drill_base
- [ ] spr_weapon_drill_head
- [ ] spr_weapon_saw
- [ ] spr_weapon_hammer_base
- [ ] spr_weapon_hammer_head
- [ ] spr_weapon_rocket
- [ ] spr_rocket_projectile
- [ ] spr_armor_plow
- [ ] spr_armor_plate
- [ ] spr_armor_cage
- [ ] spr_shock_absorber
- [ ] spr_counterweight

## Chassis state art
For each of Scrapbox, Needle, and Bulwark:
- [ ] Normal appearance
- [ ] Damaged appearance or damage overlay
- [ ] Critical/destroyed appearance
- [ ] Garage thumbnail

## Backgrounds and arena art
- [ ] bg_garage
- [ ] bg_arena_foundry
- [ ] bg_arena_scrap_pit
- [ ] spr_arena_floor_foundry
- [ ] spr_arena_floor_scrap
- [ ] spr_arena_wall
- [ ] spr_garage_lamp
- [ ] spr_garage_machine_detail

## UI assets
- [ ] ui_logo_scrap_wars
- [ ] ui_button_primary (normal, pressed, disabled)
- [ ] ui_button_secondary (normal, pressed, disabled)
- [ ] ui_panel
- [ ] ui_tab (selected and unselected)
- [ ] ui_currency_scrap
- [ ] ui_icon_chassis
- [ ] ui_icon_movement
- [ ] ui_icon_weapon
- [ ] ui_icon_armor
- [ ] ui_icon_utility
- [ ] ui_icon_upgrade
- [ ] ui_icon_rotate
- [ ] ui_icon_remove
- [ ] ui_icon_save
- [ ] ui_icon_battle
- [ ] ui_icon_settings
- [ ] ui_health_bar (frame and fill)
- [ ] ui_timer_frame
- [ ] ui_rarity_common
- [ ] ui_rarity_uncommon
- [ ] ui_rarity_rare
- [ ] ui_reward_card
- [ ] ui_lock
- [ ] ui_check
- [ ] ui_warning
- [ ] ui_tutorial_pointer
- [ ] ui_victory_emblem
- [ ] ui_defeat_emblem
- [ ] ui_draw_emblem

## Effects
- [ ] fx_sparks_small
- [ ] fx_sparks_heavy
- [ ] fx_metal_hit
- [ ] fx_drill_contact
- [ ] fx_saw_contact
- [ ] fx_hammer_impact
- [ ] fx_rocket_trail
- [ ] fx_rocket_explosion
- [ ] fx_booster_exhaust
- [ ] fx_smoke_small
- [ ] fx_smoke_heavy
- [ ] fx_component_disabled
- [ ] fx_victory_celebration

## Animation implementation
- [ ] Featured machine garage idle
- [ ] Component equip snap-in
- [ ] Component remove
- [ ] Invalid placement rejection
- [ ] Wheel rotation tied to velocity
- [ ] Crank axle/rod/leg cycle tied to motor state
- [ ] Booster activation and exhaust
- [ ] Drill rotation and contact sparks
- [ ] Saw rotation and contact sparks
- [ ] Hammer wind-up/strike/recovery
- [ ] Rocket launch/trail/impact
- [ ] Chassis collision recoil
- [ ] Light damage smoke
- [ ] Critical damage smoke/flame
- [ ] Component disabled/destroyed response
- [ ] Core destruction
- [ ] Knockout/fall
- [ ] Victory celebration
- [ ] Defeat transition
- [ ] Countdown 3-2-1-FIGHT

## Audio
- [ ] sfx_ui_button
- [ ] sfx_component_equip
- [ ] sfx_component_remove
- [ ] sfx_invalid_placement
- [ ] sfx_battle_countdown
- [ ] sfx_battle_start
- [ ] sfx_wheel_loop
- [ ] sfx_crank_leg_loop
- [ ] sfx_booster_burst
- [ ] sfx_drill_loop
- [ ] sfx_saw_loop
- [ ] sfx_hammer_swing
- [ ] sfx_hammer_impact
- [ ] sfx_rocket_launch
- [ ] sfx_rocket_impact
- [ ] sfx_metal_collision_light
- [ ] sfx_metal_collision_heavy
- [ ] sfx_armor_hit
- [ ] sfx_component_break
- [ ] sfx_core_destroyed
- [ ] sfx_victory
- [ ] sfx_defeat
- [ ] sfx_reward_collect
- [ ] music_menu_garage
- [ ] music_battle
- [ ] music_results

## UI screens and controls that must be implemented
- [ ] Main menu
- [ ] Garage builder
- [ ] Component inventory
- [ ] Campaign map with 12 nodes
- [ ] Opponent preview
- [ ] Battle HUD
- [ ] Victory results
- [ ] Defeat results
- [ ] Draw results
- [ ] Settings
- [ ] Six-step tutorial
- [ ] Confirmation dialog for reset
- [ ] Scrap balance display
- [ ] Component detail and upgrade panel
- [ ] Build validation/error panel
- [ ] Three saved machine build slots
- [ ] Touch drag/drop and tap-to-equip controls
- [ ] Back navigation on every screen
