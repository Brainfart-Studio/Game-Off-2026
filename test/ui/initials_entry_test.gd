extends GdUnitTestSuite

var _entry: InitialsEntry


func before_test() -> void:
	_entry = auto_free(InitialsEntry.new()) as InitialsEntry


func test_setup_shows_the_letters() -> void:
	_entry.setup("ABC")
	assert_str(_entry.text()).is_equal("ABC")


func test_setup_pads_and_cleans_bad_input() -> void:
	_entry.setup("z")
	assert_str(_entry.text()).is_equal("ZAA")
	_entry.setup("a1c")
	assert_str(_entry.text()).is_equal("AAC")


func test_letter_wraps_from_a_down_to_z() -> void:
	_entry.setup("AAA")
	_entry.change_letter(-1)
	assert_str(_entry.text()).is_equal("ZAA")


func test_letter_wraps_from_z_up_to_a() -> void:
	_entry.setup("ZAA")
	_entry.change_letter(1)
	assert_str(_entry.text()).is_equal("AAA")


func test_slot_is_clamped_at_both_ends() -> void:
	_entry.setup("AAA")
	_entry.move(-1)
	_entry.change_letter(1)
	assert_str(_entry.text()).is_equal("BAA")
	_entry.move(1)
	_entry.move(1)
	_entry.move(1)
	_entry.change_letter(2)
	assert_str(_entry.text()).is_equal("BAC")


func test_confirm_emits_the_shown_letters() -> void:
	_entry.setup("ABC")
	monitor_signals(_entry)
	_entry.confirm()
	await assert_signal(_entry).is_emitted("confirmed", ["ABC"])


func test_confirm_after_editing_emits_the_edited_letters() -> void:
	_entry.setup("AAA")
	_entry.change_letter(1)
	_entry.move(1)
	_entry.change_letter(2)
	monitor_signals(_entry)
	_entry.confirm()
	await assert_signal(_entry).is_emitted("confirmed", ["BCA"])
