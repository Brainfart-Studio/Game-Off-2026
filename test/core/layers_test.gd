extends GdUnitTestSuite


func test_names_match_project_layer_names() -> void:
	for i: int in Layers.NAMES.size():
		var key: String = "layer_names/2d_physics/layer_%d" % (i + 1)
		assert_str(String(Layers.NAMES[i])).is_equal(ProjectSettings.get_setting(key))


func test_bits_follow_layer_order() -> void:
	var bits: Array[int] = [
		Layers.WORLD,
		Layers.PLAYER,
		Layers.ENEMY,
		Layers.PLAYER_HITBOX,
		Layers.PLAYER_HURTBOX,
		Layers.ENEMY_HITBOX,
		Layers.ENEMY_HURTBOX,
		Layers.PICKUP,
	]
	assert_int(bits.size()).is_equal(Layers.NAMES.size())
	for i: int in bits.size():
		assert_int(bits[i]).is_equal(1 << i)
