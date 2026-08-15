extends Node2D

const DEFAULT_WORLD_SIZE = Vector2(5200, 4300)
const DEFAULT_ORIGIN_POSITION = Vector2(1320, 820)
const DEFAULT_DESTINATION_POSITION = Vector2(1820, 1120)
const DEFAULT_TREASURE_POSITION = Vector2(2100, 1700)
const DEFAULT_STORM_POSITION = Vector2(3100, 2550)
const DEFAULT_STORM_RADIUS = 145.0

const ZONE_AREAS = {
	"north_sea": {"center": Vector2(850, 470), "radius": Vector2(720, 420), "color": Color("38596c")},
	"mediterranean": {"center": Vector2(2050, 1400), "radius": Vector2(1450, 900), "color": Color("126078")},
	"atlantic": {"center": Vector2(850, 2350), "radius": Vector2(760, 1550), "color": Color("103f68")},
	"africa": {"center": Vector2(1700, 3250), "radius": Vector2(980, 920), "color": Color("176474")},
	"indian_ocean": {"center": Vector2(3150, 3150), "radius": Vector2(1650, 900), "color": Color("243f74")},
	"east_asia": {"center": Vector2(4450, 1550), "radius": Vector2(900, 1250), "color": Color("176c69")}
}

var voyage = {}
var wave_time = 0.0
var world_size = DEFAULT_WORLD_SIZE
var origin_position = DEFAULT_ORIGIN_POSITION
var destination_position = DEFAULT_DESTINATION_POSITION
var treasure_position = DEFAULT_TREASURE_POSITION
var storm_position = DEFAULT_STORM_POSITION
var storm_radius = DEFAULT_STORM_RADIUS
var unlocked_ports = []
var map_labels = []

func configure(data):
	voyage = data.duplicate(true)
	world_size = Vector2(float(voyage.get("world_width", DEFAULT_WORLD_SIZE.x)), float(voyage.get("world_height", DEFAULT_WORLD_SIZE.y)))
	origin_position = GameData.sea_port_position(str(voyage.get("origin", "venice_dock")))
	destination_position = GameData.sea_port_position(str(voyage.get("destination", "ragusa_dock")))
	treasure_position = Vector2(float(voyage.get("treasure_x", DEFAULT_TREASURE_POSITION.x)), float(voyage.get("treasure_y", DEFAULT_TREASURE_POSITION.y)))
	storm_position = Vector2(float(voyage.get("storm_x", DEFAULT_STORM_POSITION.x)), float(voyage.get("storm_y", DEFAULT_STORM_POSITION.y)))
	storm_radius = float(voyage.get("storm_radius", DEFAULT_STORM_RADIUS))
	unlocked_ports = Array(voyage.get("unlocked_ports", [str(voyage.get("origin", "venice_dock")), str(voyage.get("destination", "ragusa_dock"))]))
	_rebuild_map_labels()
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

func get_port_position(port_id):
	return GameData.sea_port_position(str(port_id))

func is_in_harbor_safe_zone(point, radius = 155.0):
	var p = Vector2(point)
	for port_id in unlocked_ports:
		if p.distance_to(GameData.sea_port_position(str(port_id))) <= float(radius):
			return true
	return false

func update_encounter_position(encounter_id, point):
	var encounters = Array(voyage.get("encounters", []))
	for index in range(encounters.size()):
		var encounter = Dictionary(encounters[index])
		if str(encounter.get("id", "")) == str(encounter_id):
			encounter.x = float(Vector2(point).x)
			encounter.y = float(Vector2(point).y)
			encounters[index] = encounter
			voyage.encounters = encounters
			queue_redraw()
			return

func _process(delta):
	wave_time += delta
	queue_redraw()

func is_navigable(point):
	var p = Vector2(point)
	if p.x < 65.0 or p.x > world_size.x - 65.0 or p.y < 65.0 or p.y > world_size.y - 65.0:
		return false
	# 港口内湾必须始终保留离港水道，避免地图调整后出生点落入礁区。
	if is_in_harbor_safe_zone(p, 120.0):
		return true
	for reef in _reef_circles():
		if p.distance_to(Vector2(reef.position)) < float(reef.radius) + 38.0:
			return false
	return true

