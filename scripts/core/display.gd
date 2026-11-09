@tool
class_name Display
## Display helpers. The view size comes from project settings, never a literal.


static func view_size() -> Vector2i:
	var w: int = ProjectSettings.get_setting("display/window/size/viewport_width")
	var h: int = ProjectSettings.get_setting("display/window/size/viewport_height")
	return Vector2i(w, h)
