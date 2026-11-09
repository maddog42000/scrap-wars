extends Node

const SAVE_PATH := "user://scrap_wars_save.json"
const BACKUP_PATH := "user://scrap_wars_save.bak"
const SCHEMA_VERSION := 1
const CHASSIS := {
	"CH-01": {"name":"Scrapbox", "mass":7.0, "core":320.0, "load":34.0, "drive":1.0, "sockets":{"front_weapon":"weapon_front","rear_utility":"utility_rear","upper_armor":"armor","lower_armor":"armor","drive_left":"movement","drive_right":"movement"}},
	"CH-02": {"name":"Needle", "mass":5.4, "core":250.0, "load":25.0, "drive":1.22, "sockets":{"front_weapon":"weapon_front","rear_utility":"utility_rear","side_armor_left":"armor","side_armor_right":"armor","drive_left":"movement","drive_right":"movement"}},
	"CH-03": {"name":"Bulwark", "mass":10.0, "core":440.0, "load":44.0, "drive":0.78, "sockets":{"front_weapon":"weapon_front","rear_utility":"utility_rear","upper_armor":"armor","side_armor_left":"armor","side_armor_right":"armor","drive_left":"movement","drive_right":"movement"}}
}
const PARTS := {
	"MV-01":{"name":"Standard Wheel","category":"Movement","socket":"movement","mass":2.0,"hp":70,"cost":35,"rarity":"Common","drive":1.0,"traction":1.0,"damage":0,"description":"Dependable powered wheel with balanced speed and grip."},
	"MV-02":{"name":"Grip Wheel","category":"Movement","socket":"movement","mass":2.8,"hp":90,"cost":55,"rarity":"Uncommon","drive":0.78,"traction":1.55,"damage":0,"description":"Wide tread prioritizes traction over top speed."},
	"MV-03":{"name":"Booster","category":"Movement","socket":"movement","mass":2.4,"hp":55,"cost":65,"rarity":"Uncommon","drive":1.1,"traction":0.8,"damage":0,"description":"Limited forward impulse on a battle cooldown."},
	"MV-04":{"name":"Crank Leg","category":"Movement","socket":"movement","mass":3.2,"hp":100,"cost":90,"rarity":"Rare","drive":0.9,"traction":1.25,"damage":0,"description":"Eccentric crank and hinged foot push against the arena floor."},
	"WP-01":{"name":"Drill","category":"Weapons","socket":"weapon_front","mass":3.0,"hp":80,"cost":55,"rarity":"Common","drive":0,"traction":0,"damage":9,"description":"Rapid repeated damage at close contact."},
	"WP-02":{"name":"Rotary Saw","category":"Weapons","socket":"weapon_front","mass":3.6,"hp":75,"cost":70,"rarity":"Uncommon","drive":0,"traction":0,"damage":11,"description":"Serrated spinning blade deals repeated contact damage."},
	"WP-03":{"name":"Hammer","category":"Weapons","socket":"weapon_front","mass":4.2,"hp":100,"cost":85,"rarity":"Rare","drive":0,"traction":0,"damage":24,"description":"Jointed head winds up, strikes, and recovers with a heavy blow."},
	"WP-04":{"name":"Rocket Launcher","category":"Weapons","socket":"weapon_front","mass":4.8,"hp":65,"cost":105,"rarity":"Rare","drive":0,"traction":0,"damage":28,"description":"Launches a ballistic rocket with a small local blast."},
	"AR-01":{"name":"Front Plow","category":"Armor","socket":"armor","mass":3.5,"hp":125,"cost":50,"rarity":"Common","drive":0,"traction":0,"damage":0,"armor":25,"description":"Angled front plate deflects contact and absorbs local damage."},
	"AR-02":{"name":"Reinforced Plate","category":"Armor","socket":"armor","mass":4.0,"hp":150,"cost":65,"rarity":"Uncommon","drive":0,"traction":0,"damage":0,"armor":35,"description":"Thick plate with high component durability."},
	"AR-03":{"name":"Side Cage","category":"Armor","socket":"armor","mass":2.2,"hp":90,"cost":45,"rarity":"Common","drive":0,"traction":0,"damage":0,"armor":18,"description":"Light cage guards components mounted along the sides."},
	"UT-01":{"name":"Shock Absorber","category":"Utility","socket":"utility_rear","mass":2.5,"hp":80,"cost":60,"rarity":"Uncommon","drive":0,"traction":0,"damage":0,"description":"Damps chassis angular response after hard impacts."},
	"UT-02":{"name":"Counterweight","category":"Utility","socket":"utility_rear","mass":5.5,"hp":110,"cost":50,"rarity":"Common","drive":0,"traction":0,"damage":0,"description":"Adds rear mass to shift the build's center of mass and stability."}
}
const AI_ARCHETYPES := {
	"rammer":{"name":"Rammer","chassis":"CH-03","policy":"ram","parts":{"drive_left":"MV-01","drive_right":"MV-01","front_weapon":"WP-03","upper_armor":"AR-01","rear_utility":"UT-02"}},
	"skirmisher":{"name":"Skirmisher","chassis":"CH-02","policy":"rush","parts":{"drive_left":"MV-02","drive_right":"MV-03","front_weapon":"WP-02","side_armor_left":"AR-03","rear_utility":"UT-01"}},
	"crusher":{"name":"Crusher","chassis":"CH-01","policy":"pressure","parts":{"drive_left":"MV-01","drive_right":"MV-01","front_weapon":"WP-01","upper_armor":"AR-02","rear_utility":"UT-01"}},
	"spinner":{"name":"Spinner","chassis":"CH-01","policy":"stable_contact","parts":{"drive_left":"MV-02","drive_right":"MV-02","front_weapon":"WP-02","lower_armor":"AR-03","rear_utility":"UT-02"}},
	"siegebreaker":{"name":"Siegebreaker","chassis":"CH-03","policy":"ranged_pressure","parts":{"drive_left":"MV-01","drive_right":"MV-01","front_weapon":"WP-04","upper_armor":"AR-02","side_armor_left":"AR-03","rear_utility":"UT-01"}}
}
const OPPONENT_NAMES := ["Tin-Eater","Quickshift","Jawbreaker","Gatecrasher","Kiln Runner","Foundry Maw","Rivet King","Anvil Prime","Dust Devil","Scrap Saint","Iron Warden","Pit Champion"]
const BATTLE_ARCHETYPES := ["rammer","skirmisher","crusher","rammer","spinner","crusher","skirmisher","siegebreaker","spinner","crusher","siegebreaker","rammer"]
const BATTLE_ARENAS := ["foundry","foundry","foundry","foundry","foundry","foundry","foundry","foundry","scrap_pit","scrap_pit","scrap_pit","scrap_pit"]
const COMPONENT_REWARDS := {1:["MV-02","MV-03","WP-02"],2:["AR-01","AR-02","UT-01"],3:["WP-03","UT-02","AR-03"],4:["WP-04","MV-04"]}
var scrap := 240
var owned: Array[String] = []
var upgrades: Dictionary = {}
var builds: Array[Dictionary] = []
var selected_slot := 0
var completed_battles := 0
var rewarded_battles: Array[int] = []
var last_equipment_rewards: Array[String] = []
var music_volume := 0.7
var sfx_volume := 0.8
var haptics := false
var reduced_shake := false
var tutorial_done := false
var current_opponent := 1
var current_arena_id := "foundry"
var return_screen := ""
var battle_control_test_stage := 0
var notice := ""

