extends RefCounted
## Layout checks for UI tests.


## Names of `root` and every descendant Control that is visible in the tree and not fully
## inside the view (`Display.view_size()`). Empty means everything fits.
static func outside_view(root: Node) -> PackedStringArray:
	var outside: PackedStringArray = PackedStringArray()
	var view: Rect2 = Rect2(Vector2.ZERO, Vector2(Display.view_size()))
	_collect(root, view, outside)
	return outside


static func _collect(node: Node, view: Rect2, outside: PackedStringArray) -> void:
	var control: Control = node as Control
	if control != null and control.is_visible_in_tree():
		if not view.encloses(control.get_global_rect()):
			outside.append(String(control.name))
	for child: Node in node.get_children():
		_collect(child, view, outside)
