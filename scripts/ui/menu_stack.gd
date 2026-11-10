class_name MenuStack
extends Control
## A stack of `MenuPage` children, one visible at a time. Moves focus to the page's first control,
## remembers the focused control of pages underneath, and goes back on `ui_cancel`.

signal emptied()
signal page_changed(page: MenuPage)

const MOVE_SOUND := &"ui_move"
const BACK_SOUND := &"ui_back"

@export var root_page: MenuPage
## When true, going back at the root closes the stack and emits `emptied`.
@export var can_close_root: bool = false

var _stack: Array[MenuPage] = []
var _focus_memory: Dictionary[MenuPage, Control] = {}
var _moving_focus: bool = false


func _ready() -> void:
	for child: Node in get_children():
		var page: MenuPage = child as MenuPage
		if page == null:
			continue
		page.hide()
		page.push_requested.connect(push_named)
		page.back_requested.connect(back)
	get_viewport().gui_focus_changed.connect(_on_focus_changed)


## The page on top of the stack, or null.
func current() -> MenuPage:
	return null if _stack.is_empty() else _stack.back()


func open_root() -> void:
	close_all()
	push(root_page)


func close_all() -> void:
	for page: MenuPage in _stack:
		page.hide()
	_stack.clear()
	_focus_memory.clear()


func push_named(page_name: StringName) -> void:
	var page: MenuPage = get_node_or_null(NodePath(page_name)) as MenuPage
	if page == null:
		push_error("MenuStack: no page %s" % page_name)
		return
	push(page)


func push(page: MenuPage) -> void:
	var top: MenuPage = current()
	if top != null:
		var owner_control: Control = get_viewport().gui_get_focus_owner()
		if owner_control != null:
			_focus_memory[top] = owner_control
		top.hide()
	_stack.append(page)
	page.show()
	page.opened()
	_focus(page.first_focus)
	page_changed.emit(page)


func back() -> void:
	if _stack.is_empty():
		return
	if _stack.size() == 1:
		if not can_close_root:
			return
		Audio.play(BACK_SOUND)
		close_all()
		emptied.emit()
		return
	Audio.play(BACK_SOUND)
	var top: MenuPage = _stack.pop_back()
	top.hide()
	_focus_memory.erase(top)
	var previous: MenuPage = _stack.back()
	previous.show()
	previous.opened()
	_focus(_focus_memory.get(previous, previous.first_focus))
	page_changed.emit(previous)


func _focus(control: Control) -> void:
	if control == null or not control.is_visible_in_tree():
		return
	_moving_focus = true
	control.grab_focus()
	_moving_focus = false


func _on_focus_changed(control: Control) -> void:
	if _moving_focus or not is_visible_in_tree():
		return
	var page: MenuPage = current()
	if page != null and control != null and page.is_ancestor_of(control):
		Audio.play(MOVE_SOUND)


func _unhandled_input(event: InputEvent) -> void:
	if not is_visible_in_tree() or current() == null:
		return
	if event.is_action_pressed(Actions.UI_CANCEL):
		back()
		get_viewport().set_input_as_handled()
