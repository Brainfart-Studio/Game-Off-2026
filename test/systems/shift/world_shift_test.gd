extends GdUnitTestSuite

var _shift: WorldShift
var _runner: GdUnitSceneRunner
var _seen: Array[String] = []


func before_test() -> void:
	_seen.clear()
	var scene: PackedScene = load("res://scenes/shift/world_shift.tscn")
	_shift = auto_free(scene.instantiate())
	var config: ShiftConfig = _shift.config.duplicate()
	config.fade_out = 0.01
	config.fade_in = 0.01
	config.cooldown = 0.1
	_shift.config = config
	Events.world_shifted.connect(_on_shifted)
	Events.world_shift_started.connect(_on_started)
	Events.shift_denied.connect(_on_denied)
	_runner = scene_runner(_shift)
	await await_millis(50)


func after_test() -> void:
	Events.world_shifted.disconnect(_on_shifted)
	Events.world_shift_started.disconnect(_on_started)
	Events.shift_denied.disconnect(_on_denied)


func _on_shifted(to: World.Id) -> void:
	_seen.append("shifted:%d" % to)


func _on_started(to: World.Id) -> void:
	_seen.append("started:%d" % to)


func _on_denied() -> void:
	_seen.append("denied")


func test_start_announces_peaceful() -> void:
	assert_array(_seen).is_equal(["shifted:%d" % World.Id.PEACEFUL])


func test_shift_emits_started_then_shifted() -> void:
	_seen.clear()
	_shift.shift()
	await await_millis(80)
	assert_array(_seen).is_equal([
		"started:%d" % World.Id.COMBAT,
		"shifted:%d" % World.Id.COMBAT,
	])
	assert_int(_shift.current).is_equal(World.Id.COMBAT)


func test_second_shift_during_cooldown_is_denied() -> void:
	_shift.shift()
	_seen.clear()
	_shift.shift()
	assert_array(_seen).is_equal(["denied"])


func test_shift_back_after_cooldown() -> void:
	_shift.shift()
	await await_millis(250)
	_seen.clear()
	_shift.shift()
	await await_millis(80)
	assert_array(_seen).is_equal([
		"started:%d" % World.Id.PEACEFUL,
		"shifted:%d" % World.Id.PEACEFUL,
	])
