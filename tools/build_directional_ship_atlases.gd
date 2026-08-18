extends SceneTree

# 每个方向最终为 256×256：在竖屏地图中显示为约 128px，足以覆盖 Retina
# 清晰度，同时避免九艘船的 Web 首包被 1024px 工作原稿无谓放大。
const OUTPUT_SIZE = 512
const SOURCE_DIR = "res://assets/art/ships/source_directional"
const OUTPUT_DIR = "res://assets/art/ships/directional"
const SHIP_IDS = [
	"sea_swallow",
	"adriatic_cog",
	"alex_caravel",
	"malta_galley",
	"cape_carrack",
	"quanzhou_junk",
	"athens_trireme",
	"yangzhou_treasure",
	"amsterdam_clipper"
]

func _init():
	call_deferred("_build_all")

func _build_all():
	var failed = false
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))
	for ship_id in SHIP_IDS:
		var source_path = "%s/%s_directions_source_v1.png" % [SOURCE_DIR, ship_id]
		var output_path = "%s/%s_directions_v1.png" % [OUTPUT_DIR, ship_id]
		var image = Image.load_from_file(source_path)
		if image == null or image.is_empty():
			push_error("无法读取四向船只源图：%s" % source_path)
			failed = true
			continue
		image.convert(Image.FORMAT_RGBA8)
		_remove_connected_neutral_background(image)
		image.resize(OUTPUT_SIZE, OUTPUT_SIZE, Image.INTERPOLATE_LANCZOS)
		var save_error = image.save_png(output_path)
		if save_error != OK:
			push_error("无法保存四向船只图集：%s" % output_path)
			failed = true
			continue
		print("SHIP_DIRECTIONS_BUILT: %s -> %s" % [ship_id, output_path])
	quit(1 if failed else 0)

func _remove_connected_neutral_background(image):
	var width = image.get_width()
	var height = image.get_height()
	var visited = PackedByteArray()
	visited.resize(width * height)
	var queue = PackedInt32Array()
	for x in range(width):
		_enqueue_background_pixel(image, x, 0, width, visited, queue)
		_enqueue_background_pixel(image, x, height - 1, width, visited, queue)
	for y in range(1, height - 1):
		_enqueue_background_pixel(image, 0, y, width, visited, queue)
		_enqueue_background_pixel(image, width - 1, y, width, visited, queue)
	var head = 0
	while head < queue.size():
		var index = int(queue[head])
		head += 1
		var x = index % width
		var y = int(index / width)
		var pixel = image.get_pixel(x, y)
		pixel.a = 0.0
		image.set_pixel(x, y, pixel)
		_enqueue_background_pixel(image, x - 1, y, width, visited, queue)
		_enqueue_background_pixel(image, x + 1, y, width, visited, queue)
		_enqueue_background_pixel(image, x, y - 1, width, visited, queue)
		_enqueue_background_pixel(image, x, y + 1, width, visited, queue)

func _enqueue_background_pixel(image, x, y, width, visited, queue):
	if x < 0 or y < 0 or x >= width or y >= image.get_height():
		return
	var index = y * width + x
	if visited[index] != 0:
		return
	if not _is_neutral_background(image.get_pixel(x, y)):
		return
	visited[index] = 1
	queue.append(index)

func _is_neutral_background(pixel):
	var brightest = max(pixel.r, max(pixel.g, pixel.b))
	var darkest = min(pixel.r, min(pixel.g, pixel.b))
	return brightest >= 0.78 and brightest - darkest <= 0.085
