class_name Layers
## Physics layer bit values (R-053). `.tscn` files keep numbers; scripts use these.
## Order and names match `layer_names/2d_physics` in project.godot.

const WORLD := 1 << 0
const PLAYER := 1 << 1
const ENEMY := 1 << 2
const PLAYER_HITBOX := 1 << 3
const PLAYER_HURTBOX := 1 << 4
const ENEMY_HITBOX := 1 << 5
const ENEMY_HURTBOX := 1 << 6
const PICKUP := 1 << 7

## Layer names in layer order (index i is layer i + 1).
const NAMES: Array[StringName] = [
	&"world",
	&"player",
	&"enemy",
	&"player_hitbox",
	&"player_hurtbox",
	&"enemy_hitbox",
	&"enemy_hurtbox",
	&"pickup",
]
