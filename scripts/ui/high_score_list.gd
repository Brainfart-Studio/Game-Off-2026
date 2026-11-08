class_name HighScoreList
extends VBoxContainer
## The saved high scores, one row each. The row passed as `highlight` stands out.

const ROW_FORMAT := "%2d. %s %7d"
const EMPTY_ROW := "-"

@export var config: UiConfig


## Fills the list from `entries` (highest first). `highlight` is the 0-based row to mark, or -1.
## An empty list shows a row of "-" for each place on the table.
func show_scores(entries: Array[Dictionary], highlight: int = -1) -> void:
	if config == null:
		config = UiConfig.new()
	for child: Node in get_children():
		remove_child(child)
		child.queue_free()
	if entries.is_empty():
		for i: int in Save.MAX_SCORES:
			_add_row(EMPTY_ROW, config.dim_color)
		return
	for i: int in entries.size():
		var entry: Dictionary = entries[i]
		var color: Color = config.highlight_color if i == highlight else config.text_color
		_add_row(ROW_FORMAT % [i + 1, entry["initials"], entry["score"]], color)


func _add_row(text: String, color: Color) -> void:
	var label: Label = Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_color_override(&"font_color", color)
	add_child(label)
