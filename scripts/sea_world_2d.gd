extends Node2D

const DEFAULT_WORLD_SIZE = Vector2(1080, 1920)
const DEFAULT_ORIGIN_POSITION = Vector2(540, 1580)
const DEFAULT_DESTINATION_POSITION = Vector2(540, 365)
const DEFAULT_TREASURE_POSITION = Vector2(285, 790)
const DEFAULT_STORM_POSITION = Vector2(790, 720)
const DEFAULT_STORM_RADIUS = 132.0

const ZONE_COLORS = {
	"mediterranean": Color("126078"),
	"north_sea": Color("38596c"),
	"atlantic": Color("103f68"),
	"africa": Color("176474"),
	"indian_ocean": Color("243f74"),
	"east_asia": Color("176c69")
}

var voyage = {}
var wave_time = 0.0
var region_name = "未知海域"
var origin_name = "启航港"
var destination_name = "目的港"
var world_size = DEFAULT_WORLD_SIZE
var origin_position = DEFAULT_ORIGIN_POSITION
var destination_position = DEFAULT_DESTINATION_POSITION
var treasure_position = DEFAULT_TREASURE_POSITION
var storm_position = DEFAULT_STORM_POSITION
var storm_radius = DEFAULT_STORM_RADIUS
var route_distance_nm = 1000
var zone_ids = ["mediterranean"]
var zone_labels = []

func configure(data):
	voyage = data.duplicate(true)
	route_distance_nm = max(1, int(voyage.get("distance_nm", 1000)))
	world_size = Vector2(float(voyage.get("world_width", GameData.SEA_WORLD_WIDTH)), float(voyage.get("world_height", GameData.sea_world_height(route_distance_nm))))
	origin_position = Vector2(float(voyage.get("origin_x", world_size.x * 0.5)), float(voyage.get("origin_y", world_size.y - GameData.SEA_WORLD_MARGIN)))
	destination_position = Vector2(float(voyage.get("destination_x", world_size.x * 0.5)), float(voyage.get("destination_y", GameData.SEA_WORLD_MARGIN)))
	treasure_position = Vector2(float(voyage.get("treasure_x", GameData.sea_route_position(route_distance_nm, 0.38, -245.0).x)), float(voyage.get("treasure_y", GameData.sea_route_position(route_distance_nm, 0.38, -245.0).y)))
	storm_position = Vector2(float(voyage.get("storm_x", GameData.sea_route_position(route_distance_nm, 0.62, 235.0).x)), float(voyage.get("storm_y", GameData.sea_route_position(route_distance_nm, 0.62, 235.0).y)))
	storm_radius = float(voyage.get("storm_radius", DEFAULT_STORM_RADIUS))
	zone_ids = Array(voyage.get("zone_ids", ["mediterranean"]))
	if zone_ids.is_empty():
		zone_ids = ["mediterranean"]
	var region_id = str(voyage.get("region", "mediterranean"))
	region_name = str(GameData.SEA_REGIONS.get(region_id, {"name": "未知海域"}).name)
	origin_name = str(GameData.TRADE_PORTS.get(str(voyage.get("origin", "")), {"name": "启航港"}).name)
	destination_name = str(GameData.TRADE_PORTS.get(str(voyage.get("destination", "")), {"name": "目的港"}).name)
	_rebuild_zone_labels()
	queue_redraw()

func get_world_size():
	return world_size

func get_origin_position():
	return origin_position

func get_destination_position():
	return destination_position

func get_treasure_position():
	return treasure_position

func get_storm_position():
	return storm_position

func get_storm_radius():
	return storm_radius

func _process(delta):
	wave_time += delta
	queue_redraw()

func is_navigable(point):
	var p = Vector2(point)
	if p.x < 52.0 or p.x > world_size.x - 52.0 or p.y < destination_position.y - 65.0 or p.y > origin_position.y + 90.0:
		return false
	for reef in _reef_circles():
		if p.distance_to(Vector2(reef.position)) < float(reef.radius) + 42.0:
			return false
	return true

