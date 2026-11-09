extends GdUnitTestSuite

const NEUTRAL := Moveset.Direction.NEUTRAL
const SIDE := Moveset.Direction.SIDE
const UP := Moveset.Direction.UP
const DOWN := Moveset.Direction.DOWN


func _attack(id: StringName) -> AttackData:
	var data: AttackData = AttackData.new()
	data.id = id
	return data


func test_direction_from_the_eight_directions() -> void:
	assert_int(Moveset.direction_from(Vector2(1, 0))).is_equal(SIDE)
	assert_int(Moveset.direction_from(Vector2(-1, 0))).is_equal(SIDE)
	assert_int(Moveset.direction_from(Vector2(0, -1))).is_equal(UP)
	assert_int(Moveset.direction_from(Vector2(0, 1))).is_equal(DOWN)
	assert_int(Moveset.direction_from(Vector2(0.7, -0.7))).is_equal(UP)
	assert_int(Moveset.direction_from(Vector2(-0.7, -0.7))).is_equal(UP)
	assert_int(Moveset.direction_from(Vector2(0.7, 0.7))).is_equal(DOWN)
	assert_int(Moveset.direction_from(Vector2(-0.7, 0.7))).is_equal(DOWN)


func test_direction_from_prefers_the_stronger_axis() -> void:
	assert_int(Moveset.direction_from(Vector2(1, -0.6))).is_equal(SIDE)
	assert_int(Moveset.direction_from(Vector2(-1, 0.6))).is_equal(SIDE)


func test_direction_from_inside_the_deadzone_is_neutral() -> void:
	assert_int(Moveset.direction_from(Vector2.ZERO)).is_equal(NEUTRAL)
	assert_int(Moveset.direction_from(Vector2(0.4, -0.4))).is_equal(NEUTRAL)
	assert_int(Moveset.direction_from(Vector2(-0.49, 0.49))).is_equal(NEUTRAL)


func test_direction_from_uses_the_given_threshold() -> void:
	assert_int(Moveset.direction_from(Vector2(0.6, 0.0), 0.8)).is_equal(NEUTRAL)
	assert_int(Moveset.direction_from(Vector2(0.9, 0.0), 0.8)).is_equal(SIDE)


func test_ground_uses_its_slot_then_neutral() -> void:
	var set: Moveset = Moveset.new()
	set.ground_neutral = _attack(&"g_neutral")
	set.ground_side = _attack(&"g_side")
	assert_str(String(set.attack_for(true, SIDE).id)).is_equal("g_side")
	assert_str(String(set.attack_for(true, NEUTRAL).id)).is_equal("g_neutral")
	assert_str(String(set.attack_for(true, UP).id)).is_equal("g_neutral")
	assert_str(String(set.attack_for(true, DOWN).id)).is_equal("g_neutral")


func test_air_uses_air_slot_then_ground_slot_then_neutral() -> void:
	var set: Moveset = Moveset.new()
	set.ground_neutral = _attack(&"g_neutral")
	set.ground_up = _attack(&"g_up")
	set.air_side = _attack(&"a_side")
	set.air_up = _attack(&"a_up")
	assert_str(String(set.attack_for(false, SIDE).id)).is_equal("a_side")
	assert_str(String(set.attack_for(false, UP).id)).is_equal("a_up")
	set.air_up = null
	assert_str(String(set.attack_for(false, UP).id)).is_equal("g_up")
	assert_str(String(set.attack_for(false, DOWN).id)).is_equal("g_neutral")
	assert_str(String(set.attack_for(false, NEUTRAL).id)).is_equal("g_neutral")
	set.air_neutral = _attack(&"a_neutral")
	assert_str(String(set.attack_for(false, NEUTRAL).id)).is_equal("a_neutral")


func test_validate_needs_ground_neutral() -> void:
	var set: Moveset = Moveset.new()
	assert_int(set.validate().size()).is_equal(1)
	set.ground_neutral = _attack(&"g_neutral")
	assert_int(set.validate().size()).is_equal(0)


func test_validate_prefixes_slot_warnings_with_the_slot_name() -> void:
	var set: Moveset = Moveset.new()
	set.ground_neutral = _attack(&"g_neutral")
	set.air_down = AttackData.new()
	var warnings: PackedStringArray = set.validate()
	assert_int(warnings.size()).is_equal(1)
	assert_str(warnings[0]).starts_with("air_down: ")
