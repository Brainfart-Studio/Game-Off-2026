class_name PlayerAttack
extends PlayerState
## One attack from the moveset: startup, hitbox active, recovery. Steering is scaled by the
## attack's `move_control` and the facing is held until the attack ends.

var _attack: AttackData
var _time: float = 0.0
var _speed: float = 1.0
var _hitbox_on: bool = false
var _hitbox_done: bool = false


func enter(previous: StringName) -> void:
	super(previous)
	var direction: Moveset.Direction = Moveset.direction_from(player.input.move)
	_attack = player.config.moveset.attack_for(player.is_on_floor(), direction)
	if direction == Moveset.Direction.SIDE:
		player.set_facing(1 if player.input.move.x > 0.0 else -1)
	player.facing_locked = true
	player.consume_attack()
	player.current_attack = _attack
	_speed = player.stats.value(&"attack_speed")
	_time = 0.0
	_hitbox_on = false
	_hitbox_done = false
	player.attack_hitbox.landed.connect(_on_landed)
	Events.player_attacked.emit(_attack)


func exit() -> void:
	player.attack_hitbox.deactivate()
	player.facing_locked = false
	if player.attack_hitbox.landed.is_connected(_on_landed):
		player.attack_hitbox.landed.disconnect(_on_landed)


func physics_update(delta: float) -> void:
	player.move(delta, _attack.move_control)
	player.apply_gravity(delta)
	_time += delta
	var startup: float = _attack.startup_time(_speed)
	if not _hitbox_on and not _hitbox_done and _time >= startup:
		_activate_hitbox()
	if _hitbox_on and _time >= startup + _attack.active_time(_speed):
		player.attack_hitbox.deactivate()
		_hitbox_on = false
		_hitbox_done = true
	if _time >= _attack.total_time(_speed):
		_finish()


func _activate_hitbox() -> void:
	var damage: int = roundi(_attack.damage * player.stats.value(&"attack_damage"))
	if _attack.damage > 0:
		damage = maxi(damage, 1)
	player.attack_hitbox.activate(_attack, player.facing, damage, player.stats.value(&"attack_reach"))
	_hitbox_on = true


func _finish() -> void:
	if not player.is_on_floor():
		machine.transition_to(&"Fall")
	elif player.input.move_x != 0.0:
		machine.transition_to(&"Run")
	else:
		machine.transition_to(&"Idle")


func _on_landed(_info: DamageInfo) -> void:
	if _attack.pogo_velocity > 0.0:
		player.velocity.y = -_attack.pogo_velocity
