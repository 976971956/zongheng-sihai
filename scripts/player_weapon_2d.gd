extends Node2D

var weapon_id = ""
var facing = "down"
var moving = false
var walk_time = 0.0

func configure(item_id):
	weapon_id = str(item_id)
	set_meta("weapon_id", weapon_id)
	visible = weapon_id != ""
	queue_redraw()

func update_pose(next_facing, is_moving, phase):
	facing = str(next_facing)
	moving = bool(is_moving)
	walk_time = float(phase)
	set_meta("facing", facing)
	set_meta("moving", moving)
	set_meta("mount", "back" if moving else "hand")
	queue_redraw()

func _draw():
	if weapon_id == "":
		return
	var palette = _weapon_palette()
	var bob = sin(walk_time * 9.0 * PI) * 0.8 if moving else 0.0
	if moving:
		_draw_back_carried_weapon(palette, bob)
		return
	var origin = Vector2(18, -2 + bob)
	var angle = -0.42
	if facing == "left":
		origin = Vector2(-18, -2 + bob)
		angle = PI + 0.42
	elif facing == "up":
		origin = Vector2(16, -1 + bob)
		angle = -0.72
	elif facing == "down":
		origin = Vector2(17, 1 + bob)
		angle = -0.23
	draw_set_transform(origin, angle)
	if weapon_id == "divine_shears":
		_draw_shears(palette)
	elif weapon_id in ["spider_knife"]:
		_draw_blade(24.0, 4.4, palette, true)
	elif weapon_id in ["tira_sword"]:
		_draw_blade(43.0, 5.4, palette, false)
	else:
		_draw_blade(36.0, 5.2, palette, true)
	draw_set_transform(Vector2.ZERO)

func _draw_back_carried_weapon(palette, bob):
	# 行走时将武器斜挂在背带上。正面/侧面由父节点放到人物后层，
	# 背面朝镜头时则覆盖在背部上方，既符合空间关系也不会完全被遮住。
	var origin = Vector2(-17, 18 + bob)
	var angle = -1.02
	if facing == "left":
		origin = Vector2(17, 18 + bob)
		angle = -2.12
	elif facing == "up":
		origin = Vector2(-16, 17 + bob)
		angle = -1.02
	elif facing == "down":
		origin = Vector2(-17, 19 + bob)
		angle = -1.02
	draw_set_transform(origin, angle)
	if weapon_id == "divine_shears":
		_draw_shears(palette)
	elif weapon_id == "spider_knife":
		_draw_blade(24.0, 4.4, palette, true)
	elif weapon_id == "tira_sword":
		_draw_blade(43.0, 5.4, palette, false)
	else:
		_draw_blade(36.0, 5.2, palette, true)
	draw_set_transform(Vector2.ZERO)

func _draw_blade(length, width, palette, curved):
	var guard_color = Color(palette.guard)
	var blade_color = Color(palette.blade)
	var shine_color = Color(palette.shine)
	draw_line(Vector2(-5, 0), Vector2(3, 0), Color(palette.grip), 4.6, true)
	draw_line(Vector2(2, -5), Vector2(2, 5), guard_color, 3.0, true)
	if curved:
		var points = PackedVector2Array([Vector2(4, 0), Vector2(length * 0.55, -1), Vector2(length, -7), Vector2(length - 3, -2), Vector2(5, 3)])
		draw_colored_polygon(points, blade_color)
		draw_polyline(PackedVector2Array([Vector2(6, 0), Vector2(length * 0.56, -2), Vector2(length - 2, -6)]), shine_color, 1.4, true)
	else:
		var points = PackedVector2Array([Vector2(4, -width * 0.5), Vector2(length - 4, -width * 0.5), Vector2(length, 0), Vector2(length - 4, width * 0.5), Vector2(4, width * 0.5)])
		draw_colored_polygon(points, blade_color)
		draw_line(Vector2(7, -1.2), Vector2(length - 5, -1.2), shine_color, 1.2, true)

func _draw_shears(palette):
	var metal = Color(palette.blade)
	var shine = Color(palette.shine)
	draw_arc(Vector2(-2, -4), 5.0, 0, TAU, 18, Color(palette.guard), 2.4, true)
	draw_arc(Vector2(-2, 5), 5.0, 0, TAU, 18, Color(palette.guard), 2.4, true)
	draw_circle(Vector2(5, 0), 2.5, Color(palette.grip))
	var top = PackedVector2Array([Vector2(5, -1), Vector2(39, -9), Vector2(42, -6), Vector2(7, 2)])
	var bottom = PackedVector2Array([Vector2(5, 1), Vector2(39, 9), Vector2(42, 6), Vector2(7, -2)])
	draw_colored_polygon(top, metal)
	draw_colored_polygon(bottom, metal)
	draw_line(Vector2(9, -1), Vector2(38, -7), shine, 1.2, true)
	draw_line(Vector2(9, 1), Vector2(38, 7), shine, 1.2, true)

func _weapon_palette():
	var set_id = ""
	if GameData.ITEMS.has(weapon_id):
		set_id = str(GameData.ITEMS[weapon_id].get("set", ""))
	match set_id:
		"warrior": return {"blade": "d8f4ee", "shine": "ffffff", "guard": "40bdb6", "grip": "5a3526"}
		"black_sail": return {"blade": "b9c3c4", "shine": "fff0ad", "guard": "c99442", "grip": "7c2633"}
		"white_whale": return {"blade": "d9f7ff", "shine": "ffffff", "guard": "69bcd1", "grip": "305677"}
		"seven_seas": return {"blade": "a8dde0", "shine": "f5ffff", "guard": "4fc0aa", "grip": "344d5c"}
		"earth_legacy": return {"blade": "8ce3c1", "shine": "effff5", "guard": "d6b45a", "grip": "335a42"}
		"tidekeeper": return {"blade": "bdfaff", "shine": "ffffff", "guard": "e1bd58", "grip": "276a7c"}
		_: return {"blade": "c7d2d6", "shine": "f4fbff", "guard": "b48d4e", "grip": "5b3826"}
