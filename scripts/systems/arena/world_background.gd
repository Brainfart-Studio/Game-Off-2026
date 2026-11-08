@tool
class_name WorldBackground
extends CanvasLayer
## Full-screen background for one world, with a labeled fallback when the art is missing.
## In the editor it shows the same texture in an unsaved preview child.

@export var texture_path: String = ""
@export var id: String = ""

@onready var _rect: TextureRect = $TextureRect
@onready var _label: AssetLabel = $AssetLabel


func _ready() -> void:
	if Engine.is_editor_hint():
		_add_editor_preview()
		return
	var tex: Texture2D = AssetLoader.texture(texture_path, Display.view_size(), id)
	_rect.texture = tex
	_label.show_if_fallback(tex, id)


## An internal child with no owner, so the editor draws it but never saves it into the scene.
func _add_editor_preview() -> void:
	var preview: TextureRect = TextureRect.new()
	preview.texture = AssetLoader.texture(texture_path, Display.view_size(), id)
	preview.stretch_mode = _rect.stretch_mode
	preview.size = Vector2(Display.view_size())
	preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(preview, false, Node.INTERNAL_MODE_FRONT)