func _ready() -> void:
	_load()
	if owned.is_empty():
		owned = ["MV-01", "WP-01"]
	if builds.size() != 3:
		builds = [_starter_build("CH-01"), _starter_build("CH-02"), _starter_build("CH-03")]
	_save()

func _starter_build(chassis_id: String) -> Dictionary:
	return {"chassis":chassis_id,"parts":{"drive_left":{"id":"MV-01","rotation":0},"drive_right":{"id":"MV-01","rotation":0},"front_weapon":{"id":"WP-01","rotation":0}},"name":CHASSIS[chassis_id].name + " Build"}

func selected_build() -> Dictionary:
	return builds[selected_slot]

func valid_socket(chassis_id: String, component_id: String, socket_id: String) -> bool:
	if not CHASSIS.has(chassis_id) or not PARTS.has(component_id): return false
	var sockets: Dictionary = CHASSIS[chassis_id].sockets
	return sockets.has(socket_id) and sockets[socket_id] == PARTS[component_id].socket

func install_part(slot_index: int, component_id: String, socket_id: String) -> bool:
	if slot_index < 0 or slot_index >= 3 or not owned.has(component_id):
		notice = "Part is not owned or the build slot is invalid."
		return false
	var build: Dictionary = builds[slot_index]
	if not valid_socket(str(build.chassis), component_id, socket_id):
		notice = "That part is incompatible with this attachment point."
		return false
	var candidate: Dictionary = build.duplicate(true)
	var existing: Dictionary = candidate.parts.get(socket_id, {})
	var retained_rotation := int(existing.get("rotation", 0)) if str(existing.get("id", "")) == component_id else 0
	candidate.parts[socket_id] = {"id":component_id,"rotation":retained_rotation}
	if build_mass(candidate) > float(CHASSIS[candidate.chassis].load):
		notice = "Load limit exceeded: remove a heavy part or choose another chassis."
		return false
	builds[slot_index] = candidate
	notice = PARTS[component_id].name + " equipped at " + socket_id.replace("_", " ") + "."
	_save()
	return true

