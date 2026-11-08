extends GdUnitTestSuite

var _hud: HUD


func before_test() -> void:
	_hud = auto_free((load("res://scenes/ui/hud.tscn") as PackedScene).instantiate()) as HUD
	scene_runner(_hud)


func after_test() -> void:
	Game.reset()


func _label(node_name: String) -> Label:
	return _hud.get_node("%" + node_name) as Label


func test_format_time_rounds_up_to_the_started_second() -> void:
	assert_str(HUD.format_time(125.2)).is_equal("2:06")
	assert_str(HUD.format_time(60.0)).is_equal("1:00")
	assert_str(HUD.format_time(9.1)).is_equal("0:10")
	assert_str(HUD.format_time(0.0)).is_equal("0:00")


func test_time_changed_sets_the_timer() -> void:
	Events.time_changed.emit(65.0)
	assert_str(_label("Timer").text).is_equal("1:05")


func test_world_shifted_sets_the_world_name() -> void:
	Events.world_shifted.emit(World.Id.COMBAT)
	assert_str(_label("World").text).is_equal("COMBAT")
	Events.world_shifted.emit(World.Id.PEACEFUL)
	assert_str(_label("World").text).is_equal("PEACEFUL")


func test_score_and_wallet_events_set_their_labels() -> void:
	Events.score_changed.emit(1250)
	Events.wallet_changed.emit(42)
	assert_str(_label("Score").text).is_equal("1250")
	assert_str(_label("CurrencyAmount").text).is_equal("42")


func test_combo_changed_sets_the_bar_and_multiplier() -> void:
	Events.combo_changed.emit(0.5, 3)
	var combo: TextureProgressBar = _hud.get_node("%Combo") as TextureProgressBar
	assert_float(combo.value).is_equal(0.5)
	assert_str(_label("Multiplier").text).is_equal("x3")


func test_pips_rebuild_when_the_max_changes() -> void:
	var health: HBoxContainer = _hud.get_node("%Health") as HBoxContainer
	Events.player_health_changed.emit(2, 3)
	assert_int(health.get_child_count()).is_equal(3)
	var full: Texture2D = (health.get_child(0) as TextureRect).texture
	var empty: Texture2D = (health.get_child(2) as TextureRect).texture
	assert_object((health.get_child(1) as TextureRect).texture).is_same(full)
	assert_object(empty).is_not_same(full)
	Events.player_health_changed.emit(5, 5)
	assert_int(health.get_child_count()).is_equal(5)
	assert_object((health.get_child(4) as TextureRect).texture).is_same(full)
	Events.player_health_changed.emit(1, 2)
	assert_int(health.get_child_count()).is_equal(2)
	assert_object((health.get_child(1) as TextureRect).texture).is_same(empty)


func test_time_warning_highlights_the_timer_until_the_next_run() -> void:
	var timer: Label = _label("Timer")
	Events.time_warning.emit(5)
	assert_object(timer.get_theme_color(&"font_color")).is_equal(_hud.config.highlight_color)
	Events.run_started.emit()
	assert_object(timer.get_theme_color(&"font_color")).is_equal(_hud.config.text_color)
