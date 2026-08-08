extends Node2D

const CITY_ART = preload("res://assets/art/maps/venice_city_v2.png")
const FIELD_ART = preload("res://assets/art/maps/venice_field_v2.png")
const DUNGEON_ART = preload("res://assets/art/maps/training_dungeon_v2.png")
const BASE_MAP_SIZE = Vector2(720, 1280)
const WORLD_SCALE = 1.5
const WORLD_SIZE = BASE_MAP_SIZE * WORLD_SCALE

var wave_time = 0.0
var region_mode = "city"

func set_region(value):
	region_mode = value
	queue_redraw()

func _process(delta):
	wave_time += delta
	queue_redraw()

func _draw():
	var texture = CITY_ART
	if region_mode == "field":
		texture = FIELD_ART
	elif region_mode in ["dungeon", "black_sail"]:
		texture = DUNGEON_ART
	draw_texture_rect(texture, Rect2(Vector2.ZERO, WORLD_SIZE), false)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE * WORLD_SCALE)
	_draw_art_overlays()
	draw_set_transform(Vector2.ZERO)

func _draw_art_overlays():
	# Soft edge shading keeps the detailed art readable under portrait HUD controls.
	draw_rect(Rect2(0, 0, 720, 205), Color(0.015, 0.035, 0.045, 0.16))
	draw_rect(Rect2(0, 1080, 720, 200), Color(0.01, 0.025, 0.035, 0.34))
	if region_mode == "city":
		for row in range(4):
			var y = 1120.0 + row * 38.0
			for column in range(7):
				var x = 18.0 + column * 110.0 + sin(wave_time * 1.2 + row + column) * 8.0
				draw_line(Vector2(x, y), Vector2(x + 48, y), Color(0.62, 0.94, 0.95, 0.22), 2)
	elif region_mode == "field":
		# A faint living mist identifies the haunted grove without obscuring paths.
		for index in range(5):
			var drift = sin(wave_time * 0.55 + index) * 14.0
			draw_circle(Vector2(535 + drift + index * 32, 700 + index * 24), 34, Color(0.42, 0.86, 0.82, 0.035))
	elif region_mode == "dungeon":
		# Firelight pulse ties the four training chambers together.
		var pulse = 0.025 + (sin(wave_time * 2.4) + 1.0) * 0.012
		draw_circle(Vector2(360, 170), 118, Color(0.95, 0.25, 0.12, pulse))
	else:
		# The corsair stronghold reuses the stone layout but has its own ominous
		# lighting, torn sails and crossed-cutlass insignia.
		draw_rect(Rect2(0, 0, 720, 1280), Color(0.16, 0.015, 0.028, 0.26))
		var pulse = 0.05 + (sin(wave_time * 2.0) + 1.0) * 0.02
		draw_circle(Vector2(360, 170), 135, Color(0.72, 0.03, 0.08, pulse))
		for side_x in [42.0, 618.0]:
			for banner_y in [255.0, 655.0]:
				draw_polygon(PackedVector2Array([
					Vector2(side_x, banner_y), Vector2(side_x + 60, banner_y + 8),
					Vector2(side_x + 52, banner_y + 105), Vector2(side_x + 30, banner_y + 88),
					Vector2(side_x + 8, banner_y + 105)
				]), PackedColorArray([Color(0.035, 0.025, 0.035, 0.88)]))
			draw_line(Vector2(side_x + 16, 275), Vector2(side_x + 50, 315), Color(0.68, 0.09, 0.11, 0.8), 5)
			draw_line(Vector2(side_x + 50, 275), Vector2(side_x + 16, 315), Color(0.68, 0.09, 0.11, 0.8), 5)
		# A black sail crest crowns the captain's floor.
		draw_polygon(PackedVector2Array([
			Vector2(325, 82), Vector2(325, 172), Vector2(405, 154), Vector2(350, 118)
		]), PackedColorArray([Color(0.02, 0.02, 0.028, 0.9)]))
		draw_line(Vector2(325, 72), Vector2(325, 182), Color(0.62, 0.42, 0.26, 0.9), 5)
		draw_circle(Vector2(351, 128), 9, Color(0.68, 0.08, 0.10, 0.9))

