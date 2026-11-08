class_name ActorSprite
extends AnimatedSprite2D
## A sprite for a character: its feet stay at the node origin for any frame size, it flashes
## a color on a hit, and it moves the asset label with it.

const FLASH_SHADER: Shader = preload("res://scripts/core/shaders/flash.gdshader")

## Label shown over a fallback texture. Moved to this sprite's offset on each `play_id`.
@export var label_path: NodePath = ^"../AssetLabel"

var _tween: Tween


## Builds the frames from `defs` and gives the sprite its own flash material.
func build(defs: Array[AnimationDef]) -> void:
	sprite_frames = AssetLoader.sprite_frames(defs)
	centered = false
	var flash_material: ShaderMaterial = ShaderMaterial.new()
	flash_material.shader = FLASH_SHADER
	flash_material.set_shader_parameter(&"flash_amount", 0.0)
	material = flash_material


## Plays animation `id` with the feet at the origin. False, with a warning, when it is missing.
func play_id(id: StringName) -> bool:
	if sprite_frames == null or not sprite_frames.has_animation(id):
		push_warning("ActorSprite: no animation '%s'" % id)
		return false
	play(id)
	var texture: Texture2D = sprite_frames.get_frame_texture(id, 0)
	var size: Vector2 = texture.get_size()
	offset = Vector2(-floorf(size.x / 2.0), -size.y)
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
