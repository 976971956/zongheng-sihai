extends Control

const ActorScript = preload("res://scripts/actor_2d.gd")
const HARBOR_ART = preload("res://assets/art/maps/venice_city_v2.png")

var player_hp = 1
var player_max_hp = 1
var enemy_hp = 1
var enemy_max_hp = 1
var enemy_name = "敌人"
var enemy_id = "drunk_sailor"
var player_offset = 0.0
var enemy_offset = 0.0
var impact_alpha = 0.0
var player_model
var enemy_model

func _ready():
	clip_contents = true
	player_model = ActorScript.new()
	player_model.z_index = 2
	player_model.scale = Vector2(1.85, 1.85)
	player_model.configure("player", Color("278e93"), Color("f1c66d"), "player")
	add_child(player_model)
	enemy_model = ActorScript.new()
	enemy_model.z_index = 2
	enemy_model.scale = Vector2(1.85, 1.85)
	add_child(enemy_model)
	_configure_enemy_model()
	_layout_models()

func _notification(what):
	if what == NOTIFICATION_RESIZED and is_instance_valid(player_model):
		_layout_models()

func set_battle_values(view):
	player_hp = int(view.get("player_hp", player_hp))
	player_max_hp = max(1, int(view.get("player_max_hp", player_max_hp)))
	enemy_hp = int(view.get("enemy_hp", enemy_hp))
	enemy_max_hp = max(1, int(view.get("enemy_max_hp", enemy_max_hp)))
	enemy_name = str(view.get("enemy_name", enemy_name))
	enemy_id = str(view.get("enemy_id", enemy_id))
	if is_instance_valid(enemy_model):
		_configure_enemy_model()
	queue_redraw()

func _configure_enemy_model():
	var colors = {
		"drunk_sailor": [Color("99484c"), Color("4a3e49")],
		"sewer_rat": [Color("68736c"), Color("aab7ad")],
		"mine_thief": [Color("855447"), Color("3e4146")],
		"giant_bear": [Color("69493e"), Color("3c302c")],
		"wildwood_ghost": [Color("617a82"), Color("acd9d6")],
		"dungeon_guard": [Color("687887"), Color("c8d2d5")],
		"stone_puppet": [Color("77766e"), Color("b6a986")],
		"tide_beast": [Color("397b83"), Color("79c2c6")],
		"vermilion_phantom": [Color("a84042"), Color("f0aa58")]
	}
	var palette = colors.get(enemy_id, [Color("99484c"), Color("4a3e49")])
	enemy_model.configure("enemy", palette[0], palette[1], enemy_id)

func _layout_models():
	player_model.position = Vector2(size.x * 0.25 + player_offset, size.y * 0.67)
	enemy_model.position = Vector2(size.x * 0.74 + enemy_offset, size.y * 0.67)

func animate_attack(player_turn = true):
	var tween = create_tween()
	if player_turn:
		tween.tween_method(_set_player_offset, 0.0, 58.0, 0.10).set_trans(Tween.TRANS_QUAD)
		tween.tween_method(_set_player_offset, 58.0, 0.0, 0.15).set_trans(Tween.TRANS_BACK)
	else:
		tween.tween_method(_set_enemy_offset, 0.0, -58.0, 0.10).set_trans(Tween.TRANS_QUAD)
		tween.tween_method(_set_enemy_offset, -58.0, 0.0, 0.15).set_trans(Tween.TRANS_BACK)
	var flash = create_tween()
	flash.tween_method(_set_impact_alpha, 0.0, 0.8, 0.08)
	flash.tween_method(_set_impact_alpha, 0.8, 0.0, 0.20)

func _set_player_offset(value):
	player_offset = value
	if is_instance_valid(player_model):
		_layout_models()
	queue_redraw()

func _set_enemy_offset(value):
	enemy_offset = value
	if is_instance_valid(enemy_model):
		_layout_models()
	queue_redraw()

func _set_impact_alpha(value):
	impact_alpha = value
	queue_redraw()

func _draw():
	# The battle arena uses the same hand-painted harbor world instead of a flat placeholder.
	# Keep the source rectangle fully inside the texture. An oversized region can
	# leave transparent gaps that reveal world-map actors behind the battle panel.
	var source = Rect2(0, 690, HARBOR_ART.get_width(), HARBOR_ART.get_height() - 690)
	draw_texture_rect_region(HARBOR_ART, Rect2(Vector2.ZERO, size), source)
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.025, 0.07, 0.085, 0.23))
	draw_rect(Rect2(0, size.y * 0.47, size.x, size.y * 0.53), Color(0.13, 0.08, 0.04, 0.12))
	# Ornamental duel line and compass medallion anchor both combatants visually.
	draw_line(Vector2(size.x * 0.12, size.y * 0.78), Vector2(size.x * 0.88, size.y * 0.78), Color(0.95, 0.75, 0.34, 0.32), 3, true)
	draw_arc(Vector2(size.x * 0.5, size.y * 0.74), 48, 0, TAU, 48, Color(0.95, 0.75, 0.34, 0.28), 3)
	for angle in range(0, 360, 90):
		var direction = Vector2.RIGHT.rotated(deg_to_rad(angle))
		draw_line(Vector2(size.x * 0.5, size.y * 0.74) + direction * 36, Vector2(size.x * 0.5, size.y * 0.74) + direction * 55, Color(0.95, 0.75, 0.34, 0.3), 3, true)
	_draw_bar(Vector2(35, 30), size.x * 0.38, float(player_hp) / player_max_hp, Color("35c6b4"))
	_draw_bar(Vector2(size.x * 0.57, 30), size.x * 0.38, float(enemy_hp) / enemy_max_hp, Color("ef6f73"))
	if impact_alpha > 0.0:
		draw_circle(Vector2(size.x * 0.5, size.y * 0.57), 52 * impact_alpha, Color(1.0, 0.83, 0.38, impact_alpha))
		for angle in range(0, 360, 45):
			var direction = Vector2.RIGHT.rotated(deg_to_rad(angle))
			draw_line(Vector2(size.x * 0.5, size.y * 0.57) + direction * 32, Vector2(size.x * 0.5, size.y * 0.57) + direction * 78, Color(1.0, 0.92, 0.62, impact_alpha), 5)
func _draw_bar(position, width, ratio, color):
	draw_rect(Rect2(position - Vector2(2, 2), Vector2(width + 4, 20)), Color(0.89, 0.69, 0.30, 0.8))
	draw_rect(Rect2(position, Vector2(width, 16)), Color("08161d"))
	draw_rect(Rect2(position + Vector2(3, 3), Vector2(max(0, width - 6) * clamp(ratio, 0.0, 1.0), 10)), color)
	draw_line(position + Vector2(4, 5), position + Vector2(4 + max(0, width - 8) * clamp(ratio, 0.0, 1.0), 5), Color(1, 1, 1, 0.28), 2, true)

func _draw_oval(center, radius, color):
	var points = PackedVector2Array()
	for index in range(28):
		var angle = TAU * float(index) / 28.0
		points.append(center + Vector2(cos(angle) * radius.x, sin(angle) * radius.y))
	draw_colored_polygon(points, color)