func _draw_city():
	# Land, canals and the open sea.
	draw_rect(Rect2(0, 0, 720, 1280), Color("163c48"))
	draw_rect(Rect2(0, 0, 720, 930), Color("b9a77d"))
	draw_rect(Rect2(0, 885, 720, 395), Color("17627a"))
	draw_polygon(PackedVector2Array([Vector2(0, 775), Vector2(170, 790), Vector2(220, 930), Vector2(0, 930)]), PackedColorArray([Color("1c7388")]))
	draw_polygon(PackedVector2Array([Vector2(720, 710), Vector2(585, 760), Vector2(560, 930), Vector2(720, 930)]), PackedColorArray([Color("1c7388")]))

	# Connected walkable roads.
	draw_polygon(PackedVector2Array([Vector2(320, 0), Vector2(410, 0), Vector2(430, 900), Vector2(285, 900)]), PackedColorArray([Color("d3c59f")]))
	draw_polygon(PackedVector2Array([Vector2(65, 525), Vector2(655, 450), Vector2(670, 610), Vector2(55, 650)]), PackedColorArray([Color("d3c59f")]))
	draw_polygon(PackedVector2Array([Vector2(110, 215), Vector2(405, 390), Vector2(345, 500), Vector2(75, 330)]), PackedColorArray([Color("cbbd94")]))
	for y in range(30, 900, 42):
		draw_line(Vector2(326, y), Vector2(408, y + 4), Color(0.48, 0.43, 0.33, 0.26), 2)
	for x in range(80, 650, 52):
		draw_line(Vector2(x, 540), Vector2(x + 28, 548), Color(0.48, 0.43, 0.33, 0.22), 2)

	# Buildings surrounding the routes.
	_draw_building(Rect2(35, 150, 190, 165), Color("bd704d"), Color("755043"), 4)
	_draw_building(Rect2(35, 455, 215, 160), Color("a95e45"), Color("70483d"), 3)
	_draw_building(Rect2(500, 390, 185, 190), Color("c07b45"), Color("774a36"), 5)
	_draw_building(Rect2(250, 55, 220, 125), Color("81725b"), Color("655d51"), 2)
	_draw_gate()
	_draw_market()
	_draw_square()
	_draw_dock()
	_draw_nature()

	# Moving water highlights keep the map feeling alive.
	for row in range(7):
		var y = 945.0 + row * 48.0
		for column in range(8):
			var x = 20.0 + column * 96.0 + sin(wave_time * 1.4 + row + column) * 9.0
			draw_line(Vector2(x, y), Vector2(x + 45, y), Color(0.50, 0.87, 0.91, 0.35), 3)

func _draw_building(rect, roof_color, wall_color, windows):
	draw_rect(rect, wall_color)
	draw_polygon(PackedVector2Array([
		Vector2(rect.position.x - 10, rect.position.y + 22),
		Vector2(rect.end.x + 10, rect.position.y + 22),
		Vector2(rect.end.x - 22, rect.position.y - 26),
		Vector2(rect.position.x + 22, rect.position.y - 26)
	]), PackedColorArray([roof_color]))
	draw_line(Vector2(rect.position.x - 4, rect.position.y + 22), Vector2(rect.end.x + 4, rect.position.y + 22), roof_color.lightened(0.15), 5)
	for index in range(windows):
		var wx = rect.position.x + 20 + index * max(28, int((rect.size.x - 55) / max(1, windows - 1)))
		draw_rect(Rect2(wx, rect.position.y + 62, 18, 26), Color("6fc2c4"))
		draw_line(Vector2(wx + 9, rect.position.y + 62), Vector2(wx + 9, rect.position.y + 88), Color("315866"), 2)
	var door = Rect2(rect.get_center().x - 18, rect.end.y - 52, 36, 52)
	draw_rect(door, Color("4f352e"))
	draw_circle(Vector2(door.end.x - 7, door.get_center().y), 3, Color("e6bc62"))

func _draw_gate():
	draw_rect(Rect2(250, 55, 58, 165), Color("746c60"))
	draw_rect(Rect2(412, 55, 58, 165), Color("746c60"))
	draw_rect(Rect2(300, 65, 120, 45), Color("635a50"))
	draw_arc(Vector2(360, 185), 53, PI, TAU, 24, Color("3c3733"), 19)
	for x in [266, 282, 428, 444]:
		draw_rect(Rect2(x, 36, 14, 26), Color("746c60"))

