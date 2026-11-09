class_name DamageInfo
extends RefCounted
## One hit, from the hitbox that landed it to the health that took it.

## Health removed.
var amount: int = 0
## Velocity change for the target (px/s).
var knockback: Vector2 = Vector2.ZERO
## Node that dealt the hit.
var source: Node2D = null
## Node that took the hit. Set by the hurtbox.
var target: Node2D = null
## Id of the attack that dealt the hit.
var attack_id: StringName = &""
## World position of the hit.
var position: Vector2 = Vector2.ZERO
## Tags copied from the attack.
var tags: Array[StringName] = []
## Feedback entry id to play for this hit. Empty keeps the event's own binding.
var feedback: StringName = &""
## Sound id to play for this hit. Empty keeps the event's own binding.
var sound: StringName = &""
