class_name ShiftTransition
extends CanvasLayer
## Screen fade used by the world shift. The only place the shift look lives.

var _rect: ColorRect
var _tween: Tween


func _ready() -> void:
	layer = 50
	_rect = ColorRect.new()
	_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rect.color = Color(0.0, 0.0, 0.0, 0.0)
	add_child(_rect)


## Fades to the cover color, then holds. Awaitable.
func cover(config: ShiftConfig) -> void:
	var clear: Color = config.fade_color
	clear.a = 0.0
	_rect.color = clear
	await _fade_to(config.fade_color, config.fade_out, config)
	if config.hold > 0.0:
		await get_tree().create_timer(config.hold).timeout


## Fades from the cover color back to clear. Awaitable.
func reveal(config: ShiftConfig) -> void:
	var clear: Color = config.fade_color
	clear.a = 0.0
	await _fade_to(clear, config.fade_in, config)


func _fade_to(target: Color, duration: float, config: ShiftConfig) -> void:
	if _tween != null and _tween.is_valid():
		_tween.kill()
	if duration <= 0.0:
		_rect.color = target
		return
	_tween = create_tween()
	_tween.set_trans(config.transition_trans)
	_tween.tween_property(_rect, "color", target, duration)
	await _tween.finished
