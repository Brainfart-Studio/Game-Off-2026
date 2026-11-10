class_name UiConfig
extends GameConfig
## The shared UI look: font, colors, and the panel. Screens read it through `UiTheme`.

## Resource path of the UI font. A missing file uses the engine default font.
@export var font_path: String = "res://art/fonts/font_main.ttf"
## Font size (px).
@export var font_size: int = 8
## Color of normal text.
@export var text_color: Color = Color.WHITE
## Color of the selected or focused item.
@export var highlight_color: Color = Color(1.0, 0.85, 0.3)
## Color of unavailable or empty text.
@export var dim_color: Color = Color(0.6, 0.6, 0.6)
## Resource path of the 9-slice panel texture.
@export var panel_path: String = "res://art/ui/ui_panel.png"
## Width of the panel border and the space inside it (px).
@export var panel_margin: int = 8
## Size of the fallback panel box when the art is missing (px).
@export var panel_size: Vector2i = Vector2i(24, 24)


func validate() -> PackedStringArray:
	var warnings: PackedStringArray = PackedStringArray()
	if font_size < 1:
		warnings.append("font_size must be at least 1")
	if panel_margin < 0:
		warnings.append("panel_margin must not be negative")
	if panel_size.x <= 2 * panel_margin or panel_size.y <= 2 * panel_margin:
		warnings.append("panel_size must be larger than twice panel_margin")
	return warnings
