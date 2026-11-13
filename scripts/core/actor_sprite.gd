@tool
class_name ActorSprite
extends AnimatedSprite2D
## A sprite for a character: its feet stay at the node origin for any frame size, it flashes
## a color on a hit, and it moves the asset label with it. In the editor it draws the first
## frame of `preview_animation` from `preview_config`, and saves nothing into the scene.

const FLASH_SHADER: Shader = preload("res://scripts/core/shaders/flash.gdshader")
## Font size of the id drawn on a fallback box in the editor preview (px).
const PREVIEW_FONT_SIZE: int = 8

## Label shown over a fallback texture. Moved to this sprite's offset on each `play_id`.
@export var label_path: NodePath = ^"../AssetLabel"

@export_group("Editor preview")
## Config that holds the animation shown in the editor (any resource with AnimationDefs).
## A path, not a resource, so an enemy scene never depends on its own data (R-069).
@export_file("*.tres") var preview_config: String = "":
	set(value):
		preview_config = value
		queue_redraw()
## Animation shown in the editor. Empty shows the first one in `preview_config`.
@export var preview_animation: StringName = &"":
	set(value):
		preview_animation = value
		queue_redraw()

var _tween: Tween
## Each animation's `draw_offset`, by id.
var _draw_offsets: Dictionary = {}


## Builds the frames from `defs` and gives the sprite its own flash material.
func build(defs: Array[AnimationDef]) -> void:
	sprite_frames = AssetLoader.sprite_frames(defs)
	_draw_offsets.clear()
	for def: AnimationDef in defs:
		_draw_offsets[def.id] = Vector2(def.draw_offset)
	centered = false
	var flash_material: ShaderMaterial = ShaderMaterial.new()
	flash_material.shader = FLASH_SHADER
	flash_material.set_shader_parameter(&"flash_amount", 0.0)
	material = flash_material


## Plays animation `id` with the feet at the origin, moved by its `draw_offset`. False, with a
## warning, when it is missing.
func play_id(id: StringName) -> bool:
	if sprite_frames == null or not sprite_frames.has_animation(id):
		push_warning("ActorSprite: no animation '%s'" % id)
		return false
	play(id)
	var texture: Texture2D = sprite_frames.get_frame_texture(id, 0)
	var size: Vector2 = texture.get_size()
	var shift: Vector2 = _draw_offsets.get(id, Vector2.ZERO) as Vector2
	offset = Vector2(-floorf(size.x / 2.0), -size.y) + shift
	var label: AssetLabel = get_node_or_null(label_path) as AssetLabel
	if label != null:
		label.position = offset
		label.show_if_fallback(texture, String(id))
	return true


## Blends the sprite to `color` at once, then back to normal over `duration` seconds.
func flash(color: Color, duration: float) -> void:
	var flash_material: ShaderMaterial = material as ShaderMaterial
	if flash_material == null:
		return
	if _tween != null and _tween.is_valid():
		_tween.kill()
	flash_material.set_shader_parameter(&"flash_color", color)
	flash_material.set_shader_parameter(&"flash_amount", 1.0)
	_tween = create_tween()
	_tween.tween_method(
		func(amount: float) -> void: flash_material.set_shader_parameter(&"flash_amount", amount),
		1.0,
		0.0,
		maxf(duration, 0.01)
	)


## The AnimationDef `id` held by `config`, in a property or an array property. The first one found
## when `id` is empty. Null when none matches.
static func find_animation(config: Resource, id: StringName) -> AnimationDef:
	if config == null:
		return null
	for property: Dictionary in config.get_property_list():
		if not int(property["usage"]) & PROPERTY_USAGE_STORAGE:
			continue
		var value: Variant = config.get(property["name"])
		var items: Array = value if value is Array else [value]
		for item: Variant in items:
			if item is AnimationDef and (id == &"" or (item as AnimationDef).id == id):
				return item as AnimationDef
	return null


## Editor only: the first frame of the preview animation with the feet at the origin, or its
## labeled fallback box.
func _draw() -> void:
	if not Engine.is_editor_hint() or not ResourceLoader.exists(preview_config):
		return
	var def: AnimationDef = find_animation(load(preview_config), preview_animation)
	if def == null:
		return
	var size: Vector2 = Vector2(def.frame_size)
	var corner: Vector2 = Vector2(-floorf(size.x / 2.0), -size.y) + Vector2(def.draw_offset)
	var strip: Texture2D = AssetLoader.texture(def.path, def.frame_size, String(def.id))
	draw_texture_rect_region(strip, Rect2(corner, size), Rect2(Vector2.ZERO, size))
	if AssetLoader.is_fallback(strip):
		var baseline: Vector2 = corner + Vector2(2.0, PREVIEW_FONT_SIZE + 1.0)
		draw_string(
			ThemeDB.fallback_font, baseline, String(def.id), HORIZONTAL_ALIGNMENT_LEFT, -1.0,
			PREVIEW_FONT_SIZE
		)
