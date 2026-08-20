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
	set_meta("mount", "back")
	queue_redraw()

func _draw():
	if weapon_id == "":
		return
	var palette = _weapon_palette()
	var bob = sin(walk_time * 9.0 * PI) * 0.8 if moving else 0.0
	_draw_back_carried_weapon(palette, bob)

func _draw_back_carried_weapon(palette, bob):
	# 探索地图中始终将武器斜挂在背带上。正面/侧面由父节点放到人物后层，
	# 背面朝镜头时则覆盖在背部上方，既符合空间关系也不会完全被遮住。
	var origin = Vector2(-22, 23 + bob)
	var angle = -0.98
	if facing == "left":
		origin = Vector2(22, 23 + bob)
		angle = -2.16
	elif facing == "up":
		origin = Vector2(-21, 22 + bob)
		angle = -0.98
	elif facing == "down":
		origin = Vector2(-22, 24 + bob)
		angle = -0.98
	draw_set_transform(origin, angle)
	if weapon_id == "divine_shears":
		_draw_sheathed_shears(palette)
	elif weapon_id == "spider_knife":
		_draw_sheathed_blade(31.0, 5.0, palette)
	elif weapon_id == "tira_sword":
		_draw_sheathed_blade(51.0, 7.0, palette)
	else:
		_draw_sheathed_blade(45.0, 6.5, palette)
	draw_set_transform(Vector2.ZERO)

func _draw_sheathed_blade(length, width, palette):
	# 背负状态展示的是完整刀鞘：鞘尖在腰后、握柄越过肩头，
	# 与手持状态的裸刃轮廓明显不同，远距离也能一眼看出正在背刀。
	var sheath = Color("18262d")
	var sheath_edge = Color(palette.guard).darkened(0.25)
	draw_line(Vector2.ZERO, Vector2(length - 5.0, 0), sheath, width + 3.0, true)
	draw_line(Vector2(2, -1.2), Vector2(length - 7.0, -1.2), sheath_edge, 1.6, true)
	var tip = PackedVector2Array([Vector2(-4, 0), Vector2(1, -width * 0.62), Vector2(3, width * 0.62)])
	draw_colored_polygon(tip, Color(palette.guard))
	var guard_x = length - 4.0
	draw_line(Vector2(guard_x, -6), Vector2(guard_x, 6), Color(palette.guard), 3.2, true)
	draw_line(Vector2(length - 1.0, 0), Vector2(length + 11.0, 0), Color(palette.grip), 5.0, true)
	draw_line(Vector2(length + 1.0, -1.1), Vector2(length + 9.0, -1.1), Color(palette.shine), 1.2, true)
	draw_circle(Vector2(length + 12.0, 0), 3.2, Color(palette.guard))

func _draw_sheathed_shears(palette):
	var sheath = Color("18262d")
	draw_line(Vector2.ZERO, Vector2(42, 0), sheath, 10.0, true)
	draw_line(Vector2(3, -2), Vector2(38, -2), Color(palette.guard).darkened(0.2), 1.6, true)
	draw_arc(Vector2(47, -5), 5.5, 0, TAU, 18, Color(palette.guard), 2.6, true)
	draw_arc(Vector2(47, 6), 5.5, 0, TAU, 18, Color(palette.guard), 2.6, true)
	draw_circle(Vector2(41, 0), 2.8, Color(palette.shine))

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