func _draw_market():
	for index in range(3):
		var x = 505 + index * 57
		draw_rect(Rect2(x, 620, 48, 65), Color("6c4938"))
		draw_polygon(PackedVector2Array([Vector2(x - 5, 620), Vector2(x + 53, 620), Vector2(x + 43, 592), Vector2(x + 5, 592)]), PackedColorArray([Color("d99a45") if index % 2 == 0 else Color("a94f42")]))
		draw_circle(Vector2(x + 15, 640), 6, Color("d7c86b"))
		draw_circle(Vector2(x + 30, 641), 6, Color("9ab15a"))

func _draw_square():
	draw_circle(Vector2(360, 630), 128, Color(0.82, 0.76, 0.61, 0.48))
	draw_circle(Vector2(360, 630), 46, Color("81715b"))
	draw_circle(Vector2(360, 622), 35, Color("2a8290"))
	draw_circle(Vector2(360, 622), 23, Color("7bc2c1"))
	draw_rect(Rect2(352, 568, 16, 55), Color("70604d"))
	draw_circle(Vector2(360, 558), 15, Color("c8a958"))

func _draw_dock():
	for index in range(5):
		var x = 225 + index * 58
		draw_rect(Rect2(x, 850, 42, 245), Color("745039"))
		for y in range(870, 1080, 35):
			draw_line(Vector2(x, y), Vector2(x + 42, y), Color("a8784e"), 3)
	draw_polygon(PackedVector2Array([Vector2(480, 1050), Vector2(665, 1085), Vector2(625, 1165), Vector2(455, 1120)]), PackedColorArray([Color("6f4633")]))
	draw_line(Vector2(565, 1072), Vector2(565, 955), Color("47362d"), 7)
	draw_polygon(PackedVector2Array([Vector2(572, 965), Vector2(572, 1055), Vector2(638, 1040)]), PackedColorArray([Color("e4d4a4")]))

func _draw_nature():
	for pos in [Vector2(55, 75), Vector2(150, 82), Vector2(610, 95), Vector2(665, 185), Vector2(65, 735), Vector2(650, 760)]:
		draw_rect(Rect2(pos.x - 4, pos.y + 12, 8, 24), Color("654833"))
		draw_circle(pos, 22, Color("376e55"))
		draw_circle(pos + Vector2(-10, -6), 13, Color("4c8760"))
		draw_circle(pos + Vector2(12, -4), 12, Color("2c624c"))

func _draw_field():
	draw_rect(Rect2(0, 0, 720, 1280), Color("315444"))
	# Dirt roads join the four field areas so every objective has a visible route.
	draw_polygon(PackedVector2Array([Vector2(315, 0), Vector2(425, 0), Vector2(440, 1280), Vector2(270, 1280)]), PackedColorArray([Color("b8a071")]))
	draw_polygon(PackedVector2Array([Vector2(35, 555), Vector2(685, 500), Vector2(700, 665), Vector2(25, 710)]), PackedColorArray([Color("aa9368")]))
	draw_polygon(PackedVector2Array([Vector2(280, 610), Vector2(75, 325), Vector2(145, 255), Vector2(385, 535)]), PackedColorArray([Color("aa9368")]))
	draw_polygon(PackedVector2Array([Vector2(405, 560), Vector2(625, 300), Vector2(695, 370), Vector2(470, 650)]), PackedColorArray([Color("aa9368")]))
	# Back hill clearing.
	draw_circle(Vector2(135, 330), 105, Color("6d8052"))
	for angle in range(0, 360, 40):
		var pos = Vector2(135, 330) + Vector2.RIGHT.rotated(deg_to_rad(angle)) * 105
		_draw_field_tree(pos)
	# Mine entrance and ore cart.
	draw_polygon(PackedVector2Array([Vector2(520, 185), Vector2(700, 175), Vector2(720, 445), Vector2(500, 450)]), PackedColorArray([Color("5d584f")]))
	draw_arc(Vector2(612, 380), 68, PI, TAU, 32, Color("201f20"), 32)
	draw_line(Vector2(565, 380), Vector2(565, 445), Color("6d4931"), 9)
	draw_line(Vector2(659, 380), Vector2(659, 445), Color("6d4931"), 9)
	draw_rect(Rect2(530, 470, 65, 42), Color("74513a"))
	draw_circle(Vector2(542, 518), 10, Color("28292c"))
	draw_circle(Vector2(585, 518), 10, Color("28292c"))
	# Residential quarter at the southern entrance.
	_draw_field_house(Rect2(35, 875, 205, 150), Color("a85e48"))
	_draw_field_house(Rect2(480, 850, 200, 165), Color("bd774d"))
	# Wildwood mist and standing stones.
	for pos in [Vector2(90, 755), Vector2(185, 790), Vector2(560, 745), Vector2(650, 700)]:
		_draw_field_tree(pos)
	for pos in [Vector2(515, 110), Vector2(675, 95), Vector2(70, 105)]:
		draw_polygon(PackedVector2Array([pos + Vector2(-16, 38), pos + Vector2(-8, 0), pos + Vector2(12, -18), pos + Vector2(19, 38)]), PackedColorArray([Color("7d8377")]))
	# Road stones and grasses.
	for y in range(40, 1230, 55):
		draw_line(Vector2(322, y), Vector2(411, y + 5), Color(0.30, 0.25, 0.18, 0.25), 2)
	for index in range(28):
		var x = float((index * 83 + 47) % 700)
		var y = float((index * 139 + 90) % 1080)
		if x < 270 or x > 450:
			draw_line(Vector2(x, y), Vector2(x + 5, y - 14), Color("7d9860"), 3)

