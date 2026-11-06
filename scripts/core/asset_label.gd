class_name AssetLabel
extends Label
## Small id label shown only on fallback textures, so a missing asset reads as a labeled box.


func _init() -> void:
	var settings: LabelSettings = LabelSettings.new()
	settings.font_size = 8
	label_settings = settings
	visible = false


func show_if_fallback(tex: Texture2D, id: String) -> void:
	text = id
	visible = AssetLoader.is_fallback(tex)
