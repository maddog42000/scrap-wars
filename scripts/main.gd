extends Node2D

const FONT := preload("res://assets/fonts/DejaVuSans.ttf")
const BUILD_PREVIEW := preload("res://scripts/garage_preview.gd")
const UI_DESIGN_SIZE := Vector2(1280.0, 720.0)
var layer: CanvasLayer
var page: Control
var current_screen := "menu"
var inventory_tab := "Movement"
var garage_tab := "Movement"
var selected_component := ""
var selected_socket := ""
var selected_inventory_item := "MV-01"
var selected_battle := 1
var tutorial_step := 0
var notice_label: Label
var details_label: Label
var test_mode := false
var ui_smoke_test := false
var battle_smoke_test := false
var asset_pipeline_test := false

func _ready() -> void:
	ArtAssets.mount_animation_visual(self, "ui/backgrounds/main-menu", UI_DESIGN_SIZE, UI_DESIGN_SIZE * 0.5)
	test_mode = OS.get_cmdline_user_args().has("--physics-test")
	battle_smoke_test = OS.get_cmdline_user_args().has("--battle-smoke-test")
	ui_smoke_test = OS.get_cmdline_user_args().has("--ui-smoke-test")
	asset_pipeline_test = OS.get_cmdline_user_args().has("--asset-pipeline-test")
	var campaign_test := false
	for arg in OS.get_cmdline_user_args():
		if str(arg).begins_with("--campaign-battle="):
			var values := str(arg).split("=", false, 1)
			GameState.current_opponent=clampi(int(values[1]),1,12)
			GameState.current_arena_id=str(GameState.battle_definition(GameState.current_opponent).arena)
			campaign_test=true
		elif str(arg)=="--rotation-test":
			GameState.current_opponent=8
			GameState.current_arena_id=str(GameState.battle_definition(8).arena)
			campaign_test=true
		elif str(arg) in ["--battle-controls-test", "--auto-combat-test"]:
			GameState.current_opponent=1
			GameState.current_arena_id=str(GameState.battle_definition(1).arena)
			campaign_test=true
	if test_mode or battle_smoke_test or campaign_test:
		get_tree().call_deferred("change_scene_to_file", "res://scenes/battle.tscn")
		return
	layer = CanvasLayer.new()
	add_child(layer)
	page = Control.new()
	page.name = "MobileSafeDesignCanvas"
	page.size = UI_DESIGN_SIZE
	layer.add_child(page)
	get_viewport().size_changed.connect(_apply_mobile_ui_scale)
	_apply_mobile_ui_scale()
	var return_screen := GameState.return_screen if GameState.return_screen != "" else "menu"
	GameState.return_screen = ""
	show_screen(return_screen)
	if ui_smoke_test: _run_ui_smoke_test()
	if asset_pipeline_test: call_deferred("_run_asset_pipeline_test")

func _run_asset_pipeline_test() -> void:
	var required_keys := [
		"machines/chassis/ch-01", "machines/chassis/ch-02", "machines/chassis/ch-03",
		"components/locomotion/mv-01", "components/locomotion/mv-02", "components/locomotion/mv-03", "components/locomotion/mv-04",
		"components/weapons/wp-01", "components/weapons/wp-02", "components/weapons/wp-03", "components/weapons/wp-04",
		"components/armor/ar-01", "components/armor/ar-02", "components/armor/ar-03",
		"components/utility/ut-01", "components/utility/ut-02", "arenas/foundry-floor", "arenas/scrap-pit",
		"ui/backgrounds/main-menu", "ui/illustrations/featured-machine"
	]
	var keys_mapped := true
	for key in required_keys:
		if not ArtAssets.TEXTURE_PATHS.has(key):
			keys_mapped = false
	var missing_texture_uses_fallback := ArtAssets.texture_for("test/asset-that-does-not-exist") == null
	var probe := Node2D.new()
	add_child(probe)
	var missing_animation_uses_fallback := not ArtAssets.mount_animation_visual(probe, "test/asset-that-does-not-exist", Vector2(16, 16))
	var sample_key := "machines/chassis/ch-01"
	var sample_path := str(ArtAssets.TEXTURE_PATHS[sample_key])
	var sample_file_present := FileAccess.file_exists(sample_path)
	var sample_texture_loaded := ArtAssets.texture_for(sample_key) != null
	var sample_path_ok := sample_texture_loaded if sample_file_present else not sample_texture_loaded
	var sample_animation_path := ArtAssets.animation_path(sample_key)
	var sample_animation_present := FileAccess.file_exists(sample_animation_path)
	var sample_frames_loaded := ArtAssets.animation_for(sample_key) != null
	var animation_probe := Node2D.new()
	add_child(animation_probe)
	var sample_animation_mounted := ArtAssets.mount_animation_visual(animation_probe, sample_key, Vector2(144, 56))
	var sample_animation_ok := sample_animation_mounted == sample_animation_present and sample_frames_loaded == sample_animation_present
	var passed := keys_mapped and missing_texture_uses_fallback and missing_animation_uses_fallback and sample_path_ok and sample_animation_ok
	print("ART_ASSET_PIPELINE_TEST keys_mapped=", keys_mapped, " missing_png_fallback=", missing_texture_uses_fallback, " missing_animation_fallback=", missing_animation_uses_fallback, " sample_file_present=", sample_file_present, " sample_texture_loaded=", sample_texture_loaded, " sample_animation_present=", sample_animation_present, " sample_frames_loaded=", sample_frames_loaded, " sample_animation_mounted=", sample_animation_mounted, " result=", passed)
	probe.queue_free()
	animation_probe.queue_free()
	get_tree().quit(0 if passed else 1)

