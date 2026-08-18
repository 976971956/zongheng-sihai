extends SceneTree

# 8 行航向 × 8 列动画，每格 128px。地图上约显示为 128 个逻辑像素，
# 在手机竖屏中足够清楚，同时比九张 2048px 图集显著节省首包体积。
const DIRECTION_COUNT = 8
const FRAME_COUNT = 8
const CELL_SIZE = 128
const OUTPUT_SIZE = CELL_SIZE * FRAME_COUNT
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
const DIRECTION_SOURCES = [
	{"name": "down", "sheet": "cardinal", "cell": Vector2i(0, 0)},
	{"name": "down_right", "sheet": "diagonal", "cell": Vector2i(0, 0)},
	{"name": "right", "sheet": "cardinal", "cell": Vector2i(1, 1)},
	{"name": "up_right", "sheet": "diagonal", "cell": Vector2i(1, 1)},
	{"name": "up", "sheet": "cardinal", "cell": Vector2i(0, 1)},
	{"name": "up_left", "sheet": "diagonal", "cell": Vector2i(0, 1)},
	{"name": "left", "sheet": "cardinal", "cell": Vector2i(1, 0)},
	{"name": "down_left", "sheet": "diagonal", "cell": Vector2i(1, 0)}
]
const FRAME_OFFSET_X = [0, 1, 1, 0, 0, -1, -1, 0]
const FRAME_OFFSET_Y = [1, 0, -1, -2, -1, 0, 1, 2]
const FRAME_SCALE_X = [1.0, 1.008, 1.014, 1.008, 1.0, 0.992, 0.986, 0.992]
const FRAME_SCALE_Y = [1.0, 0.995, 0.990, 0.995, 1.0, 1.005, 1.010, 1.005]

func _init():
	call_deferred("_build_all")

func _build_all():
	var failed = false
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))
	for ship_id in SHIP_IDS:
		var cardinal_path = "%s/%s_directions_source_v1.png" % [SOURCE_DIR, ship_id]
		var diagonal_path = "%s/%s_diagonals_source_v2.png" % [SOURCE_DIR, ship_id]
		var output_path = "%s/%s_directions_8x8_v2.png" % [OUTPUT_DIR, ship_id]
		var cardinal = Image.load_from_file(cardinal_path)
		var diagonal = Image.load_from_file(diagonal_path)
		if cardinal == null or cardinal.is_empty() or diagonal == null or diagonal.is_empty():
			push_error("无法读取八向船只源图：%s / %s" % [cardinal_path, diagonal_path])
			failed = true
			continue
		cardinal.convert(Image.FORMAT_RGBA8)
		diagonal.convert(Image.FORMAT_RGBA8)
		_remove_connected_neutral_background(cardinal)
		_remove_connected_neutral_background(diagonal)
		var atlas = Image.create(OUTPUT_SIZE, OUTPUT_SIZE, false, Image.FORMAT_RGBA8)
		atlas.fill(Color.TRANSPARENT)
		for direction_index in range(DIRECTION_COUNT):
			var source_data = Dictionary(DIRECTION_SOURCES[direction_index])
			var source_image = diagonal if str(source_data.sheet) == "diagonal" else cardinal
			var source_cell = Vector2i(source_data.cell)
			var source_cell_size = Vector2i(source_image.get_width() / 2, source_image.get_height() / 2)
			var source_region = Rect2i(source_cell * source_cell_size, source_cell_size)
			var base_frame = source_image.get_region(source_region)
			base_frame.resize(CELL_SIZE, CELL_SIZE, Image.INTERPOLATE_LANCZOS)
			for frame_index in range(FRAME_COUNT):
				_blit_animation_frame(atlas, base_frame, direction_index, frame_index)
		var save_error = atlas.save_png(output_path)
		if save_error != OK:
			push_error("无法保存8×8船只图集：%s" % output_path)
			failed = true
			continue
		print("SHIP_8X8_BUILT: %s -> %s" % [ship_id, output_path])
	quit(1 if failed else 0)

func _blit_animation_frame(atlas, base_frame, direction_index, frame_index):
	var frame = base_frame.duplicate()
	var cell_frame = Image.create(CELL_SIZE, CELL_SIZE, false, Image.FORMAT_RGBA8)
	cell_frame.fill(Color.TRANSPARENT)
	var frame_width = int(round(CELL_SIZE * float(FRAME_SCALE_X[frame_index])))
	var frame_height = int(round(CELL_SIZE * float(FRAME_SCALE_Y[frame_index])))
	frame.resize(frame_width, frame_height, Image.INTERPOLATE_LANCZOS)
	var cell_origin = Vector2i(frame_index * CELL_SIZE, direction_index * CELL_SIZE)
	var center_offset = Vector2i(
		int(floor(float(CELL_SIZE - frame_width) * 0.5)) + int(FRAME_OFFSET_X[frame_index]),
		int(floor(float(CELL_SIZE - frame_height) * 0.5)) + int(FRAME_OFFSET_Y[frame_index])
	)
	cell_frame.blend_rect(frame, Rect2i(Vector2i.ZERO, frame.get_size()), center_offset)
	atlas.blend_rect(cell_frame, Rect2i(Vector2i.ZERO, cell_frame.get_size()), cell_origin)

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