func remove_part(slot_index: int, socket_id: String) -> void:
	if slot_index < 0 or slot_index >= 3: return
	builds[slot_index].parts.erase(socket_id)
	notice = "Component removed."
	_save()

func rotate_part(slot_index: int, socket_id: String) -> void:
	if slot_index < 0 or slot_index >= 3 or not builds[slot_index].parts.has(socket_id): return
	var part: Dictionary = builds[slot_index].parts[socket_id]
	part.rotation = wrapi(int(part.rotation) + 90, 0, 360)
	_save()

func select_chassis(slot_index: int, chassis_id: String) -> void:
	if slot_index < 0 or slot_index >= 3 or not CHASSIS.has(chassis_id): return
	var build: Dictionary = builds[slot_index]
	var compatible: Dictionary = {}
	for socket_id in build.parts:
		var part: Dictionary = build.parts[socket_id]
		if valid_socket(chassis_id, str(part.id), str(socket_id)): compatible[socket_id] = part
	build.chassis = chassis_id
	build.parts = compatible
	notice = CHASSIS[chassis_id].name + " selected; incompatible mounted parts were safely returned to inventory."
	_save()

func build_mass(build: Dictionary) -> float:
	var total := float(CHASSIS.get(str(build.chassis), CHASSIS["CH-01"]).mass)
	for item in build.parts.values(): total += float(PARTS.get(str(item.id), {}).get("mass", 0.0)) * upgrade_multiplier(str(item.id), "mass")
	return total

func upgrade_multiplier(component_id: String, stat_name: String) -> float:
	# Upgrades slightly increase durability/damage, not physical mass; mass stays faithful to the part.
	if stat_name == "mass": return 1.0
	return 1.0 + 0.08 * float(upgrade_level(component_id) - 1)

func build_stats(build: Dictionary) -> Dictionary:
	var chassis: Dictionary = CHASSIS[build.chassis]
	var drive := 0.0
	var traction := 0.0
	var damage := 0.0
	var armor := 0.0
	var drive_count := 0
	for item in build.parts.values():
		var id := str(item.id)
		var p: Dictionary = PARTS.get(id, {})
		var level_factor := 1.0 + 0.08 * float(component_level(item, id) - 1)
		if p.category == "Movement":
			drive += float(p.drive) * level_factor
			traction += float(p.traction) * level_factor
			drive_count += 1
		elif p.category == "Weapons": damage += float(p.damage) * level_factor
		elif p.category == "Armor": armor += float(p.armor) * level_factor
	var mass := build_mass(build)
	var movement_rating := drive * float(chassis.drive) * 100.0 / maxf(mass / 10.0, 1.0)
	return {"mass":mass,"core":float(chassis.core),"drive":movement_rating,"traction":traction * 50.0,"damage":damage,"armor":armor,"stability":clampf(100.0 - absf(mass - 18.0) * 2.2, 0, 100),"drive_count":drive_count}

