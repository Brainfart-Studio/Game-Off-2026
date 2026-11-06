class_name WorldBackground
extends CanvasLayer
## Full-screen background for one world, with a labeled fallback when the art is missing.

@export var texture_path: String = ""
@export var id: String = ""

@onready var _rect: TextureRect = $TextureRect
@onready var _label: AssetLabel = $AssetLabel


func _ready() -> void:
	var tex: Texture2D = AssetLoader.texture(texture_path, Display.view_size(), id)
	_rect.texture = tex
	_label.show_if_fallback(tex, id)
