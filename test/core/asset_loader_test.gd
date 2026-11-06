extends GdUnitTestSuite

const MISSING: String = "res://nope/missing.png"


func test_missing_texture_gives_fallback_of_requested_size() -> void:
	var tex: Texture2D = AssetLoader.texture(MISSING, Vector2i(20, 12), "a")
	assert_bool(AssetLoader.is_fallback(tex)).is_true()
	assert_vector(tex.get_size()).is_equal(Vector2(20, 12))


func test_same_id_and_size_returns_same_texture() -> void:
	var first: Texture2D = AssetLoader.texture(MISSING, Vector2i(16, 16), "same")
	var second: Texture2D = AssetLoader.texture(MISSING, Vector2i(16, 16), "same")
	assert_object(first).is_same(second)


func test_different_ids_give_different_fill_colors() -> void:
	var first: Texture2D = AssetLoader.texture(MISSING, Vector2i(8, 8), "alpha")
	var second: Texture2D = AssetLoader.texture(MISSING, Vector2i(8, 8), "beta")
	var c1: Color = first.get_image().get_pixel(4, 4)
	var c2: Color = second.get_image().get_pixel(4, 4)
	assert_bool(c1 == c2).is_false()


func test_real_texture_is_not_fallback() -> void:
	var tex: Texture2D = AssetLoader.texture(
		"res://icon.svg", Vector2i(8, 8), "icon"
	)
	assert_bool(AssetLoader.is_fallback(tex)).is_false()


func test_sprite_frames_missing_path_gives_one_fallback_frame() -> void:
	var def: AnimationDef = AnimationDef.new()
	def.id = &"walk"
	def.path = MISSING
	def.frames = 4
	def.frame_size = Vector2i(10, 10)
	def.fps = 7.0
	def.loop = false
	var frames: SpriteFrames = AssetLoader.sprite_frames([def] as Array[AnimationDef])
	assert_int(frames.get_frame_count(&"walk")).is_equal(1)
	assert_float(frames.get_animation_speed(&"walk")).is_equal(7.0)
	assert_bool(frames.get_animation_loop(&"walk")).is_false()
	assert_bool(AssetLoader.is_fallback(frames.get_frame_texture(&"walk", 0))).is_true()


func test_missing_sound_returns_null() -> void:
	assert_object(AssetLoader.sound("res://nope/missing.ogg")).is_null()