func _reef_circles():
	return [
		{"position": Vector2(1050, 1280), "radius": 110.0},
		{"position": Vector2(2100, 820), "radius": 126.0},
		{"position": Vector2(3050, 1380), "radius": 118.0},
		{"position": Vector2(850, 2350), "radius": 138.0},
		{"position": Vector2(2050, 2750), "radius": 132.0},
		{"position": Vector2(3150, 3150), "radius": 148.0},
		{"position": Vector2(3800, 2600), "radius": 122.0},
		{"position": Vector2(4100, 930), "radius": 102.0},
		{"position": Vector2(4750, 2850), "radius": 112.0}
	]

func _rebuild_map_labels():
	for label in map_labels:
		if is_instance_valid(label):
			label.queue_free()
	map_labels = []
	for zone_id in ZONE_AREAS:
		var area = Dictionary(ZONE_AREAS[zone_id])
		var label = Label.new()
		label.text = str(GameData.SEA_REGIONS[zone_id].name)
		label.position = Vector2(area.center) - Vector2(150, 28)
		label.size = Vector2(300, 50)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", 26)
		label.add_theme_color_override("font_color", Color(0.88, 0.97, 0.95, 0.66))
		label.add_theme_color_override("font_shadow_color", Color(0.01, 0.04, 0.07, 0.9))
		label.add_theme_constant_override("shadow_offset_x", 2)
		label.add_theme_constant_override("shadow_offset_y", 2)
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(label)
		map_labels.append(label)

func _draw():
	draw_rect(Rect2(Vector2.ZERO, world_size), Color("072b43"))
	_draw_zone_waters()
	_draw_coasts()
	_draw_currents()
	_draw_shipping_lanes()
	_draw_threat_territories()
	_draw_reefs()
	_draw_storm()
	_draw_ports()

func _draw_zone_waters():
	for zone_id in ZONE_AREAS:
		var area = Dictionary(ZONE_AREAS[zone_id])
		var center = Vector2(area.center)
		var radius = Vector2(area.radius)
		var zone_color = Color(area.color)
		for ring in range(9, 0, -1):
			var ratio = float(ring) / 9.0
			draw_set_transform(center, 0.0, Vector2(radius.x / radius.y, 1.0))
			draw_circle(Vector2.ZERO, radius.y * ratio, Color(zone_color, 0.035 + (1.0 - ratio) * 0.018))
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	var rows = int(ceil(world_size.y / 105.0))
	var columns = int(ceil(world_size.x / 135.0))
	for row in range(rows):
		for column in range(columns):
			var y = 45.0 + row * 105.0
			var x = 30.0 + column * 135.0 + sin(wave_time * 0.8 + row + column) * 12.0
			draw_line(Vector2(x, y), Vector2(x + 54, y + sin(wave_time + column) * 3.0), Color(0.50, 0.90, 0.94, 0.14), 3.0)

func _draw_coasts():
	var west_land = PackedVector2Array([Vector2(0, 0), Vector2(650, 0), Vector2(720, 340), Vector2(980, 590), Vector2(1080, 980), Vector2(920, 1450), Vector2(1140, 2020), Vector2(940, 2750), Vector2(1280, 3560), Vector2(900, 4300), Vector2(0, 4300)])
	var east_land = PackedVector2Array([Vector2(5200, 0), Vector2(4480, 0), Vector2(4320, 520), Vector2(4580, 920), Vector2(4400, 1520), Vector2(4880, 1980), Vector2(4620, 2640), Vector2(5200, 2920)])
	draw_colored_polygon(west_land, Color("725f43"))
	draw_colored_polygon(east_land, Color("64704d"))
	draw_polyline(west_land, Color("dec98e"), 7.0)
	draw_polyline(east_land, Color("dec98e"), 7.0)

