extends GdUnitTestSuite


func _def(id: String, path: String, frames: int) -> AnimationDef:
	var def := AnimationDef.new()
	def.id = StringName(id)
	def.path = path
	def.frames = frames
	return def


func test_defaults_have_no_warnings() -> void:
	assert_array(PlayerConfig.new().validate()).is_empty()


func test_gravity_and_velocity_for_default_jump() -> void:
	assert_float(PlayerConfig.gravity_for(56.0, 0.36)).is_equal_approx(2.0 * 56.0 / (0.36 * 0.36), 0.001)
	assert_float(PlayerConfig.velocity_for(56.0, 0.36)).is_equal_approx(2.0 * 56.0 / 0.36, 0.001)


func test_instance_helpers_use_config_values() -> void:
	var config := PlayerConfig.new()
	assert_float(config.jump_gravity()).is_equal(PlayerConfig.gravity_for(56.0, 0.36))
	assert_float(config.jump_velocity()).is_equal(PlayerConfig.velocity_for(56.0, 0.36))


func test_zero_height_warns() -> void:
	var config := PlayerConfig.new()
	config.jump_height = 0.0
	assert_array(config.validate()).contains(["jump_height must be positive"])


func test_zero_time_warns() -> void:
	var config := PlayerConfig.new()
	config.time_to_apex = 0.0
	assert_array(config.validate()).contains(["time_to_apex must be positive"])


func test_empty_animation_path_warns() -> void:
	var config := PlayerConfig.new()
	config.animations = [_def("idle", "", 1)] as Array[AnimationDef]
	assert_array(config.validate()).contains(["animation 'idle' has an empty path"])


func test_zero_frames_warns() -> void:
	var config := PlayerConfig.new()
	config.animations = [_def("idle", "res://x.png", 0)] as Array[AnimationDef]
	assert_array(config.validate()).contains(["animation 'idle' needs at least 1 frame"])


func test_null_animation_entry_warns() -> void:
	var config := PlayerConfig.new()
	config.animations = [null] as Array[AnimationDef]
	assert_array(config.validate()).contains(["animations has an empty entry"])