func _run_ui_smoke_test() -> void:
	await get_tree().create_timer(0.25).timeout
	for screen in ["garage","inventory","campaign","preview","settings","tutorial","garage"]:
		show_screen(screen)
		await get_tree().create_timer(0.15).timeout
		print("UI_SCREEN_OK ", screen)
	var build: Dictionary=GameState.selected_build()
	print("GARAGE_BUILD_VALID ", GameState.validate_build(build).is_empty(), " socket_count=", GameState.CHASSIS[build.chassis].sockets.size(), " stats=", GameState.build_stats(build))
	var before: Dictionary=build.duplicate(true)
	var original_owned: Array[String]=GameState.owned.duplicate()
	if not GameState.owned.has("WP-02"): GameState.owned.append("WP-02")
	var invalid_rejected := not GameState.install_part(GameState.selected_slot,"WP-03","drive_left")
	var valid_equipped := GameState.install_part(GameState.selected_slot,"WP-02","front_weapon")
	GameState.rotate_part(GameState.selected_slot,"front_weapon")
	GameState._save()
	GameState._load()
	var rotation_saved := int(GameState.selected_build().parts.front_weapon.rotation)==90
	GameState.builds[GameState.selected_slot]=before
	GameState.owned=original_owned
	GameState._save()
	print("BUILDER_TEST incompatible_rejected=",invalid_rejected," compatible_install=",valid_equipped," rotation_saved=",rotation_saved," restored_valid=",GameState.validate_build(GameState.selected_build()).is_empty())
	var archetypes: Dictionary={}
	var arena_ids: Dictionary={}
	var campaign_valid:=true
	for n in range(1,13):
		var battle: Dictionary=GameState.battle_definition(n)
		archetypes[str(battle.archetype)]=true
		arena_ids[str(battle.arena)]=true
		if not GameState.validate_build(battle.build,GameState._campaign_owned_before(n)).is_empty():
			campaign_valid=false
			print("CAMPAIGN_BUILD_INVALID ",n," ",GameState.validate_build(battle.build,GameState._campaign_owned_before(n)))
	print("CAMPAIGN_DATA_CHECK battles=12 valid_builds=",campaign_valid," archetypes=",archetypes.size()," arenas=",arena_ids.size()," boss_nodes=",3)
	var saved_owned: Array[String]=GameState.owned.duplicate()
	var saved_clear:=GameState.completed_battles
	var saved_claims: Array[int]=GameState.rewarded_battles.duplicate()
	var saved_scrap:=GameState.scrap
	var saved_opponent:=GameState.current_opponent
	var saved_inventory_tab:=inventory_tab
	var saved_inventory_item:=selected_inventory_item
	GameState.owned=["MV-01","WP-01"]
	GameState.completed_battles=0
	GameState.rewarded_battles.clear()
	GameState.current_opponent=1
	inventory_tab="Weapons"
	selected_inventory_item="WP-02"
	await show_screen("inventory")
	var lock_card_found:=false
	var lock_hint_found:=false
	for child in page.get_children():
		if child is Button and str(child.text).begins_with("LOCKED · WP-02"): lock_card_found=true
		if child is Label and "LOCKED · BATTLE 01" in str(child.text): lock_hint_found=true
	var reward_scrap:=GameState.grant_battle_reward(true)
	var bundle_ids: Array[String]=GameState.last_equipment_rewards.duplicate()
	var repeat_reward:=GameState.grant_battle_reward(true)
	GameState.current_opponent=2
	var defeat_reward:=GameState.grant_battle_reward(false)
	var draw_reward:=GameState.grant_battle_reward(false,true)
	var reward_ok:=reward_scrap==43 and GameState.owned.has("MV-02") and GameState.owned.has("MV-03") and GameState.owned.has("WP-02") and GameState.completed_battles==1
	print("LOCKED_INVENTORY_TEST card=",lock_card_found," unlock_hint=",lock_hint_found)
	print("REWARD_TEST first_clear=",reward_ok," scrap=",reward_scrap," components=",bundle_ids," repeat_win=",repeat_reward," defeat=",defeat_reward," draw=",draw_reward)
	GameState.owned=saved_owned
	GameState.completed_battles=saved_clear
	GameState.rewarded_battles=saved_claims
	GameState.scrap=saved_scrap
	GameState.current_opponent=saved_opponent
	GameState.last_equipment_rewards.clear()
	inventory_tab=saved_inventory_tab
	selected_inventory_item=saved_inventory_item
	GameState._save()
	await show_screen("garage")

