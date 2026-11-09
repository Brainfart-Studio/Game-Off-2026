extends Node
## Feedback service (autoload `Feedback`).
##
## Plays the effects bound to `Events` signals in `feedback_config.tres`: camera shake, hitstop,
## screen flash, sprite flash, haptics, and one-shot effect sprites. Gameplay code never calls it
## directly; it emits on `Events` and a binding does the rest.

@export var config: FeedbackConfig

## Master switch. Off blocks every effect (tests turn it off for combat physics).
var enabled: bool = true
## Off blocks camera shake (set by the P3 settings).
var shake_enabled: bool = true
## Off blocks screen flashes (set by the P3 settings).
var flash_enabled: bool = true
## Camera shake strength, 0 to 1. The offset scales with its square.
var trauma: float = 0.0

## Real time (microseconds) at which the hitstop ends, or 0 when none runs.
var _hitstop_end: int = 0
var _last_tick: int = 0
var _noise: FastNoiseLite
var _shaking: bool = false
var _flash_tween: Tween

@onready var _flash: ColorRect = $FlashLayer/Flash


func _ready() -> void:
	config.check()
	_noise = FastNoiseLite.new()
	_noise.noise_type = FastNoiseLite.TYPE_PERLIN
	_last_tick = Time.get_ticks_usec()
	EventRouter.connect_keys(Events, config.bindings.keys(), _on_event)
	Events.run_started.connect(reset)
	Events.run_ended.connect(_on_run_ended)


func _exit_tree() -> void:
	Engine.time_scale = 1.0


func _process(_delta: float) -> void:
	var now: int = Time.get_ticks_usec()
	var real_delta: float = float(now - _last_tick) / 1_000_000.0
	_last_tick = now
	if _hitstop_end > 0 and now >= _hitstop_end:
		_hitstop_end = 0
		Engine.time_scale = 1.0
	trauma = maxf(trauma - config.shake_decay * real_delta, 0.0)
	_apply_shake(float(now) / 1_000_000.0)


## Plays the entry `id`. Does nothing when disabled or when the entry does not exist.
func play(id: StringName, context: FeedbackContext = null) -> void:
	if not enabled:
		return
	var entry: FeedbackEntry = config.entry(id)
	if entry == null:
		return
	var used: FeedbackContext = context if context != null else FeedbackContext.new()
	for effect: FeedbackEffect in entry.effects:
		if effect != null:
			effect.play(used)


## Adds camera shake trauma, clamped to 0 to 1.
func add_trauma(amount: float) -> void:
	if shake_enabled:
		trauma = clampf(trauma + amount, 0.0, 1.0)


## Slows time to `time_scale` for `duration` real seconds. Overlapping hitstops extend the end.
func hitstop(duration: float, time_scale: float) -> void:
	if not enabled or duration <= 0.0:
		return
	var end: int = Time.get_ticks_usec() + int(duration * 1_000_000.0)
	_hitstop_end = maxi(_hitstop_end, end)
	Engine.time_scale = minf(Engine.time_scale, time_scale)


## Flashes the whole screen with `color`, fading out over `duration` seconds.
func screen_flash(color: Color, duration: float) -> void:
	if not flash_enabled:
		return
	_kill_flash()
	_flash.color = color
	_flash_tween = create_tween()
	_flash_tween.set_ignore_time_scale(true)
	_flash_tween.tween_property(_flash, "color", Color(color, 0.0), duration)


## Rumbles every connected gamepad.
func vibrate(weak: float, strong: float, duration: float) -> void:
	for device: int in Input.get_connected_joypads():
		Input.start_joy_vibration(device, weak, strong, duration)


## Plays `def` once at the world position `at`.
func spawn_fx(def: AnimationDef, at: Vector2) -> void:
	if def == null:
		return
	var scene: Node = get_tree().current_scene
	if scene == null:
		return
	var fx: FxSprite = FxSprite.new()
	scene.add_child(fx)
	fx.global_position = at
	fx.play_once(def)


## Stops every running effect and puts time, shake, and flash back to normal.
func reset() -> void:
	Engine.time_scale = 1.0
	_hitstop_end = 0
	trauma = 0.0
	_shaking = true
	_apply_shake(0.0)
	_kill_flash()
	_flash.color = Color(_flash.color, 0.0)


func _on_run_ended(_result: RunResult) -> void:
	reset()


func _on_event(event: StringName, args: Array) -> void:
	if not enabled:
		return
	var context: FeedbackContext = FeedbackContext.from_args(event, args)
	if not args.is_empty() and args[0] is DamageInfo:
		var info: DamageInfo = args[0] as DamageInfo
		if config.entry(info.feedback) != null:
			play(info.feedback, context)
			return
	for key: StringName in EventRouter.lookup_keys(event, args):
		if config.bindings.has(key):
			play(config.bindings[key], context)
			return


func _apply_shake(seconds: float) -> void:
	var camera: Camera2D = get_viewport().get_camera_2d()
	if camera == null:
		return
	if trauma > 0.0:
		var t: float = seconds * config.shake_noise_speed
		var noise: Vector2 = Vector2(_noise.get_noise_2d(t, 0.0), _noise.get_noise_2d(t, 100.0))
		camera.offset = config.shake_max_offset * trauma * trauma * noise
		_shaking = true
	elif _shaking:
		camera.offset = Vector2.ZERO
		_shaking = false


func _kill_flash() -> void:
	if _flash_tween != null and _flash_tween.is_valid():
		_flash_tween.kill()
	_flash_tween = null
