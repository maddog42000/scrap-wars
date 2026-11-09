extends Node

## Optional replacement art for SCRAP WARS. Missing resources are normal: callers retain
## their original procedural drawing. Keys are stable semantic IDs, not filenames guessed
## throughout gameplay scripts.
const TEXTURE_PATHS := {
	"machines/chassis/ch-01": "res://assets/art/machines/chassis/ch-01.png",
	"machines/chassis/ch-02": "res://assets/art/machines/chassis/ch-02.png",
	"machines/chassis/ch-03": "res://assets/art/machines/chassis/ch-03.png",
	"components/locomotion/mv-01": "res://assets/art/components/locomotion/mv-01.png",
	"components/locomotion/mv-02": "res://assets/art/components/locomotion/mv-02.png",
	"components/locomotion/mv-03": "res://assets/art/components/locomotion/mv-03.png",
	"components/locomotion/mv-04": "res://assets/art/components/locomotion/mv-04.png",
	"components/locomotion/crank-axle": "res://assets/art/components/locomotion/crank-axle.png",
	"components/locomotion/crank-leg": "res://assets/art/components/locomotion/crank-leg.png",
	"components/weapons/wp-01": "res://assets/art/components/weapons/wp-01.png",
	"components/weapons/wp-02": "res://assets/art/components/weapons/wp-02.png",
	"components/weapons/wp-03": "res://assets/art/components/weapons/wp-03.png",
	"components/weapons/wp-04": "res://assets/art/components/weapons/wp-04.png",
	"components/armor/ar-01": "res://assets/art/components/armor/ar-01.png",
	"components/armor/ar-02": "res://assets/art/components/armor/ar-02.png",
	"components/armor/ar-03": "res://assets/art/components/armor/ar-03.png",
	"components/utility/ut-01": "res://assets/art/components/utility/ut-01.png",
	"components/utility/ut-02": "res://assets/art/components/utility/ut-02.png",
	"arenas/foundry-floor": "res://assets/art/arenas/foundry-floor.png",
	"arenas/scrap-pit": "res://assets/art/arenas/scrap-pit.png",
	"ui/backgrounds/main-menu": "res://assets/art/ui/backgrounds/main-menu.png",
	"ui/illustrations/featured-machine": "res://assets/art/ui/illustrations/featured-machine.png",
}

var _texture_cache: Dictionary = {}
var _animation_cache: Dictionary = {}

func texture_for(asset_key: String) -> Texture2D:
	if _texture_cache.has(asset_key):
		return _texture_cache[asset_key] as Texture2D
	var path := str(TEXTURE_PATHS.get(asset_key, ""))
	var texture := texture_at_path(path) if not path.is_empty() else null
	_texture_cache[asset_key] = texture
	return texture

func texture_at_path(path: String) -> Texture2D:
	if path.is_empty() or not ResourceLoader.exists(path):
		return null
	var loaded := ResourceLoader.load(path)
	return loaded as Texture2D

func draw_texture(canvas: CanvasItem, asset_key: String, destination: Rect2, modulation := Color.WHITE) -> bool:
	var texture := texture_for(asset_key)
	if texture == null:
		return false
	canvas.draw_texture_rect(texture, destination, false, modulation)
	return true

func animation_path(asset_key: String) -> String:
	return "res://assets/animations/" + asset_key + ".tres"

func animation_for(asset_key: String) -> SpriteFrames:
	if _animation_cache.has(asset_key):
		return _animation_cache[asset_key] as SpriteFrames
	var path := animation_path(asset_key)
	var frames: SpriteFrames
	if ResourceLoader.exists(path):
		frames = ResourceLoader.load(path) as SpriteFrames
	_animation_cache[asset_key] = frames
	return frames

func mount_animation_visual(parent: Node2D, asset_key: String, target_size: Vector2, local_position := Vector2.ZERO) -> bool:
	var old_visual := parent.get_node_or_null("ExternalAssetAnimation")
	if is_instance_valid(old_visual):
		old_visual.queue_free()
	parent.set_meta("external_animation_enabled", false)
	var frames := animation_for(asset_key)
	if frames == null or frames.get_animation_names().is_empty():
		return false
	var animation_name := String(frames.get_animation_names()[0])
	if frames.get_frame_count(animation_name) <= 0:
		return false
	var sprite := AnimatedSprite2D.new()
	sprite.name = "ExternalAssetAnimation"
	sprite.sprite_frames = frames
	sprite.animation = animation_name
	sprite.centered = true
	sprite.position = local_position
	sprite.z_index = 0
	var first_frame := frames.get_frame_texture(animation_name, 0)
	if first_frame != null and first_frame.get_size().x > 0.0 and first_frame.get_size().y > 0.0:
		sprite.scale = target_size / first_frame.get_size()
	parent.add_child(sprite)
	sprite.play()
	parent.set_meta("external_animation_enabled", true)
	return true

func button_key_from_text(caption: String) -> String:
	var value := caption.strip_edges().to_upper()
	if value in ["−", "-"]:
		return "slow"
	if value in ["+", "＋"]:
		return "fast"
	if value.begins_with("PLAY CAMPAIGN"):
		return "play_campaign"
	if value.begins_with("ENTER GARAGE"):
		return "enter_garage"
	if value == "START BATTLE" or value == "BATTLE":
		return "start_battle"
	if value == "BACK":
		return "back"
	if value == "PAUSE":
		return "pause"
	if value == "RESUME":
		return "resume"
	if value == "RESTART":
		return "restart"
	if value == "SLOW":
		return "slow"
	if value == "FAST":
		return "fast"
	if value == "NORMAL":
		return "normal"
	return ""

func apply_button_textures(button: Button, button_key: String) -> void:
	if button_key.is_empty():
		return
	var base_path := "res://assets/art/ui/buttons/" + button_key
	var normal_texture := texture_at_path(base_path + "_normal.png")
	if normal_texture == null:
		normal_texture = texture_at_path(base_path + ".png")
	var states := ["normal", "hover", "pressed", "disabled"]
	for state in states:
		var texture := texture_at_path(base_path + "_" + state + ".png")
		if texture == null:
			texture = normal_texture
		if texture == null:
			continue
		var style := StyleBoxTexture.new()
		style.texture = texture
		style.texture_margin_left = 10.0
		style.texture_margin_right = 10.0
		style.texture_margin_top = 8.0
		style.texture_margin_bottom = 8.0
		style.content_margin_left = 12.0
		style.content_margin_right = 12.0
		style.content_margin_top = 6.0
		style.content_margin_bottom = 6.0
		button.add_theme_stylebox_override(state, style)