func _draw() -> void:
	var view_size := get_viewport_rect().size
	if bool(get_meta("external_animation_enabled", false)):
		return
	if ArtAssets.draw_texture(self, "ui/backgrounds/main-menu", Rect2(Vector2.ZERO, view_size)):
		return
	draw_rect(Rect2(Vector2.ZERO, view_size), Color("172328"), true)
	for i in range(ceili(view_size.x / 105.0) + 1):
		var x := float(i)*105.0
		draw_rect(Rect2(Vector2(x, 65), Vector2(42, 485)), Color("1d2b30"), true)
		draw_line(Vector2(x+9,75),Vector2(x+9,535),Color(0.5,0.58,0.54,0.12),3)
	for x in range(125, ceili(view_size.x) + 310, 310):
		draw_line(Vector2(x,0),Vector2(x,80),Color("536166"),5)
		draw_rect(Rect2(Vector2(x-24,75),Vector2(48,12)),Color("d1a254"),true)
	var floor_y := view_size.y - 155.0
	draw_rect(Rect2(Vector2(0,floor_y),Vector2(view_size.x,155)),Color("10191d"),true)
	draw_line(Vector2(0,floor_y),Vector2(view_size.x,floor_y),Color("a97d42"),3)

func _apply_mobile_ui_scale() -> void:
	if not is_instance_valid(page):
		return
	var available := get_viewport().get_visible_rect().size
	if available.x <= 0.0 or available.y <= 0.0:
		return
	var fit_scale := minf(available.x / UI_DESIGN_SIZE.x, available.y / UI_DESIGN_SIZE.y)
	fit_scale = clampf(fit_scale, 0.65, 1.0)
	page.scale = Vector2.ONE * fit_scale
	page.position = (available - UI_DESIGN_SIZE * fit_scale) * 0.5

func show_screen(screen: String) -> void:
	current_screen = screen
	for child in page.get_children(): child.queue_free()
	await get_tree().process_frame
	match screen:
		"menu": _menu_screen()
		"garage": _garage_screen()
		"inventory": _inventory_screen()
		"campaign": _campaign_screen()
		"preview": _opponent_screen()
		"settings": _settings_screen()
		"tutorial": _tutorial_screen()
	queue_redraw()

