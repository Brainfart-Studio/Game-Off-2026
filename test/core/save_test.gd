extends GdUnitTestSuite

const SAVE_SCRIPT: String = "res://scripts/core/save.gd"
const TEST_PATH: String = "user://save_test.cfg"

var _save: Node


func before_test() -> void:
	_remove_file()
	_save = _make_save()


func after_test() -> void:
	_remove_file()


func _make_save() -> Node:
	var save: Node = auto_free((load(SAVE_SCRIPT) as GDScript).new()) as Node
	save.path = TEST_PATH
	save.load_file()
	return save


func _remove_file() -> void:
	var absolute: String = ProjectSettings.globalize_path(TEST_PATH)
	if FileAccess.file_exists(absolute):
		DirAccess.remove_absolute(absolute)


func _scores(save: Node) -> Array[int]:
	var result: Array[int] = []
	for entry: Dictionary in save.high_scores():
		result.append(int(entry["score"]))
	return result


func _fill(count: int) -> void:
	for i: int in count:
		_save.add_high_score("AAA", (i + 1) * 10)


func test_empty_save_has_no_scores_and_default_initials() -> void:
	assert_array(_save.high_scores()).is_empty()
	assert_str(_save.last_initials()).is_equal("AAA")


func test_inserts_keep_highest_first() -> void:
	_save.add_high_score("AAA", 100)
	_save.add_high_score("BBB", 300)
	_save.add_high_score("CCC", 200)
	assert_array(_scores(_save)).is_equal([300, 200, 100])
	var entries: Array[Dictionary] = _save.high_scores()
	assert_str(entries[0]["initials"]).is_equal("BBB")
	assert_str(entries[2]["initials"]).is_equal("AAA")


func test_list_is_capped_at_ten() -> void:
	_fill(12)
	assert_int(_save.high_scores().size()).is_equal(10)
	assert_array(_scores(_save)).is_equal([120, 110, 100, 90, 80, 70, 60, 50, 40, 30])


func test_qualifies_needs_a_score_above_zero() -> void:
	assert_bool(_save.qualifies(0)).is_false()
	assert_bool(_save.qualifies(-5)).is_false()
	assert_bool(_save.qualifies(1)).is_true()


func test_qualifies_on_a_full_list_needs_more_than_the_lowest() -> void:
	_fill(10)
	assert_bool(_save.qualifies(10)).is_false()
	assert_bool(_save.qualifies(5)).is_false()
	assert_bool(_save.qualifies(11)).is_true()


func test_qualifies_while_the_list_has_room() -> void:
	_fill(9)
	assert_bool(_save.qualifies(1)).is_true()


func test_add_returns_the_rank() -> void:
	assert_int(_save.add_high_score("AAA", 100)).is_equal(0)
	assert_int(_save.add_high_score("BBB", 300)).is_equal(0)
	assert_int(_save.add_high_score("CCC", 200)).is_equal(1)
	assert_int(_save.add_high_score("DDD", 50)).is_equal(3)


func test_equal_score_ranks_below_the_existing_one() -> void:
	_save.add_high_score("AAA", 100)
	assert_int(_save.add_high_score("BBB", 100)).is_equal(1)
	assert_str(_save.high_scores()[0]["initials"]).is_equal("AAA")


func test_score_below_a_full_list_returns_minus_one() -> void:
	_fill(10)
	assert_int(_save.add_high_score("ZZZ", 5)).is_equal(-1)
	assert_array(_scores(_save)).is_equal([100, 90, 80, 70, 60, 50, 40, 30, 20, 10])


func test_scores_reload_from_the_file() -> void:
	_save.add_high_score("AAA", 100)
	_save.add_high_score("BBB", 300)
	var reloaded: Node = _make_save()
	assert_array(_scores(reloaded)).is_equal([300, 100])
	assert_str(reloaded.high_scores()[0]["initials"]).is_equal("BBB")


func test_last_initials_are_remembered_and_reload() -> void:
	_save.add_high_score("ZED", 100)
	assert_str(_save.last_initials()).is_equal("ZED")
	assert_str(_make_save().last_initials()).is_equal("ZED")
