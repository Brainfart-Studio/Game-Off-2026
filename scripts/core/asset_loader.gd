@tool
class_name AssetLoader
extends RefCounted
## Static asset helpers with labeled fallbacks. Not an autoload.

static var _fallbacks: Dictionary[String, Texture2D] = {}
static var _fallback_set: Dictionary[Texture2D, bool] = {}


## Loads the texture at `path`, or a cached colored box of `size` (stable color per `id`).
static func texture(path: String, size: Vector2i, id: String) -> Texture2D:
	if ResourceLoader.exists(path):
		var loaded: Texture2D = load(path) as Texture2D
		if loaded != null:
			return loaded
	return _fallback(size, id)


static func is_fallback(tex: Texture2D) -> bool:
	return tex != null and _fallback_set.has(tex)


## Builds SpriteFrames from strip definitions. A missing file gives one fallback frame.
static func sprite_frames(defs: Array[AnimationDef]) -> SpriteFrames:
	var result: SpriteFrames = SpriteFrames.new()
	result.remove_animation(&"default")
	for def: AnimationDef in defs:
		result.add_animation(def.id)
		result.set_animation_speed(def.id, def.fps)
		result.set_animation_loop(def.id, def.loop)
		if ResourceLoader.exists(def.path):
			var strip: Texture2D = load(def.path) as Texture2D
			if strip != null:
				for i: int in maxi(def.frames, 1):
					var atlas: AtlasTexture = AtlasTexture.new()
					atlas.atlas = strip
					atlas.region = Rect2(
						Vector2(def.frame_size.x * i, 0), Vector2(def.frame_size)
					)
					result.add_frame(def.id, atlas)
				continue
		result.add_frame(def.id, _fallback(def.frame_size, String(def.id)))
	return result


## Loads a sound, or null if missing. If `<name>_2`, `_3`... exist beside it, picks one at random.
static func sound(path: String) -> AudioStream:
	var options: Array[String] = []
	if ResourceLoader.exists(path):
		options.append(path)
	var base: String = path.get_basename()
	var ext: String = path.get_extension()
	var n: int = 2
	while ResourceLoader.exists("%s_%d.%s" % [base, n, ext]):
		options.append("%s_%d.%s" % [base, n, ext])
		n += 1
	if options.is_empty():
		return null
	return load(options.pick_random()) as AudioStream


## Loads the font at `path`, or null if missing.
static func font(path: String) -> Font:
	if ResourceLoader.exists(path):
		return load(path) as Font
	return null


static func _fallback(size: Vector2i, id: String) -> Texture2D:
	var key: String = "%s|%d|%d" % [id, size.x, size.y]
	if _fallbacks.has(key):
		return _fallbacks[key]
	var hue: float = float(id.hash() % 360) / 360.0
	var fill: Color = Color.from_hsv(hue, 0.5, 0.85)
	var outline: Color = fill.darkened(0.4)
	var image: Image = Image.create(size.x, size.y, false, Image.FORMAT_RGBA8)
	image.fill(fill)
	for x: int in size.x:
		image.set_pixel(x, 0, outline)
		image.set_pixel(x, size.y - 1, outline)
	for y: int in size.y:
		image.set_pixel(0, y, outline)
		image.set_pixel(size.x - 1, y, outline)
	var tex: ImageTexture = ImageTexture.create_from_image(image)
	_fallbacks[key] = tex
	_fallback_set[tex] = true
	return tex