func _label(parent: Control, text: String, pos: Vector2, size: Vector2, fs := 18, color := Color("d9e0d9"), align := HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var l := Label.new()
	l.text = text
	l.position = pos
	l.size = size
	l.add_theme_font_override("font", FONT)
	l.add_theme_font_size_override("font_size", fs)
	l.add_theme_color_override("font_color", color)
	l.horizontal_alignment = align
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	parent.add_child(l)
	return l

func _panel(parent: Control, pos: Vector2, size: Vector2, fill := Color(0.075,0.105,0.115,0.96)) -> Panel:
	var p := Panel.new()
	p.position = pos
	p.size = size
	var sb := StyleBoxFlat.new()
	sb.bg_color = fill
	sb.border_color = Color("85683f")
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(9)
	p.add_theme_stylebox_override("panel", sb)
	parent.add_child(p)
	return p

func _button(parent: Control, text: String, pos: Vector2, size: Vector2, callback: Callable, active := false, fs := 15) -> Button:
	var b := Button.new()
	b.text = text
	b.position = pos
	var touch_size := Vector2(maxf(size.x, 64.0), maxf(size.y, 48.0))
	b.size = touch_size
	b.custom_minimum_size = touch_size
	b.add_theme_font_override("font", FONT)
	b.add_theme_font_size_override("font_size", maxi(fs, 12))
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color("5a4830") if active else Color("33444a")
	normal.border_color = Color("e1ba6d") if active else Color("687a79")
	normal.set_border_width_all(1)
	normal.set_corner_radius_all(6)
	b.add_theme_stylebox_override("normal", normal)
	var hover := StyleBoxFlat.new()
	hover.bg_color = Color("77603b")
	hover.set_border_width_all(2)
	hover.border_color = Color("f0d08c")
	hover.set_corner_radius_all(6)
	b.add_theme_stylebox_override("hover", hover)
	b.add_theme_stylebox_override("pressed", hover)
	ArtAssets.apply_button_textures(b, ArtAssets.button_key_from_text(text))
	b.pressed.connect(callback)
	parent.add_child(b)
	return b

func _header(title: String, back_to := "menu") -> void:
	var head := _panel(page, Vector2(22,16),Vector2(1236,94),Color(0.06,0.085,0.095,0.97))
	_label(head,"SCRAP WARS",Vector2(22,11),Vector2(235,38),27,Color("efc26e"))
	_label(head,title.to_upper(),Vector2(258,18),Vector2(650,33),20,Color("e1e5d9"))
	_label(head,"SCRAP  " + str(GameState.scrap),Vector2(973,18),Vector2(205,34),19,Color("f0c66e"),HORIZONTAL_ALIGNMENT_RIGHT)
	_button(head,"BACK",Vector2(1070,58),Vector2(132,27),func(): show_screen(back_to),false,12)

func _menu_screen() -> void:
	_header("Yard Hangar")
	_panel(page,Vector2(190,145),Vector2(900,370),Color(0.06,0.09,0.10,0.93))
	_label(page,"BUILD IT. BREAK THE ARENA.",Vector2(274,173),Vector2(730,58),32,Color("efc26e"),HORIZONTAL_ALIGNMENT_CENTER)
	_label(page,"Offline machine combat  •  Local profile  •  Workshop test build",Vector2(310,232),Vector2(650,30),16,Color("aab9b5"),HORIZONTAL_ALIGNMENT_CENTER)
	_draw_featured_machine()
	_button(page,"PLAY CAMPAIGN",Vector2(315,438),Vector2(250,55),func(): show_screen("campaign"),true,19)
	_button(page,"ENTER GARAGE",Vector2(585,438),Vector2(250,55),func(): show_screen("garage"),false,19)
	_button(page,"PARTS",Vector2(315,505),Vector2(165,42),func(): show_screen("inventory"))
	_button(page,"SETTINGS",Vector2(495,505),Vector2(165,42),func(): show_screen("settings"))
	_button(page,"TUTORIAL",Vector2(675,505),Vector2(165,42),func(): tutorial_step=0; show_screen("tutorial"))
	_label(page,"CAMPAIGN  %d / 12 COMPLETE" % GameState.completed_battles,Vector2(850,514),Vector2(230,28),13,Color("a4b1a9"),HORIZONTAL_ALIGNMENT_RIGHT)

func _draw_featured_machine() -> void:
	var p := _panel(page,Vector2(480,295),Vector2(320,116),Color(0.08,0.12,0.13,0.82))
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var d := Control.new()
	d.position=Vector2(0,0); d.size=Vector2(320,116)
	d.draw.connect(func():
		if not ArtAssets.draw_texture(d, "ui/illustrations/featured-machine", Rect2(Vector2.ZERO, d.size)):
			d.draw_rect(Rect2(Vector2(74,30),Vector2(172,44)),Color("637174"),true)
			d.draw_rect(Rect2(Vector2(74,30),Vector2(172,44)),Color("1b282b"),false,4)
			for pt in [Vector2(104,80),Vector2(211,80)]: d.draw_circle(pt,18,Color("283539")); d.draw_arc(pt,18,0,TAU,24,Color("d3a34f"),3)
			d.draw_circle(Vector2(252,43),13,Color("d4a956"))
	)
	p.add_child(d)

func _garage_screen() -> void:
	_header("Garage · Build & Test")
	var slotbar := _panel(page,Vector2(24,121),Vector2(1232,58))
	for i in 3:
		_button(slotbar,"BUILD SLOT %d%s" % [i+1,"  •  ACTIVE" if i==GameState.selected_slot else ""],Vector2(14+i*205,5),Vector2(191,48),func(): _select_slot(i),i==GameState.selected_slot,13)
	var chassisbar := _panel(page,Vector2(24,185),Vector2(1232,58))
	_label(chassisbar,"CHASSIS",Vector2(12,9),Vector2(105,33),14,Color("e2bd73"))
	var cidx := 0
	for chassis_id in GameState.CHASSIS.keys():
		var cid: String = chassis_id
		_button(chassisbar,GameState.CHASSIS[cid].name,Vector2(112+cidx*166,5),Vector2(153,48),func(): GameState.select_chassis(GameState.selected_slot,cid); _garage_screen(),GameState.selected_build().chassis==cid,14)
		cidx += 1
	_panel(page,Vector2(24,250),Vector2(306,287))
	_label(page,"PART BIN · TAP TO PICK",Vector2(43,257),Vector2(275,31),16,Color("efc26e"))
	var cats := ["Movement","Weapons","Armor","Utility"]
	for i in cats.size():
		var cat: String = cats[i]
		_button(page,cat.substr(0,3).to_upper(),Vector2(37+i*69,291),Vector2(65,30),func(): garage_tab=cat; selected_component=""; _garage_screen(),garage_tab==cat,11)
	var rows: Array[String] = []
	for id in GameState.PARTS.keys():
		if GameState.PARTS[id].category == garage_tab: rows.append(id)
	var row_y := 343.0
	for id in rows:
		var part_id: String = id
		var is_owned := GameState.owned.has(part_id)
		var equipped_text := "  · INSTALLED" if _equipped_socket(part_id) != "" else ""
		var card := _button(page,"%s%s  %s%s" % ["LOCKED · " if not is_owned else "",part_id,GameState.PARTS[part_id].name,equipped_text],Vector2(37,row_y),Vector2(276,39),func(): selected_component=part_id; _refresh_garage_details(),selected_component==part_id,10)
		card.disabled = not is_owned
		row_y += 48
	if rows.is_empty(): _label(page,"No owned parts in this category.",Vector2(43,345),Vector2(265,55),13,Color("a8b4b1"))
	_panel(page,Vector2(345,250),Vector2(548,287),Color(0.06,0.085,0.09,0.97))
	_label(page,"MACHINE WORKBENCH  ·  TAP SOCKET TO INSTALL",Vector2(366,255),Vector2(515,29),14,Color("efc26e"))
	var preview := BUILD_PREVIEW.new()
	preview.position=Vector2(357,270); preview.size=Vector2(525,255); preview.mouse_filter=Control.MOUSE_FILTER_IGNORE
	page.add_child(preview)
	for entry in _socket_points(GameState.selected_build().chassis):
		var socket_id: String = entry[0]
		var point: Vector2 = entry[1]
		var installed: Dictionary = GameState.selected_build().parts.get(socket_id,{})
		var caption := socket_id.replace("_"," ").to_upper()
		if installed.has("id"): caption += "\n%s · %d°" % [str(installed.id),int(installed.get("rotation",0))]
		var absolute := preview.position + point - Vector2(34,17)
		_button(page,caption,absolute,Vector2(69,37),func(): _tap_socket(socket_id),selected_socket==socket_id,9)
	_panel(page,Vector2(913,250),Vector2(343,287))
	_label(page,"LIVE BUILD READOUT",Vector2(935,258),Vector2(290,28),16,Color("efc26e"))
	_render_stats(page,Vector2(936,291),GameState.selected_build())
	_label(page,"SELECTED PART",Vector2(935,405),Vector2(280,26),13,Color("c4b17f"))
	var detail := "Tap a part, then tap a compatible socket."
	if selected_component!="":
		var pdef: Dictionary=GameState.PARTS[selected_component]
		detail="%s · %s\n%s\nMASS %.1f   HP %d   COST %d   %s" % [selected_component,pdef.name,pdef.description,pdef.mass,pdef.hp,pdef.cost,pdef.rarity]
		if not GameState.owned.has(selected_component): detail="%s · %s · LOCKED\n%s\nUNLOCK: VICTORY IN BATTLE %02d" % [selected_component,pdef.name,pdef.description,GameState.reward_battle_for(selected_component)]
	_label(page,detail,Vector2(935,430),Vector2(298,89),12,Color("c7d1c8"))
	var buttons := _panel(page,Vector2(24,549),Vector2(1232,145),Color(0.055,0.078,0.084,0.98))
	var errors: Array[String]=GameState.validate_build(GameState.selected_build())
	var status := "BUILD VALID · READY FOR BATTLE" if errors.is_empty() else "BUILD INVALID · " + errors[0]
	_label(buttons,status,Vector2(18,8),Vector2(860,26),14,Color("91d6a2") if errors.is_empty() else Color("ef917b"))
	_label(buttons,GameState.notice,Vector2(18,35),Vector2(670,23),12,Color("c3b78d"))
	_button(buttons,"ROTATE",Vector2(18,76),Vector2(100,44),func(): _rotate_selected(),false,13)
	_button(buttons,"REMOVE",Vector2(128,76),Vector2(100,44),func(): _remove_selected(),false,13)
	_button(buttons,"SAVE SLOT",Vector2(238,76),Vector2(120,44),func(): GameState._save(); GameState.notice="Build saved locally."; _garage_screen(),false,13)
	_button(buttons,"TUTORIAL",Vector2(368,76),Vector2(112,44),func(): tutorial_step=0; show_screen("tutorial"),false,12)
	_button(buttons,"CAMPAIGN",Vector2(490,76),Vector2(120,44),func(): show_screen("campaign"),false,12)
	_button(buttons,"TEST BUILD",Vector2(624,76),Vector2(135,44),func(): _start_battle(true),errors.is_empty(),13)
	_button(buttons,"BATTLE SELECT",Vector2(773,76),Vector2(180,44),func(): show_screen("campaign"),false,13)
	_button(buttons,"PARTS & UPGRADES",Vector2(966,76),Vector2(220,44),func(): show_screen("inventory"),false,12)

func _socket_points(chassis_id: String) -> Array:
	var out := [["front_weapon",Vector2(458,133)],["rear_utility",Vector2(122,190)],["drive_left",Vector2(192,212)],["drive_right",Vector2(387,212)]]
	if chassis_id=="CH-01": out.append_array([["upper_armor",Vector2(278,103)],["lower_armor",Vector2(278,209)]])
	elif chassis_id=="CH-02": out.append_array([["side_armor_left",Vector2(124,166)],["side_armor_right",Vector2(455,166)]])
	else: out.append_array([["upper_armor",Vector2(278,94)],["side_armor_left",Vector2(120,159)],["side_armor_right",Vector2(460,159)]])
	return out

func _render_stats(parent: Control, pos: Vector2, build: Dictionary) -> void:
	var stats: Dictionary=GameState.build_stats(build)
	var rows := ["TOTAL MASS     %.1f / %.0f" % [stats.mass,GameState.CHASSIS[build.chassis].load],"CORE HEALTH    %.0f" % stats.core,"DRIVE RATING   %.0f" % stats.drive,"TRACTION       %.0f" % stats.traction,"WEAPON DAMAGE  %.0f" % stats.damage,"ARMOR          %.0f" % stats.armor,"STABILITY      %.0f%%" % stats.stability]
	for i in rows.size(): _label(parent,rows[i],pos+Vector2(0,i*22),Vector2(292,22),13,Color("d4dbcf"))

func _equipped_socket(component_id: String) -> String:
	for slot in GameState.builds.size():
		for socket_id in GameState.builds[slot].parts:
			if str(GameState.builds[slot].parts[socket_id].id)==component_id and slot==GameState.selected_slot: return str(socket_id)
	return ""

func _select_slot(index: int) -> void:
	GameState.selected_slot=index; selected_socket=""; selected_component=""; GameState._save(); _garage_screen()

func _tap_socket(socket_id: String) -> void:
	selected_socket=socket_id
	if selected_component!="":
		if GameState.install_part(GameState.selected_slot,selected_component,socket_id): selected_component=""
	_refresh_garage_details()

func _rotate_selected() -> void:
	if selected_socket=="" or not GameState.selected_build().parts.has(selected_socket):
		GameState.notice="Select an occupied socket before rotating a part."
	else:
		GameState.rotate_part(GameState.selected_slot,selected_socket); GameState.notice="Part rotated 90 degrees."
	_garage_screen()

func _remove_selected() -> void:
	if selected_socket=="" or not GameState.selected_build().parts.has(selected_socket): GameState.notice="Select an occupied socket to remove its component."
	else: GameState.remove_part(GameState.selected_slot,selected_socket)
	selected_component=""; _garage_screen()

func _refresh_garage_details() -> void:
	_garage_screen()

func _start_battle(test_build: bool) -> void:
	var errors: Array[String]=GameState.validate_build(GameState.selected_build())
	if not errors.is_empty(): GameState.notice=errors[0]; _garage_screen(); return
	GameState._save()
	get_tree().change_scene_to_file("res://scenes/battle.tscn")

func _inventory_screen() -> void:
	_header("Parts Inventory · Workshop")
	var tabs := ["Chassis","Movement","Weapons","Armor","Utility"]
	for i in tabs.size():
		var cat: String=tabs[i]
		_button(page,cat.to_upper(),Vector2(30+i*190,127),Vector2(177,42),func(): inventory_tab=cat; _inventory_screen(),inventory_tab==cat,12)
	_panel(page,Vector2(30,185),Vector2(565,440))
	_panel(page,Vector2(616,185),Vector2(634,440))
	_label(page,"OWNED / LOCKED CATALOG",Vector2(52,195),Vector2(520,31),17,Color("efc26e"))
	var ids: Array[String]=[]
	if inventory_tab == "Chassis":
		for id in GameState.CHASSIS.keys(): ids.append(str(id))
	else:
		for id in GameState.PARTS.keys():
			if GameState.PARTS[id].category==inventory_tab: ids.append(str(id))
	if not ids.is_empty() and not ids.has(selected_inventory_item): selected_inventory_item=ids[0]
	var y:=239.0
	for id in ids:
		var component_id: String=id
		var is_chassis := inventory_tab == "Chassis"
		var owned_part := is_chassis or GameState.owned.has(component_id)
		var used: bool = _is_equipped_anywhere(component_id) if not is_chassis else GameState.selected_build().chassis==component_id
		var display_name := str(GameState.CHASSIS[component_id].name) if is_chassis else str(GameState.PARTS[component_id].name)
		var card := _button(page,"%s%s  ·  %s%s" % ["" if owned_part else "LOCKED · ",id,display_name,"  / EQUIPPED" if used else ""],Vector2(48,y),Vector2(520,47),func(): selected_inventory_item=component_id; _inventory_screen(),selected_inventory_item==id,12)
		y+=55
	var selected_is_chassis := inventory_tab == "Chassis"
	var pdef: Dictionary=GameState.CHASSIS.get(selected_inventory_item,{}) if selected_is_chassis else GameState.PARTS.get(selected_inventory_item,GameState.PARTS[ids[0]] if not ids.is_empty() else {})
	_label(page,"COMPONENT DETAIL",Vector2(643,198),Vector2(550,32),18,Color("efc26e"))
	_label(page,"%s  ·  %s" % [selected_inventory_item,pdef.get("name","No owned components")],Vector2(643,247),Vector2(545,37),21,Color("e2e6dc"))
	var description := "CHASSIS · %d drive mounts · %d attachment points" % [2,pdef.get("sockets",{}).size()] if selected_is_chassis else str(pdef.get("description","Select a component from the left."))
	_label(page,description,Vector2(643,293),Vector2(547,58),14,Color("becac4"))
	var is_owned := selected_is_chassis or GameState.owned.has(selected_inventory_item)
	var level:=GameState.upgrade_level(selected_inventory_item) if not selected_is_chassis else 1
	var rarity := "CHASSIS" if selected_is_chassis else (str(pdef.get("rarity","-")) if is_owned else "LOCKED · BATTLE %02d" % GameState.reward_battle_for(selected_inventory_item))
	_label(page,"RARITY  %s     MASS  %.1f     DURABILITY  %d     LOAD %.1f" % [rarity,pdef.get("mass",0.0),pdef.get("hp",pdef.get("core",0)),pdef.get("load",0.0)],Vector2(643,368),Vector2(555,28),13,Color("dbc78e"))
	_label(page,"UPGRADE LEVEL",Vector2(643,410),Vector2(180,30),14,Color("b8c6c0"))
	for i in 5:
		var fill:=i<level
		var pip:=_panel(page,Vector2(644+i*53,447),Vector2(43,18),Color("d4a953") if fill else Color("303e41"))
		pip.mouse_filter=Control.MOUSE_FILTER_IGNORE
	_label(page,"UPGRADE COST  %d SCRAP" % GameState.upgrade_cost(selected_inventory_item) if not selected_is_chassis else "Chassis upgrades are not component upgrades.",Vector2(643,482),Vector2(340,30),14,Color("e8d6a4"))
	var upgrade_button := _button(page,"UPGRADE",Vector2(643,527),Vector2(190,47),func(): GameState.buy_upgrade(selected_inventory_item); _inventory_screen(),level<5,16)
	upgrade_button.disabled = selected_is_chassis or not is_owned
	_label(page,GameState.notice,Vector2(643,582),Vector2(565,28),13,Color("d3bd7c"))
	_button(page,"BACK TO GARAGE",Vector2(938,575),Vector2(265,40),func(): show_screen("garage"),false,13)

func _is_equipped_anywhere(component_id: String) -> bool:
	for build in GameState.builds:
		for item in build.parts.values():
			if str(item.id)==component_id: return true
	return false

func _campaign_screen() -> void:
	_header("Campaign · Battle Select")
	var chapters: Array[String]=["YARD TRIALS","FOUNDRY CIRCUIT","SCRAP PIT CHAMPIONSHIP"]
	for ch in 3:
		var x:=Vector2(27+ch*410,139)
		_panel(page,x,Vector2(392,480))
		_label(page,chapters[ch],x+Vector2(18,12),Vector2(355,33),16,Color("efc26e"))
		for j in 4:
			var n:=ch*4+j+1
			var unlocked:=n<=GameState.completed_battles+1
			var done:=n<=GameState.completed_battles
			var boss:=j==3
			var txt: String="%02d  %s  ·  %s" % [n,"CHAPTER BOSS" if boss else "ARENA BOUT","COMPLETED" if done else ("AVAILABLE" if unlocked else "LOCKED")]
			var yy:=67.0+float(j)*90.0
			_button(page,txt,x+Vector2(18,yy),Vector2(355,58),func(): _select_battle(n),unlocked,12)
			var loot_names: Array[String]=[]
			for item_id in GameState.COMPONENT_REWARDS.get(n,[]): loot_names.append(str(GameState.PARTS[item_id].name))
			var loot_label := " · LOOT " + ", ".join(PackedStringArray(loot_names)) if not loot_names.is_empty() else ""
			var scrap_reward: int = 0 if GameState.rewarded_battles.has(n) else 35+n*8
			_label(page,"OPPONENT  %s · %d SCRAP%s" % [_opponent_name(n),scrap_reward,loot_label],x+Vector2(24,yy+58),Vector2(345,22),10,Color("a8b6b1"))
	_label(page,"Victory unlocks the next node. Completed battles can be replayed.",Vector2(45,640),Vector2(1180,32),14,Color("bac6be"),HORIZONTAL_ALIGNMENT_CENTER)

func _opponent_name(n: int) -> String:
	return str(GameState.OPPONENT_NAMES[clampi(n,1,12)-1])

func _select_battle(n: int) -> void:
	if n>GameState.completed_battles+1: GameState.notice="Win the previous battle to unlock this node."; return
	selected_battle=n
	GameState.current_opponent=n
	GameState.current_arena_id=str(GameState.battle_definition(n).arena)
	show_screen("preview")

func _opponent_screen() -> void:
	_header("Opponent Preview","campaign")
	var data: Dictionary=GameState.battle_definition(selected_battle)
	_panel(page,Vector2(170,146),Vector2(940,430))
	_label(page,"BATTLE %02d  ·  %s%s" % [selected_battle,data.name,"  /  CHAPTER BOSS" if data.boss else ""],Vector2(220,165),Vector2(840,48),25,Color("efc26e"),HORIZONTAL_ALIGNMENT_CENTER)
	_draw_preview_vehicles()
	_label(page,"YOUR MACHINE",Vector2(260,375),Vector2(300,30),16,Color("c2d0c5"),HORIZONTAL_ALIGNMENT_CENTER)
	var enemy_build: Dictionary=data.build
	var enemy_chassis: Dictionary=GameState.CHASSIS[enemy_build.chassis]
	_label(page,"AI %s  ·  %s" % [str(data.archetype_name).to_upper(),enemy_chassis.name.to_upper()],Vector2(675,375),Vector2(380,30),16,Color("d99170"),HORIZONTAL_ALIGNMENT_CENTER)
	_label(page,str(data.description),Vector2(235,408),Vector2(810,25),12,Color("bdc7bd"),HORIZONTAL_ALIGNMENT_CENTER)
	var loot_names: Array[String]=[]
	for item_id in data.equipment_reward: loot_names.append(str(GameState.PARTS[item_id].name))
	var loot_label := "  /  LOOT: "+", ".join(PackedStringArray(loot_names)) if not loot_names.is_empty() else ""
	var scrap_reward: int = 0 if GameState.rewarded_battles.has(selected_battle) else int(data.reward)
	_label(page,"CHAPTER %d  ·  %s  /  REWARD %d SCRAP%s  /  TIER %d" % [data.chapter,"FOUNDRY FLOOR" if data.arena=="foundry" else "SCRAP PIT",scrap_reward,loot_label,data.difficulty],Vector2(230,437),Vector2(820,27),12,Color("d2c395"),HORIZONTAL_ALIGNMENT_CENTER)
	var errors: Array[String]=GameState.validate_build(GameState.selected_build())
	_label(page,"READY" if errors.is_empty() else "BUILD ERROR: "+errors[0],Vector2(300,460),Vector2(680,30),14,Color("8dd39a") if errors.is_empty() else Color("ef8875"),HORIZONTAL_ALIGNMENT_CENTER)
	_button(page,"RETURN TO GARAGE",Vector2(335,520),Vector2(240,48),func(): show_screen("garage"))
	_button(page,"START BATTLE",Vector2(600,520),Vector2(250,48),func(): _start_battle(false),errors.is_empty(),17)

func _draw_preview_vehicles() -> void:
	var d:=Control.new(); d.position=Vector2(280,245); d.size=Vector2(710,120); page.add_child(d)
	d.draw.connect(func():
		d.draw_rect(Rect2(60,42,220,56),Color("667477"),true); d.draw_rect(Rect2(60,42,220,56),Color("1c292c"),false,4)
		for pt in [Vector2(105,105),Vector2(235,105)]: d.draw_circle(pt,22,Color("263337")); d.draw_arc(pt,22,0,TAU,24,Color("d5a958"),3)
		d.draw_circle(Vector2(292,63),17,Color("d0a14d"))
		d.draw_rect(Rect2(426,30,230,70),Color("5e696c"),true); d.draw_rect(Rect2(426,30,230,70),Color("1c292c"),false,4)
		for pt in [Vector2(470,105),Vector2(610,105)]: d.draw_circle(pt,22,Color("263337")); d.draw_arc(pt,22,0,TAU,24,Color("d5a958"),3)
		d.draw_colored_polygon(PackedVector2Array([Vector2(656,39),Vector2(682,62),Vector2(669,83),Vector2(650,67)]),Color("bc7541"))
	)

func _settings_screen() -> void:
	_header("Settings")
	_panel(page,Vector2(225,145),Vector2(830,440))
	_label(page,"AUDIO MIX",Vector2(270,177),Vector2(300,35),20,Color("efc26e"))
	_label(page,"Music volume",Vector2(270,235),Vector2(180,28),15)
	var music:=HSlider.new(); music.position=Vector2(470,223); music.size=Vector2(440,48); music.custom_minimum_size=Vector2(440,48); music.min_value=0; music.max_value=1; music.step=0.05; music.value=GameState.music_volume; music.value_changed.connect(func(v): GameState.music_volume=v; GameState._save()); page.add_child(music)
	_label(page,"Sound effects volume",Vector2(270,289),Vector2(180,28),15)
	var sfx:=HSlider.new(); sfx.position=Vector2(470,277); sfx.size=Vector2(440,48); sfx.custom_minimum_size=Vector2(440,48); sfx.min_value=0; sfx.max_value=1; sfx.step=0.05; sfx.value=GameState.sfx_volume; sfx.value_changed.connect(func(v): GameState.sfx_volume=v; GameState._save()); page.add_child(sfx)
	_button(page,"HAPTICS  %s" % ("ON" if GameState.haptics else "OFF"),Vector2(270,350),Vector2(245,45),func(): GameState.haptics=not GameState.haptics; GameState._save(); _settings_screen(),GameState.haptics,14)
	_button(page,"REDUCED SCREEN SHAKE  %s" % ("ON" if GameState.reduced_shake else "OFF"),Vector2(535,350),Vector2(350,45),func(): GameState.reduced_shake=not GameState.reduced_shake; GameState._save(); _settings_screen(),GameState.reduced_shake,13)
	_button(page,"REPLAY TUTORIAL",Vector2(270,421),Vector2(230,45),func(): GameState.tutorial_done=false; tutorial_step=0; show_screen("tutorial"),false,14)
	_button(page,"RESET LOCAL PROFILE",Vector2(515,421),Vector2(260,45),func(): _confirm_reset(),false,14)
	_label(page,"All progress is stored locally on this device.",Vector2(270,505),Vector2(590,28),14,Color("a6b7b1"))

func _confirm_reset() -> void:
	var dialog:=ConfirmationDialog.new()
	dialog.title="Reset SCRAP WARS profile?"
	dialog.dialog_text="This permanently clears local scrap, upgrades, campaign progress, settings, and saved builds."
	page.add_child(dialog)
	dialog.confirmed.connect(func(): DirAccess.remove_absolute(ProjectSettings.globalize_path(GameState.SAVE_PATH)); DirAccess.remove_absolute(ProjectSettings.globalize_path(GameState.BACKUP_PATH)); get_tree().reload_current_scene())
	dialog.popup_centered(Vector2i(550,210))

func _tutorial_screen() -> void:
	_header("Workshop Tutorial","garage")
	var steps:= ["1 / 6 · CHOOSE A CHASSIS\nUse the chassis tabs at the top of the Garage. Each frame has its own sockets and load limit.","2 / 6 · EQUIP MOVEMENT\nChoose a movement part from the Part Bin, then tap one of the green drive sockets on the machine.","3 / 6 · EQUIP A WEAPON\nPick a weapon and tap the front weapon socket. A battle-ready build requires movement and a weapon.","4 / 6 · CHECK THE LIVE READOUT\nThe workbench updates total mass, core health, drive, traction, weapon damage, armor and stability.","5 / 6 · SAVE AND START A TEST\nSave a build slot or use Test Build. Validated builds proceed to automatic physics combat.","6 / 6 · UPGRADE PARTS\nBattle rewards add scrap. Open Parts & Upgrades, select a component, and upgrade it up to level 5."]
	_panel(page,Vector2(190,170),Vector2(900,350))
	_label(page,"BUILD SMARTER. FIGHT HARDER.",Vector2(245,210),Vector2(790,55),28,Color("efc26e"),HORIZONTAL_ALIGNMENT_CENTER)
	_label(page,steps[mini(tutorial_step,5)],Vector2(295,292),Vector2(690,125),19,Color("d6ddd2"),HORIZONTAL_ALIGNMENT_CENTER)
	_button(page,"BACK",Vector2(410,495),Vector2(170,52),func(): tutorial_step=maxi(0,tutorial_step-1); _tutorial_screen())
	_button(page,"NEXT",Vector2(600,495),Vector2(170,52),func():
		tutorial_step+=1
		if tutorial_step>=6: GameState.tutorial_done=true; GameState._save(); show_screen("garage")
		else: _tutorial_screen(),true,17)

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode==KEY_ESCAPE:
		if current_screen=="menu": return
		if current_screen=="preview": show_screen("campaign")
		elif current_screen=="tutorial": show_screen("garage")
		else: show_screen("menu")
