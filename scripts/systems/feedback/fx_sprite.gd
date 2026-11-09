class_name FxSprite
extends AnimatedSprite2D
## A one-shot effect sprite. Frees itself when its animation ends, or after a safety time.

## Extra time past the animation before the sprite frees itself (s).
const GRACE: float = 0.5

var _age: float = 0.0
var _max_age: float = -1.0


## Plays `def` once, centered on this node, then frees the node.
func play_once(def: AnimationDef) -> void:
	sprite_frames = AssetLoader.sprite_frames([def])
	sprite_frames.set_animation_loop(def.id, false)
	centered = true
	_max_age = float(maxi(def.frames, 1)) / maxf(def.fps, 0.01) + GRACE
	animation_finished.connect(queue_free)
	play(def.id)


func _process(delta: float) -> void:
	if _max_age < 0.0:
		return
	_age += delta
	if _age >= _max_age:
		queue_free()
