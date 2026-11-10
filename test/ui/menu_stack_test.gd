extends GdUnitTestSuite

var _stack: MenuStack
var _runner: GdUnitSceneRunner
var _a: MenuPage
var _b: MenuPage
var _c: MenuPage
var _a1: Button
var _a2: Button
var _b1: Button
var _c1: Button
var _shown: Array[StringName] = []
var _emptied: int = 0


func before_test() -> void:
	_shown.clear()
	_emptied = 0
	_stack = MenuStack.new()
	_a = _make_page(&"A", 2)
	_b = _make_page(&"B", 1)
	_c = _make_page(&"C", 1)
	_a1 = _a.first_focus as Button
	_a2 = _a.get_child(0).get_child(1) as Button
	_b1 = _b.first_focus as Button
	_c1 = _c.first_focus as Button
	_stack.root_page = _a
	_runner = scene_runner(auto_free(_stack))
	_stack.page_changed.connect(_on_page_changed)
	_stack.emptied.connect(_on_emptied)


func after_test() -> void:
	InputMap.load_from_project_settings()


func _make_page(page_name: StringName, buttons: int) -> MenuPage:
	var page: MenuPage = MenuPage.new()
	page.name = page_name
	page.set_anchors_preset(Control.PRESET_FULL_RECT)
	var box: VBoxContainer = VBoxContainer.new()
	page.add_child(box)
	for i: int in buttons:
		var button: Button = Button.new()
		button.text = "%s%d" % [page_name, i]
		box.add_child(button)
		if i == 0:
			page.first_focus = button
	_stack.add_child(page)
	return page


func _on_page_changed(page: MenuPage) -> void:
	_shown.append(page.name)


func _on_emptied() -> void:
	_emptied += 1


func test_open_root_shows_only_the_root_and_focuses_its_first_control() -> void:
	_stack.open_root()
	assert_bool(_a.visible).is_true()
	assert_bool(_b.visible).is_false()
	assert_bool(_c.visible).is_false()
	assert_bool(_a1.has_focus()).is_true()
	assert_object(_stack.current()).is_same(_a)


func test_push_named_hides_the_page_below_and_focuses_the_new_one() -> void:
	_stack.open_root()
	_stack.push_named(&"B")
	assert_bool(_a.visible).is_false()
	assert_bool(_b.visible).is_true()
	assert_bool(_b1.has_focus()).is_true()


func test_cancel_goes_back_and_restores_the_focused_control() -> void:
	_stack.open_root()
	_a2.grab_focus()
	_stack.push_named(&"B")
	_runner.simulate_action_pressed("ui_cancel")
	await await_idle_frame()
	assert_bool(_a.visible).is_true()
	assert_bool(_b.visible).is_false()
	assert_bool(_a2.has_focus()).is_true()
	assert_object(_stack.current()).is_same(_a)


func test_back_at_the_root_keeps_the_page_when_it_cannot_close() -> void:
	_stack.open_root()
	_stack.back()
	assert_bool(_a.visible).is_true()
	assert_object(_stack.current()).is_same(_a)
	assert_int(_emptied).is_equal(0)


func test_back_at_the_root_closes_everything_when_it_can() -> void:
	_stack.can_close_root = true
	_stack.open_root()
	_stack.back()
	assert_bool(_a.visible).is_false()
	assert_object(_stack.current()).is_null()
	assert_int(_emptied).is_equal(1)


func test_unknown_page_is_a_push_error_and_keeps_the_page() -> void:
	_stack.open_root()
	await assert_error(func() -> void: _stack.push_named(&"Nope")) \
		.is_push_error("MenuStack: no page Nope")
	assert_object(_stack.current()).is_same(_a)
	assert_bool(_a.visible).is_true()


func test_page_changed_reports_each_shown_page() -> void:
	_stack.open_root()
	_stack.push_named(&"B")
	_stack.push_named(&"C")
	_stack.back()
	_stack.back()
	assert_array(_shown).is_equal([&"A", &"B", &"C", &"B", &"A"])
