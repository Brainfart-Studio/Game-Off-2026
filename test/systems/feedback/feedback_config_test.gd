extends GdUnitTestSuite

var _config: FeedbackConfig


func before_test() -> void:
	_config = auto_free(FeedbackConfig.new())


func _entry(id: StringName) -> FeedbackEntry:
	var entry: FeedbackEntry = FeedbackEntry.new()
	entry.id = id
	return entry


func test_entry_lookup() -> void:
	var shift: FeedbackEntry = _entry(&"shift")
	_config.entries = [shift, _entry(&"other")]
	assert_object(_config.entry(&"shift")).is_same(shift)
	assert_object(_config.entry(&"missing")).is_null()


func test_valid_config_has_no_warnings() -> void:
	_config.entries = [_entry(&"shift")]
	_config.bindings = {&"world_shift_started": &"shift"}
	assert_int(_config.validate().size()).is_equal(0)


func test_duplicate_id_warns() -> void:
	_config.entries = [_entry(&"shift"), _entry(&"shift")]
	var warnings: PackedStringArray = _config.validate()
	assert_int(warnings.size()).is_equal(1)
	assert_str(warnings[0]).contains("duplicate")


func test_binding_to_a_missing_entry_warns() -> void:
	_config.entries = [_entry(&"shift")]
	_config.bindings = {&"shift_denied": &"nope"}
	var warnings: PackedStringArray = _config.validate()
	assert_int(warnings.size()).is_equal(1)
	assert_str(warnings[0]).contains("nope")


func test_entry_without_an_id_warns() -> void:
	_config.entries = [_entry(&"")]
	assert_int(_config.validate().size()).is_equal(1)


func test_shipped_config_is_valid() -> void:
	var shipped: FeedbackConfig = load("res://config/feedback/feedback_config.tres") as FeedbackConfig
	assert_int(shipped.validate().size()).is_equal(0)
