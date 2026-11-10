class_name UiTheme
extends RefCounted
## Builds the shared UI `Theme` from a `UiConfig`.

static var _cache: Dictionary[UiConfig, Theme] = {}


## The theme for `config`, built once per config.
static func build(config: UiConfig) -> Theme:
	if _cache.has(config):
		return _cache[config]
	var theme: Theme = Theme.new()
	var font: Font = AssetLoader.font(config.font_path)
	if font != null:
		theme.default_font = font
	theme.default_font_size = config.font_size
	theme.set_color(&"font_color", &"Label", config.text_color)
	theme.set_color(&"font_color", &"Button", config.text_color)
	theme.set_color(&"font_hover_color", &"Button", config.highlight_color)
	theme.set_color(&"font_pressed_color", &"Button", config.highlight_color)
	theme.set_color(&"font_focus_color", &"Button", config.highlight_color)
	theme.set_color(&"font_disabled_color", &"Button", config.dim_color)
	var focus: StyleBoxFlat = StyleBoxFlat.new()
	focus.draw_center = false
	focus.set_border_width_all(1)
	focus.border_color = config.highlight_color
	theme.set_stylebox(&"focus", &"Button", focus)
	for state: StringName in [&"normal", &"hover", &"pressed", &"disabled"]:
		var compact: StyleBoxEmpty = StyleBoxEmpty.new()
		compact.content_margin_left = 2.0
		compact.content_margin_right = 2.0
		compact.content_margin_top = 1.0
		compact.content_margin_bottom = 1.0
		theme.set_stylebox(state, &"Button", compact)
	var panel: StyleBoxTexture = StyleBoxTexture.new()
	panel.texture = AssetLoader.texture(config.panel_path, config.panel_size, "ui_panel")
	panel.set_texture_margin_all(config.panel_margin)
	panel.set_content_margin_all(config.panel_margin)
	theme.set_stylebox(&"panel", &"PanelContainer", panel)
	_cache[config] = theme
	return theme
