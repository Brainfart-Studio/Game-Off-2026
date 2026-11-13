class_name BindingButton
extends Button
## One cell of the controls page: the binding of one action on one device. A gamepad button
## shows its glyph when the image exists, otherwise its name.

var action: StringName
var device: InputRebinder.Device = InputRebinder.Device.KEYBOARD


## Shows the current binding.
func refresh() -> void:
	icon = null
	text = InputRebinder.binding_label(action, device)
	if device != InputRebinder.Device.GAMEPAD:
		return
	var glyph: String = InputRebinder.glyph_path(InputRebinder.primary(action, device))
	if glyph != "" and ResourceLoader.exists(glyph):
		icon = load(glyph) as Texture2D
		text = ""


## Shows `waiting` instead of the binding while the page listens for a new input.
func show_waiting(waiting: String) -> void:
	icon = null
	text = waiting
