extends Node2D

const WORLD_SIZE = Vector2(1080, 1920)
const ORIGIN_POSITION = Vector2(540, 1580)
const DESTINATION_POSITION = Vector2(540, 365)
const PIRATE_POSITION = Vector2(540, 1030)
const TREASURE_POSITION = Vector2(285, 790)
const STORM_POSITION = Vector2(790, 720)
const STORM_RADIUS = 132.0

var voyage = {}
var wave_time = 0.0
var region_name = "未知海域"
var origin_name = "启航港"
var destination_name = "目的港"

func configure(data):
	voyage = data.duplicate(true)
	var region_id = str(voyage.get("region", "mediterranean"))
	region_name = str(GameData.SEA_REGIONS.get(region_id, {"name": "未知海域"}).name)
	origin_name = str(GameData.TRADE_PORTS.get(str(voyage.get("origin", "")), {"name": "启航港"}).name)
	destination_name = str(GameData.TRADE_PORTS.get(str(voyage.get("destination", "")), {"name": "目的港"}).name)
	queue_redraw()

func _process(delta):
	wave_time += delta
	queue_redraw()

func is_navigable(point):
	var p = Vector2(point)
	if p.x < 52.0 or p.x > WORLD_SIZE.x - 52.0 or p.y < 300.0 or p.y > 1650.0:
		return false
	for reef in _reef_circles():
		if p.distance_to(reef.position) < float(reef.radius) + 42.0:
			return false
	return true

func _reef_circles():
	return [
		{"position": Vector2(180, 1260), "radius": 104.0},
		{"position": Vector2(860, 1280), "radius": 118.0},
		{"position": Vector2(190, 520), "radius": 112.0},
		{"position": Vector2(915, 430), "radius": 96.0}
	]

func _draw():
	_draw_ocean()
	_draw_currents()
	_draw_route()
	_draw_reefs()
	_draw_storm()
	_draw_harbor(ORIGIN_POSITION, false)
	_draw_harbor(DESTINATION_POSITION, true)

func _draw_ocean():
	draw_rect(Rect2(Vector2.ZERO, WORLD_SIZE), Color("082d42"))
	for band in range(12):
		var y = float(band) * 160.0
		var tint = Color(0.03, 0.28 + float(band % 3) * 0.015, 0.38, 0.15)
		draw_rect(Rect2(0, y, WORLD_SIZE.x, 160), tint)
	for row in range(20):
		var y = 55.0 + row * 91.0
		for column in range(10):
			var x = 28.0 + column * 116.0 + sin(wave_time * 1.1 + row * 0.8 + column) * 14.0
			draw_line(Vector2(x, y), Vector2(x + 54, y + sin(wave_time + column) * 3.0), Color(0.52, 0.92, 0.94, 0.20), 3.0)

func _draw_currents():
	for index in range(7):
		var y = 470.0 + index * 155.0
		var x = 430.0 + sin(wave_time * 0.45 + index) * 145.0
		draw_arc(Vector2(x, y), 45.0, 0.2, 2.7, 18, Color(0.20, 0.82, 0.79, 0.22), 5.0)
		draw_line(Vector2(x + 33, y + 29), Vector2(x + 52, y + 19), Color(0.20, 0.82, 0.79, 0.28), 5.0)

func _draw_route():
	var points = PackedVector2Array([
		ORIGIN_POSITION, Vector2(520, 1390), Vector2(590, 1210),
		Vector2(500, 1010), Vector2(445, 820), Vector2(530, 610), DESTINATION_POSITION
	])
	draw_polyline(points, Color(0.95, 0.78, 0.34, 0.20), 18.0, true)
	draw_polyline(points, Color(0.98, 0.86, 0.52, 0.68), 3.0, true)

func _draw_reefs():
	for reef in _reef_circles():
		var center = Vector2(reef.position)
		var radius = float(reef.radius)
		draw_circle(center, radius + 18.0, Color(0.28, 0.74, 0.71, 0.15))
		draw_circle(center, radius, Color("3b6257"))
		draw_circle(center + Vector2(-18, -14), radius * 0.72, Color("657c63"))
		for rock in range(5):
			var angle = float(rock) * TAU / 5.0
			var rock_pos = center + Vector2.from_angle(angle) * radius * 0.68
			draw_circle(rock_pos, 18.0 + float(rock % 2) * 7.0, Color("253f42"))

func _draw_storm():
	var pulse = 0.18 + (sin(wave_time * 2.0) + 1.0) * 0.04
	draw_circle(STORM_POSITION, STORM_RADIUS, Color(0.32, 0.37, 0.50, pulse))
	for ring in range(4):
		var radius = 42.0 + ring * 25.0
		draw_arc(STORM_POSITION + Vector2(sin(wave_time + ring) * 10.0, 0), radius, wave_time * 0.4 + ring, wave_time * 0.4 + ring + 4.5, 24, Color(0.70, 0.82, 0.88, 0.36), 5.0)
	for bolt in range(3):
		var x = STORM_POSITION.x - 55.0 + bolt * 54.0
		var y = STORM_POSITION.y - 46.0 + sin(wave_time * 4.0 + bolt) * 8.0
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
