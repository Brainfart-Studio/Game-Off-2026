extends Node
## Local save (autoload `Save`).
##
## Keeps the top 10 high scores and the last initials typed in `user://save.cfg`.
## A missing or unreadable file is an empty save.

const MAX_SCORES := 10
const SECTION_SCORES := "high_scores"
const KEY_ENTRIES := "entries"
const SECTION_PLAYER := "player"
const KEY_LAST_INITIALS := "last_initials"
const DEFAULT_INITIALS := "AAA"
const INITIALS_LENGTH := 3

## Where the save is stored. Tests point it at a throwaway file.
var path: String = "user://save.cfg"

var _file: ConfigFile = ConfigFile.new()


func _ready() -> void:
	load_file()


## Reads the save from `path`. A missing file gives an empty save.
func load_file() -> void:
	_file = ConfigFile.new()
	_file.load(path)


## The saved scores as `{"initials": String, "score": int}`, highest first.
func high_scores() -> Array[Dictionary]:
	var entries: Array[Dictionary] = []
	var raw: Variant = _file.get_value(SECTION_SCORES, KEY_ENTRIES, [])
	if not raw is Array:
		return entries
	for item: Variant in raw:
		if not item is Dictionary:
			continue
		var entry: Dictionary = item as Dictionary
		if not entry.has("initials") or not entry.has("score"):
			continue
		entries.append({"initials": String(entry["initials"]), "score": int(entry["score"])})
	return entries


## True when `score` is above 0 and would make the top 10.
func qualifies(score: int) -> bool:
	if score <= 0:
		return false
	var entries: Array[Dictionary] = high_scores()
	if entries.size() < MAX_SCORES:
		return true
	return score > int(entries[entries.size() - 1]["score"])


## Adds a score, keeps the best 10, saves, and remembers the initials.
## Returns the 0-based rank of the new entry, or -1 when it did not make the list.
func add_high_score(initials: String, score: int) -> int:
	var clean: String = _clean_initials(initials)
	var entries: Array[Dictionary] = high_scores()
	var rank: int = entries.size()
	for i: int in entries.size():
		if score > int(entries[i]["score"]):
			rank = i
			break
	entries.insert(rank, {"initials": clean, "score": score})
	if entries.size() > MAX_SCORES:
		entries.resize(MAX_SCORES)
	_file.set_value(SECTION_SCORES, KEY_ENTRIES, entries)
	_file.set_value(SECTION_PLAYER, KEY_LAST_INITIALS, clean)
	_file.save(path)
	if rank >= MAX_SCORES:
		return -1
	return rank


## The initials typed last, or "AAA" when none were saved.
func last_initials() -> String:
	var saved: String = String(_file.get_value(SECTION_PLAYER, KEY_LAST_INITIALS, DEFAULT_INITIALS))
	if saved.is_empty():
		return DEFAULT_INITIALS
	return saved


func _clean_initials(initials: String) -> String:
	var clean: String = initials.strip_edges().to_upper().substr(0, INITIALS_LENGTH)
	if clean.is_empty():
		return DEFAULT_INITIALS
	return clean
