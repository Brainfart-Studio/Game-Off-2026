class_name GameConfig
extends Resource
## Base for every config resource. Override `validate()` to return warnings.


## Returns a list of warnings. Empty means the config is valid.
func validate() -> PackedStringArray:
	return PackedStringArray()


## Runs `validate()` and pushes each warning with the resource path.
func check() -> void:
	for warning: String in validate():
		push_warning("%s: %s" % [resource_path, warning])