func validate_build(build: Dictionary, available_override: Array[String] = []) -> Array[String]:
	var errors: Array[String] = []
	var movement := 0
	var weapon := 0
	var available := owned if available_override.is_empty() else available_override
	if not CHASSIS.has(str(build.get("chassis", ""))): errors.append("Select a chassis.")
	for socket_id in build.get("parts", {}):
		var item: Dictionary = build.parts[socket_id]
		var id := str(item.get("id", ""))
		if not available.has(id): errors.append("Part " + id + " is not owned or available."); continue
		if not valid_socket(str(build.chassis), id, str(socket_id)): errors.append(id + " is in an incompatible socket."); continue
		if PARTS[id].category == "Movement": movement += 1
		if PARTS[id].category == "Weapons": weapon += 1
	if movement == 0: errors.append("Install at least one movement component.")
	if weapon == 0: errors.append("Install at least one weapon.")
	if CHASSIS.has(str(build.get("chassis", ""))) and build_mass(build) > float(CHASSIS[build.chassis].load): errors.append("Chassis load limit exceeded.")
	return errors

func buy_upgrade(component_id: String) -> bool:
	if not PARTS.has(component_id) or not owned.has(component_id): return false
	var level := int(upgrades.get(component_id, 1))
	if level >= 5: notice = "This component is already level 5."; return false
	var cost := int(PARTS[component_id].cost * (0.8 + level * 0.65))
	if scrap < cost: notice = "Not enough scrap for this upgrade."; return false
	scrap -= cost
	upgrades[component_id] = level + 1
	notice = PARTS[component_id].name + " upgraded to level " + str(level + 1) + "."
	_save()
	return true

func upgrade_level(component_id: String) -> int:
	return int(upgrades.get(component_id, 1))

func upgrade_cost(component_id: String) -> int:
	return int(float(PARTS.get(component_id, {}).get("cost", 0)) * (0.8 + upgrade_level(component_id) * 0.65))

func grant_battle_reward(won: bool, is_draw := false) -> int:
	var first_clear := not rewarded_battles.has(current_opponent)
	var reward := (35 + current_opponent * 8) if won and first_clear else (15 if is_draw else (10 if not won else 0))
	last_equipment_rewards.clear()
	scrap += reward
	if won:
		completed_battles = maxi(completed_battles, current_opponent)
		if first_clear:
			rewarded_battles.append(current_opponent)
			for component_id in COMPONENT_REWARDS.get(current_opponent, []):
				if not owned.has(component_id):
					owned.append(component_id)
					last_equipment_rewards.append(component_id)
	notice = "+" + str(reward) + " scrap"
	_save()
	return reward

func battle_definition(battle_number: int) -> Dictionary:
	var n := clampi(battle_number, 1, 12)
	var archetype_id: String = BATTLE_ARCHETYPES[n-1]
	var archetype: Dictionary = AI_ARCHETYPES[archetype_id]
	var level := 5 if n == 12 else clampi(1 + int((n-1) / 3), 1, 5)
	var build := {"chassis":archetype.chassis,"name":str(archetype.name)+" / " + str(n),"archetype":archetype_id,"policy":archetype.policy,"parts":{},"upgrades":{}}
	var available := _campaign_owned_before(n)
	var target_parts: Dictionary = archetype.parts.duplicate(true)
	if archetype_id == "rammer" and n >= 9 and available.has("MV-04"):
		target_parts["drive_left"] = "MV-04"
	for socket_id in target_parts:
		var component_id: String = target_parts[socket_id]
		if not available.has(component_id):
			var category: String = PARTS[component_id].category
			if category == "Movement": component_id = "MV-01"
			elif category == "Weapons": component_id = "WP-01"
			else: continue
		build.parts[socket_id] = {"id":component_id,"rotation":0,"level":level}
		build.upgrades[component_id] = level
	var chapter := int((n-1)/4)
	return {"number":n,"name":OPPONENT_NAMES[n-1],"archetype":archetype_id,"archetype_name":archetype.name,"description":_ai_description(archetype_id),"arena":BATTLE_ARENAS[n-1],"chapter":chapter+1,"boss":n%4==0,"reward":35+n*8,"equipment_reward":COMPONENT_REWARDS.get(n,[]),"difficulty":level,"build":build}

