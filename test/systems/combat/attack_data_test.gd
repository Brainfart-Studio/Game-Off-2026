extends GdUnitTestSuite


func _valid() -> AttackData:
	var data: AttackData = AttackData.new()
	data.id = &"slash"
	return data


func test_times_scale_with_speed() -> void:
	var data: AttackData = _valid()
	data.startup = 0.1
	data.active = 0.2
	data.recovery = 0.3
	assert_float(data.startup_time(2.0)).is_equal_approx(0.05, 0.0001)
	assert_float(data.active_time(2.0)).is_equal_approx(0.1, 0.0001)
	assert_float(data.recovery_time(2.0)).is_equal_approx(0.15, 0.0001)
	assert_float(data.total_time(2.0)).is_equal_approx(0.3, 0.0001)


func test_speed_below_floor_does_not_divide_by_zero() -> void:
	var data: AttackData = _valid()
	data.startup = 0.01
	assert_float(data.startup_time(0.0)).is_equal_approx(1.0, 0.0001)
	assert_float(data.startup_time(-3.0)).is_equal_approx(1.0, 0.0001)


func test_default_attack_with_id_is_valid() -> void:
	assert_int(_valid().validate().size()).is_equal(0)


func test_validate_flags_each_problem() -> void:
	var data: AttackData = AttackData.new()
	assert_int(data.validate().size()).is_equal(1)
	data.id = &"slash"
	data.hitbox_size = Vector2(0, 16)
	assert_int(data.validate().size()).is_equal(1)
	data.hitbox_size = Vector2(24, 16)
	data.startup = -0.1
	assert_int(data.validate().size()).is_equal(1)
	data.startup = 0.05
	data.recovery = -0.1
	assert_int(data.validate().size()).is_equal(1)
	data.recovery = 0.15
	data.active = 0.0
	assert_int(data.validate().size()).is_equal(1)
	data.active = 0.1
	data.damage = -1
	assert_int(data.validate().size()).is_equal(1)
	data.damage = 1
	data.move_control = 1.5
	assert_int(data.validate().size()).is_equal(1)
	data.move_control = -0.1
	assert_int(data.validate().size()).is_equal(1)
	data.move_control = 0.5
	assert_int(data.validate().size()).is_equal(0)
