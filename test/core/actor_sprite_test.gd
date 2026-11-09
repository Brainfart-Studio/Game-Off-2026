extends GdUnitTestSuite

var _sprite: ActorSprite
var _label: AssetLabel


func before_test() -> void:
	var root: Node2D = auto_free(Node2D.new())
	_label = AssetLabel.new()
	_label.name = "AssetLabel"
	root.add_child(_label)
	_sprite = ActorSprite.new()
	_sprite.name = "Sprite"
	root.add_child(_sprite)
	add_child(root)


## A def whose file does not exist, so the sprite gets a fallback box of `size`.
func _def(id: StringName, size: Vector2i) -> AnimationDef:
	var def: AnimationDef = AnimationDef.new()
	def.id = id
	def.path = "res://test/missing/%s.png" % id
	def.frame_size = size
	def.frames = 1
	return def


func _amount() -> float:
	return (_sprite.material as ShaderMaterial).get_shader_parameter(&"flash_amount") as float


func test_wide_frame_is_anchored_at_the_feet() -> void:
	_sprite.build([_def(&"wide", Vector2i(64, 32))])
	assert_bool(_sprite.play_id(&"wide")).is_true()
	assert_vector(_sprite.offset).is_equal(Vector2(-32, -32))
	assert_bool(_sprite.centered).is_false()


func test_tall_frame_is_anchored_at_the_feet() -> void:
	_sprite.build([_def(&"tall", Vector2i(32, 64))])
	assert_bool(_sprite.play_id(&"tall")).is_true()
	assert_vector(_sprite.offset).is_equal(Vector2(-16, -64))


func test_label_follows_the_offset_and_shows_on_a_fallback() -> void:
	_sprite.build([_def(&"wide", Vector2i(64, 32)), _def(&"tall", Vector2i(32, 64))])
	_sprite.play_id(&"wide")
	assert_vector(_label.position).is_equal(Vector2(-32, -32))
	assert_bool(_label.visible).is_true()
	assert_str(_label.text).is_equal("wide")
	_sprite.play_id(&"tall")
	assert_vector(_label.position).is_equal(Vector2(-16, -64))


func test_missing_id_returns_false() -> void:
	_sprite.build([_def(&"wide", Vector2i(64, 32))])
	assert_bool(_sprite.play_id(&"nope")).is_false()


func test_flash_raises_the_amount_then_returns_to_zero() -> void:
	_sprite.build([_def(&"wide", Vector2i(64, 32))])
	assert_float(_amount()).is_equal(0.0)
	_sprite.flash(Color.RED, 0.1)
	assert_float(_amount()).is_equal(1.0)
	await await_millis(400)
	assert_float(_amount()).is_equal(0.0)


func test_find_animation_by_id_in_an_array() -> void:
	var def: AnimationDef = ActorSprite.find_animation(
		load("res://config/player/player_config.tres"), &"player_run"
	)
	assert_object(def).is_not_null()
	assert_str(String(def.id)).is_equal("player_run")


func test_find_animation_in_a_single_property() -> void:
	var def: AnimationDef = ActorSprite.find_animation(
		load("res://config/economy/economy_config.tres"), &"pickup_currency"
	)
	assert_object(def).is_not_null()


func test_find_animation_with_no_id_gives_the_first() -> void:
	var def: AnimationDef = ActorSprite.find_animation(
		load("res://config/player/player_config.tres"), &""
	)
	assert_str(String(def.id)).is_equal("player_idle")


func test_find_animation_unknown_id_is_null() -> void:
	var config: Resource = load("res://config/player/player_config.tres")
	assert_object(ActorSprite.find_animation(config, &"nope")).is_null()
	assert_object(ActorSprite.find_animation(null, &"player_idle")).is_null()