func _draw_dungeon():
	draw_rect(Rect2(0, 0, 720, 1280), Color("171d25"))
	# Four vertically connected chambers, floor 1 at the bottom and Boss at the top.
	for floor_index in range(4):
		var chamber_y = 70 + floor_index * 255
		var chamber = Rect2(78, chamber_y, 564, 205)
		var tint = Color("313744") if floor_index < 3 else Color("4a302f")
		draw_rect(chamber, tint)
		draw_rect(chamber.grow(-9), tint.lightened(0.08), false, 4)
		for x in range(95, 630, 54):
			draw_line(Vector2(x, chamber_y + 12), Vector2(x, chamber_y + 193), Color(0.10, 0.12, 0.16, 0.45), 2)
		for y in range(int(chamber_y + 35), int(chamber_y + 190), 45):
			draw_line(Vector2(90, y), Vector2(630, y), Color(0.10, 0.12, 0.16, 0.38), 2)
		if floor_index < 3:
			draw_rect(Rect2(330, chamber_y + 205, 60, 50), Color("5b5147"))
			draw_line(Vector2(340, chamber_y + 212), Vector2(340, chamber_y + 248), Color("95826b"), 4)
			draw_line(Vector2(380, chamber_y + 212), Vector2(380, chamber_y + 248), Color("95826b"), 4)
	# Braziers and final-floor fire glow.
	for y in [150, 405, 660, 915]:
		for x in [105, 615]:
			draw_rect(Rect2(x - 7, y, 14, 35), Color("6b4b36"))
			draw_circle(Vector2(x, y), 15, Color("dc7045"))
			draw_circle(Vector2(x, y - 5), 8, Color("f5bf5f"))
	draw_circle(Vector2(360, 160), 92, Color(0.76, 0.18, 0.14, 0.16))
	# Entrance platform.
	draw_polygon(PackedVector2Array([Vector2(250, 1100), Vector2(470, 1100), Vector2(540, 1280), Vector2(180, 1280)]), PackedColorArray([Color("393d46")]))

func _draw_field_tree(pos):
	draw_rect(Rect2(pos.x - 5, pos.y + 12, 10, 28), Color("5f4431"))
	draw_circle(pos, 27, Color("315f45"))
	draw_circle(pos + Vector2(-12, -8), 16, Color("477a55"))
	draw_circle(pos + Vector2(14, -6), 15, Color("28543e"))

func _draw_field_house(rect, roof):
	draw_rect(rect, Color("705244"))
	draw_polygon(PackedVector2Array([Vector2(rect.position.x - 8, rect.position.y + 18), Vector2(rect.end.x + 8, rect.position.y + 18), Vector2(rect.end.x - 25, rect.position.y - 25), Vector2(rect.position.x + 25, rect.position.y - 25)]), PackedColorArray([roof]))
	draw_rect(Rect2(rect.get_center().x - 18, rect.end.y - 50, 36, 50), Color("45342d"))