func _draw_currents():
	for index in range(30):
		var x = 420.0 + float((index * 337) % int(world_size.x - 780.0))
		var y = 410.0 + float((index * 521) % int(world_size.y - 760.0))
		draw_arc(Vector2(x, y), 48.0, 0.2, 2.8, 18, Color(0.20, 0.82, 0.79, 0.20), 5.0)

func _draw_shipping_lanes():
	var lane_pairs = [
		["amsterdam_dock", "venice_dock"], ["venice_dock", "ragusa_dock"],
		["venice_dock", "malta_dock"], ["malta_dock", "alexandria_dock"],
		["athens_dock", "alexandria_dock"], ["alexandria_dock", "cape_town_dock"],
		["cape_town_dock", "quanzhou_dock"], ["quanzhou_dock", "yangzhou_dock"],
		["quanzhou_dock", "amsterdam_dock"]
	]
	for pair in lane_pairs:
		if str(pair[0]) in unlocked_ports and str(pair[1]) in unlocked_ports:
			draw_dashed_line(GameData.sea_port_position(str(pair[0])), GameData.sea_port_position(str(pair[1])), Color(0.77, 0.91, 0.86, 0.22), 3.0, 18.0)
	draw_line(origin_position, destination_position, Color(0.98, 0.78, 0.30, 0.18), 18.0)
	draw_dashed_line(origin_position, destination_position, Color(0.99, 0.87, 0.51, 0.72), 4.0, 22.0)

func _draw_threat_territories():
	for encounter in Array(voyage.get("encounters", [])):
		if bool(encounter.get("defeated", false)):
			continue
		var center = Vector2(float(encounter.get("x", 540.0)), float(encounter.get("y", 900.0)))
		var danger_color = Color("d45f67") if str(encounter.get("kind", "monster")) == "pirate" else Color("bb76d6")
		var alert_radius = 380.0 if str(encounter.get("kind", "monster")) == "pirate" else 330.0
		draw_circle(center, alert_radius, Color(danger_color, 0.022))
		draw_arc(center, alert_radius, 0.0, TAU, 48, Color(danger_color, 0.16), 3.0)
		draw_circle(center, 112.0, Color(danger_color, 0.08))
		draw_arc(center, 112.0, 0.0, TAU, 32, Color(danger_color, 0.34), 4.0)

func _draw_reefs():
	for reef in _reef_circles():
		var center = Vector2(reef.position)
		var radius = float(reef.radius)
		draw_circle(center, radius + 16.0, Color(0.28, 0.74, 0.71, 0.14))
		draw_circle(center, radius, Color("3b6257"))
		for rock in range(6):
			var rock_pos = center + Vector2.from_angle(float(rock) * TAU / 6.0) * radius * 0.65
			draw_circle(rock_pos, 16.0 + float(rock % 2) * 6.0, Color("253f42"))

func _draw_storm():
	var pulse = 0.18 + (sin(wave_time * 2.0) + 1.0) * 0.04
	draw_circle(storm_position, storm_radius, Color(0.32, 0.37, 0.50, pulse))
	for ring in range(4):
		draw_arc(storm_position, 45.0 + ring * 27.0, wave_time * 0.35 + ring, wave_time * 0.35 + ring + 4.6, 24, Color(0.70, 0.82, 0.88, 0.36), 5.0)

func _draw_ports():
	for port_id in unlocked_ports:
		var position = GameData.sea_port_position(str(port_id))
		var is_target = str(port_id) == str(voyage.get("destination", ""))
		draw_circle(position, 68.0 if is_target else 48.0, Color(0.98, 0.79, 0.35, 0.12 if is_target else 0.07))
		draw_arc(position, 68.0 if is_target else 48.0, 0.0, TAU, 30, Color(0.98, 0.79, 0.35, 0.74 if is_target else 0.42), 5.0)
		draw_rect(Rect2(position - Vector2(13, 13), Vector2(26, 26)), Color("a97145"))