func _reef_circles():
	var reefs = []
	var reef_specs = [
		{"progress": 0.18, "x": 170.0, "radius": 104.0},
		{"progress": 0.31, "x": 895.0, "radius": 116.0},
		{"progress": 0.48, "x": 175.0, "radius": 108.0},
		{"progress": 0.72, "x": 905.0, "radius": 102.0},
		{"progress": 0.86, "x": 190.0, "radius": 94.0}
	]
	for reef in reef_specs:
		var center = GameData.sea_route_position(route_distance_nm, float(reef.progress))
		reefs.append({"position": Vector2(float(reef.x), center.y), "radius": float(reef.radius)})
	return reefs

func _rebuild_zone_labels():
	for label in zone_labels:
		if is_instance_valid(label):
			label.queue_free()
	zone_labels = []
	var count = max(1, zone_ids.size())
	for index in range(count):
		var zone_id = str(zone_ids[index])
		var progress = (float(index) + 0.5) / float(count)
		var label = Label.new()
		label.text = "%s · %d—%d海里" % [str(GameData.SEA_REGIONS.get(zone_id, {"name": "未知海域"}).name), int(round(route_distance_nm * float(index) / count)), int(round(route_distance_nm * float(index + 1) / count))]
		label.position = GameData.sea_route_position(route_distance_nm, progress, 0.0) + Vector2(-210, -34)
		label.size = Vector2(420, 45)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", 23)
		label.add_theme_color_override("font_color", Color(0.91, 0.98, 0.96, 0.78))
		label.add_theme_color_override("font_shadow_color", Color(0.01, 0.04, 0.07, 0.92))
		label.add_theme_constant_override("shadow_offset_x", 2)
		label.add_theme_constant_override("shadow_offset_y", 2)
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(label)
		zone_labels.append(label)

func _draw():
	_draw_ocean()
	_draw_zone_boundaries()
	_draw_currents()
	_draw_route()
	_draw_threat_territories()
	_draw_reefs()
	_draw_storm()
	_draw_harbor(origin_position, false)
	_draw_harbor(destination_position, true)

func _draw_ocean():
	draw_rect(Rect2(Vector2.ZERO, world_size), Color("082d42"))
	var count = max(1, zone_ids.size())
	for index in range(count):
		var start_progress = float(index) / float(count)
		var end_progress = float(index + 1) / float(count)
		var bottom_y = GameData.sea_route_position(route_distance_nm, start_progress).y
		var top_y = GameData.sea_route_position(route_distance_nm, end_progress).y
		var zone_color = Color(ZONE_COLORS.get(str(zone_ids[index]), Color("126078")))
		draw_rect(Rect2(0, top_y, world_size.x, bottom_y - top_y), zone_color)
		draw_rect(Rect2(0, top_y, world_size.x, bottom_y - top_y), Color(0.01, 0.08, 0.13, 0.20))
	var rows = int(ceil(world_size.y / 91.0))
	for row in range(rows):
		var y = 45.0 + row * 91.0
		for column in range(10):
			var x = 28.0 + column * 116.0 + sin(wave_time * 1.1 + row * 0.8 + column) * 14.0
			draw_line(Vector2(x, y), Vector2(x + 54, y + sin(wave_time + column) * 3.0), Color(0.52, 0.92, 0.94, 0.18), 3.0)

func _draw_zone_boundaries():
	var count = max(1, zone_ids.size())
	for index in range(1, count):
		var y = GameData.sea_route_position(route_distance_nm, float(index) / float(count)).y
		draw_line(Vector2(55, y), Vector2(world_size.x - 55, y), Color(0.78, 0.95, 0.91, 0.32), 3.0)
		for marker_x in range(75, int(world_size.x - 60), 90):
			draw_circle(Vector2(marker_x, y), 4.0, Color(0.95, 0.79, 0.35, 0.62))

func _draw_currents():
	var count = max(6, int(route_distance_nm / 650))
	for index in range(count):
		var progress = (float(index) + 0.5) / float(count)
		var route_point = GameData.sea_route_position(route_distance_nm, progress)
		var x = route_point.x + sin(wave_time * 0.45 + index) * 145.0
		draw_arc(Vector2(x, route_point.y), 45.0, 0.2, 2.7, 18, Color(0.20, 0.82, 0.79, 0.20), 5.0)
		draw_line(Vector2(x + 33, route_point.y + 29), Vector2(x + 52, route_point.y + 19), Color(0.20, 0.82, 0.79, 0.26), 5.0)

