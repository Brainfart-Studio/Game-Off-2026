class_name EnemyAnimator
extends Node
## Plays enemy animations by id in response to StateMachine.state_changed.

## State node name -> animation suffix. A new state adds one entry.
const STATE_SUFFIXES: Dictionary[StringName, String] = {
	&"Idle": "idle",
	&"Patrol": "run",
	&"Chase": "run",
	&"Hurt": "hurt",
	&"Die": "death",
}

@onready var _enemy: Enemy = owner as Enemy
# Children _ready before their parent, so the Enemy's own @onready refs are not set yet.
@onready var _machine: StateMachine = _enemy.get_node("StateMachine")
@onready var _sprite: ActorSprite = _enemy.get_node("Visual/Sprite")


func _ready() -> void:
	_machine.state_changed.connect(_on_state_changed)


func _on_state_changed(_from: StringName, to: StringName) -> void:
	if _enemy.data == null or not STATE_SUFFIXES.has(to):
		return
	_sprite.play_id(_enemy.data.animation_id(STATE_SUFFIXES[to]))
