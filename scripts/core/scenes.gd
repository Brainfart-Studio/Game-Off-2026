class_name Scenes
extends RefCounted
## Scene paths and the one way to change scene. Tests turn changes off and read `last_request`.

const TITLE := "res://scenes/title.tscn"
const RUN := "res://scenes/run.tscn"

static var changes_enabled: bool = true
static var last_request: String = ""


static func change(tree: SceneTree, path: String) -> void:
	last_request = path
	if not changes_enabled:
		return
	tree.paused = false
	tree.change_scene_to_file(path)