func _draw_route():
	var points = PackedVector2Array()
	var samples = max(10, int(route_distance_nm / 420))
	for index in range(samples + 1):
		points.append(GameData.sea_route_position(route_distance_nm, float(index) / float(samples)))
	draw_polyline(points, Color(0.95, 0.78, 0.34, 0.18), 18.0, true)
	draw_polyline(points, Color(0.98, 0.86, 0.52, 0.66), 3.0, true)
	for index in range(1, samples):
		if index % 2 == 0:
			draw_circle(points[index], 5.0, Color(0.99, 0.86, 0.49, 0.72))

func _draw_threat_territories():
	for encounter in Array(voyage.get("encounters", [])):
		if bool(encounter.get("defeated", false)):
			continue
		var center = Vector2(float(encounter.get("x", 540.0)), float(encounter.get("y", 900.0)))
		var zone_id = str(encounter.get("zone_id", "mediterranean"))
		var danger_color = Color("d45f67") if str(encounter.get("kind", "monster")) == "pirate" else Color("bb76d6")
		draw_circle(center, 118.0, Color(danger_color, 0.08))
		draw_arc(center, 118.0, 0.0, TAU, 32, Color(danger_color, 0.34), 4.0)
		var zone_tint = Color(ZONE_COLORS.get(zone_id, Color("126078")))
		draw_arc(center, 132.0, -0.9, 0.9, 20, Color(zone_tint.lightened(0.35), 0.55), 3.0)

func _draw_reefs():
	for reef in _reef_circles():
		var center = Vector2(reef.position)
		var radius = float(reef.radius)
		draw_circle(center, radius + 18.0, Color(0.28, 0.74, 0.71, 0.14))
		draw_circle(center, radius, Color("3b6257"))
		draw_circle(center + Vector2(-18, -14), radius * 0.72, Color("657c63"))
		for rock in range(5):
			var angle = float(rock) * TAU / 5.0
			var rock_pos = center + Vector2.from_angle(angle) * radius * 0.68
			draw_circle(rock_pos, 18.0 + float(rock % 2) * 7.0, Color("253f42"))

func _draw_storm():
	var pulse = 0.18 + (sin(wave_time * 2.0) + 1.0) * 0.04
	draw_circle(storm_position, storm_radius, Color(0.32, 0.37, 0.50, pulse))
	for ring in range(4):
		var radius = 42.0 + ring * 25.0
		draw_arc(storm_position + Vector2(sin(wave_time + ring) * 10.0, 0), radius, wave_time * 0.4 + ring, wave_time * 0.4 + ring + 4.5, 24, Color(0.70, 0.82, 0.88, 0.36), 5.0)
	for bolt in range(3):
		var x = storm_position.x - 55.0 + bolt * 54.0
		var y = storm_position.y - 46.0 + sin(wave_time * 4.0 + bolt) * 8.0
		draw_polyline(PackedVector2Array([Vector2(x, y), Vector2(x + 13, y + 25), Vector2(x - 2, y + 24), Vector2(x + 15, y + 53)]), Color(0.96, 0.88, 0.45, 0.64), 4.0)

func _draw_harbor(position, destination):
	var land_color = Color("9a8059") if destination else Color("78694e")
	var coast = PackedVector2Array([
		position + Vector2(-230, -62), position + Vector2(230, -62),
		position + Vector2(285, 92), position + Vector2(-285, 92)
	])
	draw_colored_polygon(coast, land_color)
	draw_line(position + Vector2(-230, -62), position + Vector2(230, -62), Color("e0c58a"), 7.0)
	for pier in [-92.0, 0.0, 92.0]:
		draw_rect(Rect2(position + Vector2(pier - 17, -58), Vector2(34, 112)), Color("6e4932"))
		for plank in range(4):
			draw_line(position + Vector2(pier - 15, -35 + plank * 23), position + Vector2(pier + 15, -35 + plank * 23), Color("a16e46"), 3.0)
	if destination:
		draw_circle(position + Vector2(0, 15), 75.0, Color(0.98, 0.79, 0.35, 0.10))
		draw_arc(position + Vector2(0, 15), 74.0, 0.0, TAU, 42, Color(0.98, 0.79, 0.35, 0.62), 5.0)