func _campaign_owned_before(battle_number: int) -> Array[String]:
	var available: Array[String] = ["MV-01", "WP-01"]
	for n in range(1, battle_number):
		for component_id in COMPONENT_REWARDS.get(n, []):
			if not available.has(component_id): available.append(component_id)
	return available

func reward_battle_for(component_id: String) -> int:
	for n in COMPONENT_REWARDS:
		if COMPONENT_REWARDS[n].has(component_id): return int(n)
	return 0

func _ai_description(archetype_id: String) -> String:
	match archetype_id:
		"rammer": return "Bulwark front-liner; drives hard into contact and swings a heavy hammer."
		"skirmisher": return "Needle rush build with high-grip wheels and a cooldown booster."
		"crusher": return "Armored close-range pressure machine built around a contact drill."
		"spinner": return "Grip-wheel saw fighter with a rear counterweight for steadier contact."
		_: return "Armored siege platform; launches physical rockets, then advances."

func component_level(item: Dictionary, component_id: String) -> int:
	if item.has("level"): return clampi(int(item.level), 1, 5)
	return clampi(int(upgrades.get(component_id, 1)), 1, 5)

func _save() -> void:
	var data := {"schema":SCHEMA_VERSION,"scrap":scrap,"owned":owned,"upgrades":upgrades,"builds":builds,"selected_slot":selected_slot,"completed_battles":completed_battles,"rewarded_battles":rewarded_battles,"music_volume":music_volume,"sfx_volume":sfx_volume,"haptics":haptics,"reduced_shake":reduced_shake,"tutorial_done":tutorial_done}
	if FileAccess.file_exists(SAVE_PATH):
		var old := FileAccess.get_file_as_string(SAVE_PATH)
		if not old.is_empty():
			var backup := FileAccess.open(BACKUP_PATH, FileAccess.WRITE)
			if backup: backup.store_string(old); backup.close()
	var f := FileAccess.open(SAVE_PATH + ".tmp", FileAccess.WRITE)
	if f == null: return
	f.store_string(JSON.stringify(data, "\t"))
	f.close()
	DirAccess.rename_absolute(ProjectSettings.globalize_path(SAVE_PATH + ".tmp"), ProjectSettings.globalize_path(SAVE_PATH))

func _load() -> void:
	var parsed: Variant = null
	for path in [SAVE_PATH, BACKUP_PATH]:
		if not FileAccess.file_exists(path): continue
		var candidate: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
		if typeof(candidate) == TYPE_DICTIONARY and int(candidate.get("schema", 0)) <= SCHEMA_VERSION:
			parsed = candidate
			break
	if typeof(parsed) != TYPE_DICTIONARY: return
	scrap = maxi(0, int(parsed.get("scrap", scrap)))
	owned.clear()
	for id in parsed.get("owned", []):
		if PARTS.has(str(id)): owned.append(str(id))
	upgrades = parsed.get("upgrades", {})
	builds.clear()
	for raw_build in parsed.get("builds", []):
		if typeof(raw_build) != TYPE_DICTIONARY or not CHASSIS.has(str(raw_build.get("chassis", ""))): continue
		var clean := {"chassis":str(raw_build.chassis),"parts":{},"name":str(raw_build.get("name", "Build"))}
		for socket_id in raw_build.get("parts", {}):
			var item: Dictionary = raw_build.parts[socket_id]
			if owned.has(str(item.get("id", ""))) and valid_socket(clean.chassis, str(item.id), str(socket_id)):
				clean.parts[socket_id] = {"id":str(item.id),"rotation":int(item.get("rotation", 0))}
		builds.append(clean)
	selected_slot = clampi(int(parsed.get("selected_slot", 0)), 0, 2)
	completed_battles = clampi(int(parsed.get("completed_battles", 0)), 0, 12)
	rewarded_battles.clear()
	for n in parsed.get("rewarded_battles", []):
		if int(n) >= 1 and int(n) <= 12: rewarded_battles.append(int(n))
	music_volume = clampf(float(parsed.get("music_volume", 0.7)), 0.0, 1.0)
	sfx_volume = clampf(float(parsed.get("sfx_volume", 0.8)), 0.0, 1.0)
	haptics = bool(parsed.get("haptics", false))
	reduced_shake = bool(parsed.get("reduced_shake", false))
	tutorial_done = bool(parsed.get("tutorial_done", false))
