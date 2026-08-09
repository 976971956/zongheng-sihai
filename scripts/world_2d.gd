extends Control

const MAP_SIZE = Vector2(720, 1280)
const WORLD_SCALE = 1.5
const WORLD_SIZE = MAP_SIZE * WORLD_SCALE
const CAMERA_FOCUS = Vector2(360, 625)
const CAMERA_SMOOTH_SPEED = 8.0
const TEAL = Color("38c5b5")
const GOLD = Color("f1c66d")
const INK = Color("e2f1f1")
const MUTED = Color("9ab3b8")
const RED = Color("ef6f73")
const PANEL = Color(0.025, 0.08, 0.105, 0.94)
const WorldMapScript = preload("res://scripts/world_map_2d.gd")
const ActorScript = preload("res://scripts/actor_2d.gd")
const BattleStageScript = preload("res://scripts/battle_stage_2d.gd")
const JoystickScript = preload("res://scripts/virtual_joystick.gd")
const MONSTER_RESPAWN_SECONDS = GameState.ENEMY_RESPAWN_SECONDS
const MONSTER_RESPAWN_RETRY_SECONDS = 1.5
const MONSTER_RESPAWN_SAFE_DISTANCE = 170.0
const AUTO_BATTLE_HIT_DELAY = 0.16
const AUTO_BATTLE_READ_DELAY = 0.30

const ENEMY_SPAWNS = {
	"drunk_sailor": {"region": "city", "name": "喝醉的水手", "position": Vector2(360, 300), "color": Color("99484c"), "accent": Color("4a3e49"), "location": "venice_north_gate"},
	"sewer_rat": {"region": "field", "name": "灰毛巨鼠", "position": Vector2(465, 945), "color": Color("68736c"), "accent": Color("aab7ad"), "location": "residential_quarter"},
	"mine_thief": {"region": "field", "name": "偷矿者", "position": Vector2(595, 455), "color": Color("855447"), "accent": Color("3e4146"), "location": "venice_mine"},
	"giant_bear": {"region": "field", "name": "后山巨熊", "position": Vector2(140, 410), "color": Color("69493e"), "accent": Color("3c302c"), "location": "venice_back_hill"},
	"wildwood_ghost": {"region": "field", "name": "荒林幽灵", "position": Vector2(575, 750), "color": Color("617a82"), "accent": Color("acd9d6"), "location": "venice_wildwood"},
	"dungeon_guard": {"region": "dungeon", "name": "一层训练卫兵", "position": Vector2(360, 930), "color": Color("687887"), "accent": Color("c8d2d5"), "location": "training_dungeon_1"},
	"stone_puppet": {"region": "dungeon", "name": "二层石傀儡", "position": Vector2(360, 680), "color": Color("77766e"), "accent": Color("b6a986"), "location": "training_dungeon_2"},
	"tide_beast": {"region": "dungeon", "name": "三层潮汐兽", "position": Vector2(360, 425), "color": Color("397b83"), "accent": Color("79c2c6"), "location": "training_dungeon_3"},
	"vermilion_phantom": {"region": "dungeon", "name": "朱雀幻影", "position": Vector2(360, 225), "color": Color("a84042"), "accent": Color("f0aa58"), "location": "training_dungeon_4"}
	,"corsair_deckhand": {"region": "black_sail", "name": "黑帆水手", "position": Vector2(360, 930), "color": Color("8a493e"), "accent": Color("d1b36b"), "location": "black_sail_1"}
	,"corsair_raider": {"region": "black_sail", "name": "黑帆袭击者", "position": Vector2(360, 680), "color": Color("56463e"), "accent": Color("c77b49"), "location": "black_sail_2"}
	,"corsair_guard": {"region": "black_sail", "name": "黑帆重卫", "position": Vector2(360, 425), "color": Color("536573"), "accent": Color("d4b85c"), "location": "black_sail_3"}
	,"corsair_captain": {"region": "black_sail", "name": "船长雷蒙", "position": Vector2(360, 225), "color": Color("263d57"), "accent": Color("e3bd5b"), "location": "black_sail_4"}
}

const DISCOVERY_SPAWNS = {
	"alisa_shell": {"region": "city", "location": "alisa_hut", "position": Vector2(76, 430)},
	"field_cache": {"region": "field", "location": "residential_quarter", "position": Vector2(305, 860)},
	"trial_relic": {"region": "dungeon", "location": "training_dungeon_2", "position": Vector2(250, 680)},
	"corsair_manifest": {"region": "black_sail", "location": "black_sail_3", "position": Vector2(485, 455)}
}

var state = GameState.new()
var world_layer
var map_node
var player_actor
var actors = []
var move_target = Vector2.ZERO
var has_move_target = false
var nearest_actor = {}
var action_button
var location_label
var stats_label
var quest_label
var hint_label
var overlay
var battle_stage
var battle_log_label
var battle_action_button
var battle_auto_button
var battle_skill_button
var battle_round_label
var battle_player_info_label
var battle_enemy_info_label
var battle_intent_label
var battle_stance_buttons = {}
var battle_heal_button
var battle_cure_button
var battle_result = {}
var auto_battle_running = false
var active_enemy_actor = {}
var enemy_respawn_scheduled = {}
var current_zone = ""
var current_region = "city"
var joystick
var joystick_direction = Vector2.ZERO
var waypoint_label
var waypoint_world_target = Vector2.ZERO
var navigation_button
var inventory_notice = ""
var audio_button
var footstep_timer = 0.0

var region_by_location = {
	"alisa_hut": "city", "venice_tavern": "city", "venice_square": "city",
	"venice_market": "city", "venice_dock": "city", "venice_north_gate": "city",
	"ragusa_dock": "city", "alexandria_dock": "city",
	"residential_quarter": "field", "venice_mine": "field", "venice_back_hill": "field", "venice_wildwood": "field",
	"training_dungeon_1": "dungeon", "training_dungeon_2": "dungeon", "training_dungeon_3": "dungeon", "training_dungeon_4": "dungeon"
	,"black_sail_1": "black_sail", "black_sail_2": "black_sail", "black_sail_3": "black_sail", "black_sail_4": "black_sail"
}

var region_zones = {
	"city": {
		"alisa_hut": {"point": Vector2(150, 350), "radius": 115},
		"venice_tavern": {"point": Vector2(165, 685), "radius": 115},
		"venice_square": {"point": Vector2(360, 705), "radius": 120},
		"venice_market": {"point": Vector2(575, 665), "radius": 110},
		"venice_dock": {"point": Vector2(360, 900), "radius": 115},
		"venice_north_gate": {"point": Vector2(360, 285), "radius": 110}
	},
	"field": {
		"residential_quarter": {"point": Vector2(360, 1010), "radius": 130},
		"venice_mine": {"point": Vector2(595, 455), "radius": 130},
		"venice_back_hill": {"point": Vector2(140, 410), "radius": 130},
		"venice_wildwood": {"point": Vector2(575, 750), "radius": 125}
	},
	"dungeon": {
		"training_dungeon_1": {"point": Vector2(360, 970), "radius": 115},
		"training_dungeon_2": {"point": Vector2(360, 720), "radius": 105},
		"training_dungeon_3": {"point": Vector2(360, 465), "radius": 105},
		"training_dungeon_4": {"point": Vector2(360, 210), "radius": 115}
	},
	"black_sail": {
		"black_sail_1": {"point": Vector2(360, 970), "radius": 115},
		"black_sail_2": {"point": Vector2(360, 720), "radius": 105},
		"black_sail_3": {"point": Vector2(360, 465), "radius": 105},
		"black_sail_4": {"point": Vector2(360, 210), "radius": 115}
	}
}

var region_obstacles = {
	"city": [Rect2(20, 160, 170, 190), Rect2(20, 730, 210, 190), Rect2(530, 160, 170, 230), Rect2(235, 25, 80, 200), Rect2(405, 25, 80, 200)],
	"field": [Rect2(495, 135, 225, 285), Rect2(20, 835, 235, 195), Rect2(465, 815, 235, 205)],
	"dungeon": [Rect2(0, 285, 295, 58), Rect2(425, 285, 295, 58), Rect2(0, 540, 295, 58), Rect2(425, 540, 295, 58), Rect2(0, 795, 295, 58), Rect2(425, 795, 295, 58)],
	"black_sail": [Rect2(0, 285, 295, 58), Rect2(425, 285, 295, 58), Rect2(0, 540, 295, 58), Rect2(425, 540, 295, 58), Rect2(0, 795, 295, 58), Rect2(425, 795, 295, 58)]
}

func _ready():
	get_window().content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	get_window().content_scale_aspect = Window.CONTENT_SCALE_ASPECT_EXPAND
	get_window().content_scale_size = Vector2i(720, 1280)
	var capture_world = "--capture-2d" in OS.get_cmdline_user_args()
	var capture_battle = "--capture-2d-battle" in OS.get_cmdline_user_args()
	var capture_field = "--capture-2d-field" in OS.get_cmdline_user_args()
	var capture_dungeon = "--capture-2d-dungeon" in OS.get_cmdline_user_args()
	var capture_black_sail = "--capture-black-sail" in OS.get_cmdline_user_args()
	var capture_mode = capture_world or capture_battle or capture_field or capture_dungeon or capture_black_sail
	if state.has_save() and not capture_mode:
		state.load_game()
	_scale_world_geometry()
	current_region = str(region_by_location.get(str(state.player.location), "city"))
	_build_world()
	_build_hud()
	_spawn_world_actors()
	player_actor.position = _spawn_for_location(str(state.player.location))
	_update_camera(0.0, true)
	_update_zone(true)
	_refresh_hud()
	_refresh_waypoint()
	AudioDirector.set_region(current_region)
	if not state.active_battle.is_empty():
		call_deferred("_open_battle", state.get_battle_view())
	if capture_battle:
		call_deferred("_capture_battle_preview")
	elif capture_field:
		call_deferred("_capture_region_preview", "field", "residential_quarter", "res://world_2d_field_preview.png")
	elif capture_dungeon:
		call_deferred("_capture_region_preview", "dungeon", "training_dungeon_1", "res://world_2d_dungeon_preview.png")
	elif capture_black_sail:
		state.player.level = 12
		state.quest_index = 13
		call_deferred("_capture_region_preview", "black_sail", "black_sail_1", "res://world_2d_black_sail_preview.png")
	elif capture_world:
		call_deferred("_capture_preview")

func _capture_preview():
	await get_tree().create_timer(0.5).timeout
	var image = get_viewport().get_texture().get_image()
	image.save_png("res://world_2d_preview.png")
	get_tree().quit()

func _capture_battle_preview():
	state.player.level = 3
	state.player.location = "venice_north_gate"
	state.player.hp = state.get_stats().max_hp
	var view = state.start_battle("drunk_sailor")
	_open_battle(view)
	await get_tree().create_timer(0.5).timeout
	var image = get_viewport().get_texture().get_image()
	image.save_png("res://world_2d_battle_preview.png")
	get_tree().quit()

func _capture_region_preview(region_id, location_id, output_path):
	state.player.level = 12 if region_id == "black_sail" else 4
	_switch_region(region_id, location_id)
	await get_tree().create_timer(0.5).timeout
	var image = get_viewport().get_texture().get_image()
	image.save_png(output_path)
	get_tree().quit()

func _build_world():
	world_layer = Node2D.new()
	world_layer.y_sort_enabled = true
	add_child(world_layer)
	map_node = WorldMapScript.new()
	map_node.set_region(current_region)
	world_layer.add_child(map_node)
	player_actor = ActorScript.new()
	player_actor.z_index = 10
	player_actor.configure("player", Color("278e93"), GOLD, "player")
	player_actor.scale = Vector2.ONE * 1.12
	world_layer.add_child(player_actor)

func _scale_world_geometry():
	for region_id in region_zones:
		for location_id in region_zones[region_id]:
			var zone = region_zones[region_id][location_id]
			zone.point = _world_point(zone.point)
			zone.radius = float(zone.radius) * WORLD_SCALE
	for region_id in region_obstacles:
		var scaled_rects = []
		for rect in region_obstacles[region_id]:
			scaled_rects.append(_world_rect(rect))
		region_obstacles[region_id] = scaled_rects

func _world_point(point):
	return Vector2(point) * WORLD_SCALE

func _world_rect(rect):
	return Rect2(rect.position * WORLD_SCALE, rect.size * WORLD_SCALE)

func _spawn_world_actors():
	for entry in actors:
		if is_instance_valid(entry.node):
			entry.node.queue_free()
	actors = []
	nearest_actor = {}
	if current_region == "city":
		var active_port = str(state.player.location)
		if active_port == "ragusa_dock":
			_add_actor("npc", "ragusa_broker", "拉古萨经纪人", Vector2(205, 870), Color("665044"), GOLD, "ragusa_dock")
		elif active_port == "alexandria_dock":
			_add_actor("npc", "alexandria_merchant", "香料商萨米尔", Vector2(205, 870), Color("6d563e"), GOLD, "alexandria_dock")
		else:
			_add_actor("npc", "alisa", "艾丽莎", Vector2(150, 365), Color("628ec6"), Color("f2d58b"), "alisa_hut")
			_add_actor("npc", "tavern_keeper", "酒馆老板", Vector2(180, 675), Color("8c6750"), Color("c78d52"), "venice_tavern")
			_add_actor("npc", "ship_owner", "船老板", Vector2(205, 870), Color("3d7287"), Color("d6b35c"), "venice_dock")
			_spawn_enemy_if_ready("drunk_sailor")
			_add_actor("travel", "field", "前往城外", Vector2(455, 285), Color("547b61"), GOLD, "residential_quarter")
		if state.quest_index >= 12:
			_add_actor("travel", "black_sail", "黑帆据点", Vector2(520, 910), Color("493b45"), RED, "black_sail_1")
	elif current_region == "field":
		_spawn_enemy_if_ready("sewer_rat")
		_spawn_enemy_if_ready("mine_thief")
		_spawn_enemy_if_ready("giant_bear")
		_spawn_enemy_if_ready("wildwood_ghost")
		_add_actor("travel", "city", "返回威尼斯", Vector2(220, 1070), Color("4e7781"), GOLD, "venice_north_gate")
		_add_actor("travel", "dungeon", "经验副本入口", Vector2(360, 245), Color("775c54"), RED, "training_dungeon_1")
	elif current_region == "dungeon":
		_spawn_next_dungeon_enemy(["dungeon_guard", "stone_puppet", "tide_beast", "vermilion_phantom"])
		_add_actor("travel", "field", "离开副本", Vector2(215, 1080), Color("4e7781"), GOLD, "residential_quarter")
	else:
		_spawn_next_dungeon_enemy(["corsair_deckhand", "corsair_raider", "corsair_guard", "corsair_captain"])
		_add_actor("travel", "city", "返回港口", Vector2(215, 1080), Color("4e7781"), GOLD, "venice_dock")
	for discovery_id in DISCOVERY_SPAWNS:
		_spawn_discovery_if_available(discovery_id)

func _spawn_next_dungeon_enemy(enemy_ids):
	for enemy_id in enemy_ids:
		if not bool(state.dungeon_cleared.get(enemy_id, false)):
			_spawn_enemy_if_ready(enemy_id)
			return

func _spawn_discovery_if_available(discovery_id):
	if bool(state.discoveries.get(discovery_id, false)) or not DISCOVERY_SPAWNS.has(discovery_id):
		return
	var spawn = DISCOVERY_SPAWNS[discovery_id]
	if str(spawn.region) != current_region:
		return
	if current_region in ["dungeon", "black_sail"] and _dungeon_floor_lock(str(spawn.location)) != "":
		return
	var data = GameData.DISCOVERIES[discovery_id]
	_add_actor("discovery", discovery_id, data.name, spawn.position, Color("735a2f"), GOLD, spawn.location)

func _spawn_enemy_if_ready(enemy_id):
	if not ENEMY_SPAWNS.has(enemy_id):
		return
	var data = ENEMY_SPAWNS[enemy_id]
	if str(data.region) != current_region:
		return
	var key = _enemy_spawn_key(enemy_id)
	var remaining = float(state.enemy_respawns.get(key, 0.0)) - _world_time_seconds()
	if remaining > 0.0:
		_schedule_enemy_respawn(enemy_id, remaining)
		return
	state.enemy_respawns.erase(key)
	enemy_respawn_scheduled.erase(key)
	if _has_actor_id(enemy_id):
		return
	_add_actor("enemy", enemy_id, data.name, data.position, data.color, data.accent, data.location)

func _enemy_spawn_key(enemy_id):
	return str(enemy_id)

func _world_time_seconds():
	return float(Time.get_unix_time_from_system())

func _has_actor_id(actor_id):
	for entry in actors:
		if str(entry.id) == str(actor_id) and is_instance_valid(entry.node):
			return true
	return false

func _schedule_enemy_respawn(enemy_id, delay):
	var key = _enemy_spawn_key(enemy_id)
	var deadline = float(state.enemy_respawns.get(key, _world_time_seconds() + float(delay)))
	if is_equal_approx(float(enemy_respawn_scheduled.get(key, -1.0)), deadline):
		return
	enemy_respawn_scheduled[key] = deadline
	var timer = get_tree().create_timer(max(0.05, float(delay)))
	timer.timeout.connect(_try_respawn_enemy.bind(enemy_id, deadline))

func _defer_enemy_respawn(enemy_id):
	var key = _enemy_spawn_key(enemy_id)
	var retry_deadline = _world_time_seconds() + MONSTER_RESPAWN_RETRY_SECONDS
	enemy_respawn_scheduled[key] = retry_deadline
	var timer = get_tree().create_timer(MONSTER_RESPAWN_RETRY_SECONDS)
	timer.timeout.connect(_try_respawn_enemy.bind(enemy_id, retry_deadline))

func _respawn_is_blocked(data):
	if is_instance_valid(overlay):
		return true
	if not is_instance_valid(player_actor):
		return false
	return player_actor.position.distance_to(_world_point(data.position)) < MONSTER_RESPAWN_SAFE_DISTANCE

func _try_respawn_enemy(enemy_id, scheduled_deadline = -1.0):
	var key = _enemy_spawn_key(enemy_id)
	if scheduled_deadline >= 0.0 and not is_equal_approx(float(enemy_respawn_scheduled.get(key, -2.0)), float(scheduled_deadline)):
		return
	enemy_respawn_scheduled.erase(key)
	var remaining = float(state.enemy_respawns.get(key, 0.0)) - _world_time_seconds()
	if remaining > 0.0:
		_schedule_enemy_respawn(enemy_id, remaining)
		return
	var data = ENEMY_SPAWNS.get(enemy_id, {})
	if data.is_empty():
		return
	if str(data.region) in ["dungeon", "black_sail"] and bool(state.dungeon_cleared.get(enemy_id, false)):
		state.enemy_respawns.erase(key)
		return
	if str(data.region) != current_region:
		state.enemy_respawns.erase(key)
		return
	if _has_actor_id(enemy_id):
		state.enemy_respawns.erase(key)
		return
	if _respawn_is_blocked(data):
		_defer_enemy_respawn(enemy_id)
		if not is_instance_valid(overlay):
			hint_label.text = "%s将在你离开刷新点后重新出现。" % data.name
		return
	state.enemy_respawns.erase(key)
	_add_actor("enemy", enemy_id, data.name, data.position, data.color, data.accent, data.location)
	_refresh_waypoint()
	hint_label.text = "%s重新出现了，可以再次挑战。" % data.name

func _despawn_defeated_enemy():
	if active_enemy_actor.is_empty():
		return
	var defeated = active_enemy_actor
	active_enemy_actor = {}
	var enemy_id = str(defeated.get("id", ""))
	if enemy_id == "" or not ENEMY_SPAWNS.has(enemy_id):
		return
	actors.erase(defeated)
	if is_instance_valid(defeated.get("node")):
		defeated.node.selected = false
		defeated.node.queue_free()
	if not nearest_actor.is_empty() and str(nearest_actor.get("id", "")) == enemy_id:
		nearest_actor = {}
		action_button.text = "敌人已击败"
		action_button.disabled = true
	if current_region in ["dungeon", "black_sail"]:
		state.enemy_respawns.erase(_enemy_spawn_key(enemy_id))
		call_deferred("_spawn_world_actors")
		call_deferred("_refresh_waypoint")
		hint_label.text = "%s已被击败，下一层道路已开放。" % defeated.name
		return
	var key = _enemy_spawn_key(enemy_id)
	if state.enemy_respawn_remaining(enemy_id) <= 0.0:
		state.enemy_respawns[key] = _world_time_seconds() + MONSTER_RESPAWN_SECONDS
		state.save_game()
	_schedule_enemy_respawn(enemy_id, MONSTER_RESPAWN_SECONDS)
	hint_label.text = "%s已被击败并消失，%d秒后在原地刷新。" % [defeated.name, int(MONSTER_RESPAWN_SECONDS)]

func _add_actor(kind, id, display_name, position, color, accent, location_id = ""):
	var actor = ActorScript.new()
	actor.position = _world_point(position)
	actor.z_index = 10
	actor.scale = Vector2.ONE * 1.12
	actor.configure(kind, color, accent, id)
	world_layer.add_child(actor)
	var nameplate = Label.new()
	nameplate.text = display_name
	nameplate.position = Vector2(-72, 50)
	nameplate.size = Vector2(144, 31)
	nameplate.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nameplate.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	nameplate.add_theme_font_size_override("font_size", 15)
	nameplate.add_theme_color_override("font_color", Color("fff4d1"))
	nameplate.add_theme_stylebox_override("normal", _style(Color(0.025, 0.055, 0.065, 0.88), 9, Color(GOLD, 0.48), 1, 5))
	actor.add_child(nameplate)
	actors.append({"kind": kind, "id": id, "name": display_name, "node": actor, "location": location_id})

func _spawn_for_location(location_id):
	var overrides = {
		"alisa_hut": Vector2(250, 365), "venice_tavern": Vector2(250, 690),
		"venice_square": Vector2(360, 790), "venice_market": Vector2(450, 700),
		"venice_dock": Vector2(360, 915), "venice_north_gate": Vector2(360, 365),
		"ragusa_dock": Vector2(360, 915), "alexandria_dock": Vector2(360, 915),
		"residential_quarter": Vector2(350, 1045), "venice_mine": Vector2(500, 505),
		"venice_back_hill": Vector2(230, 450), "venice_wildwood": Vector2(500, 820),
		"training_dungeon_1": Vector2(360, 1025), "training_dungeon_2": Vector2(360, 775),
		"training_dungeon_3": Vector2(360, 520), "training_dungeon_4": Vector2(360, 285)
		,"black_sail_1": Vector2(360, 1025), "black_sail_2": Vector2(360, 775),
		"black_sail_3": Vector2(360, 520), "black_sail_4": Vector2(360, 285)
	}
	if overrides.has(location_id):
		return _world_point(overrides[location_id])
	var region = str(region_by_location.get(location_id, current_region))
	var zones = region_zones.get(region, {})
	var lookup_id = location_id
	if not zones.has(lookup_id):
		lookup_id = "venice_dock" if region == "city" else ("residential_quarter" if region == "field" else "training_dungeon_1")
	var point = zones.get(lookup_id, {"point": Vector2(360, 700)}).point
	return Vector2(point.x, clamp(point.y + 72.0 * WORLD_SCALE, 225.0 * WORLD_SCALE, 1070.0 * WORLD_SCALE))

func _build_hud():
	var top = PanelContainer.new()
	top.position = Vector2(14, 16)
	top.size = Vector2(692, 116)
	top.z_index = 50
	top.add_theme_stylebox_override("panel", _style(PANEL, 18, Color(GOLD, 0.62), 2, 13))
	add_child(top)
	var top_box = VBoxContainer.new()
	top_box.add_theme_constant_override("separation", 4)
	top.add_child(top_box)
	var row = HBoxContainer.new()
	top_box.add_child(row)
	location_label = _label("", 19, GOLD)
	location_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(location_label)
	stats_label = _label("", 14, INK)
	row.add_child(stats_label)
	audio_button = _button("♪ 开" if AudioDirector.is_audio_enabled() else "♪ 关", "ghost")
	audio_button.custom_minimum_size = Vector2(66, 42)
	audio_button.add_theme_font_size_override("font_size", 13)
	audio_button.pressed.connect(_toggle_audio)
	row.add_child(audio_button)
	quest_label = _label("", 13, MUTED)
	quest_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	top_box.add_child(quest_label)

	hint_label = _label("摇杆或点击道路移动 · 金色标记是任务方向", 13, INK)
	hint_label.position = Vector2(92, 145)
	hint_label.size = Vector2(536, 43)
	hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hint_label.z_index = 50
	hint_label.add_theme_stylebox_override("normal", _style(Color(0.02, 0.065, 0.075, 0.88), 13, Color(GOLD, 0.42), 1, 8))
	add_child(hint_label)

	action_button = _button("附近没有可互动目标", "primary")
	action_button.position = Vector2(410, 1022)
	action_button.size = Vector2(296, 94)
	action_button.z_index = 55
	action_button.disabled = true
	action_button.pressed.connect(_interact)
	add_child(action_button)

	var menu = HBoxContainer.new()
	menu.position = Vector2(14, 1140)
	menu.size = Vector2(692, 92)
	menu.z_index = 55
	menu.add_theme_constant_override("separation", 7)
	add_child(menu)
	for entry in [
		{"text": "背包", "call": _open_inventory},
		{"text": "任务", "call": _open_quest},
		{"text": "地图", "call": _open_world_map},
		{"text": "航海日志", "call": _open_full_journal}
	]:
		var button = _button(entry.text, "ghost")
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.pressed.connect(entry.call)
		menu.add_child(button)

	joystick = JoystickScript.new()
	joystick.position = Vector2(14, 930)
	joystick.size = Vector2(180, 180)
	joystick.z_index = 60
	joystick.direction_changed.connect(_on_joystick_direction)
	add_child(joystick)

	navigation_button = _button("◆ 任务导航", "gold")
	navigation_button.position = Vector2(410, 930)
	navigation_button.size = Vector2(296, 80)
	navigation_button.z_index = 55
	navigation_button.pressed.connect(_navigate_to_quest)
	add_child(navigation_button)

	waypoint_label = _label("◆ 任务目标", 14, Color("fff1ad"))
	waypoint_label.size = Vector2(150, 38)
	waypoint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	waypoint_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	waypoint_label.z_index = 45
	waypoint_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	waypoint_label.add_theme_stylebox_override("normal", _style(Color(0.28, 0.20, 0.05, 0.88), 11, Color(GOLD, 0.75), 2, 7))
	add_child(waypoint_label)

func _toggle_audio():
	var is_enabled = AudioDirector.toggle_audio()
	if is_instance_valid(audio_button):
		audio_button.text = "♪ 开" if is_enabled else "♪ 关"
	hint_label.text = "背景音乐与音效已开启。" if is_enabled else "背景音乐与音效已关闭。"

func _process(delta):
	if is_instance_valid(overlay):
		return
	var keyboard = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var direction = joystick_direction if joystick_direction.length() > 0.08 else keyboard
	if direction.length() < 0.1 and has_move_target:
		var difference = move_target - player_actor.position
		if difference.length() < 8:
			has_move_target = false
		else:
			direction = difference.normalized()
	elif direction.length() > 0.1:
		has_move_target = false
	var previous_position = player_actor.position
	if direction.length() > 0.05:
		var movement = direction.normalized() * 245.0 * delta
		var next_position = player_actor.position + movement
		next_position.x = clamp(next_position.x, 28.0 * WORLD_SCALE, 692.0 * WORLD_SCALE)
		next_position.y = clamp(next_position.y, 210.0 * WORLD_SCALE, 1080.0 * WORLD_SCALE)
		if _is_walkable(next_position):
			player_actor.position = next_position
		else:
			# Slide along building edges instead of feeling stuck on a corner.
			var horizontal = Vector2(clamp(player_actor.position.x + movement.x, 28.0 * WORLD_SCALE, 692.0 * WORLD_SCALE), player_actor.position.y)
			var vertical = Vector2(player_actor.position.x, clamp(player_actor.position.y + movement.y, 210.0 * WORLD_SCALE, 1080.0 * WORLD_SCALE))
			if abs(movement.x) >= abs(movement.y) and _is_walkable(horizontal):
				player_actor.position = horizontal
			elif _is_walkable(vertical):
				player_actor.position = vertical
			elif _is_walkable(horizontal):
				player_actor.position = horizontal
	if player_actor.position.distance_to(previous_position) > 0.5:
		footstep_timer -= delta
		if footstep_timer <= 0.0:
			AudioDirector.play_sfx("step")
			footstep_timer = 0.34
	else:
		footstep_timer = min(footstep_timer, 0.08)
	player_actor.set_motion(direction if direction.length() > 0.05 else Vector2.ZERO)
	_update_camera(delta)
	_update_nearest_actor()
	_update_zone(false)
	_update_waypoint_screen_position()

func _gui_input(event):
	if is_instance_valid(overlay):
		return
	if event is InputEventScreenTouch and event.pressed:
		_set_move_target(event.position)
		accept_event()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_set_move_target(event.position)
		accept_event()

func _unhandled_input(event):
	# Keep a fallback for non-GUI pointer sources and desktop embedding.
	if is_instance_valid(overlay):
		return
	if event is InputEventScreenTouch and event.pressed:
		_set_move_target(event.position)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_set_move_target(event.position)

func _set_move_target(position):
	if position.y < 195 or position.y > 1125:
		return
	move_target = world_layer.to_local(position)
	has_move_target = true

func _update_camera(delta, snap = false):
	if not is_instance_valid(world_layer) or not is_instance_valid(player_actor):
		return
	var desired = CAMERA_FOCUS - player_actor.position
	desired.x = clamp(desired.x, MAP_SIZE.x - WORLD_SIZE.x, 0.0)
	desired.y = clamp(desired.y, MAP_SIZE.y - WORLD_SIZE.y, 0.0)
	if snap or delta <= 0.0:
		world_layer.position = desired
	else:
		world_layer.position = world_layer.position.lerp(desired, min(1.0, delta * CAMERA_SMOOTH_SPEED))

func _on_joystick_direction(value):
	joystick_direction = value
	if value.length() > 0.08:
		has_move_target = false

func _is_walkable(position):
	for rect in region_obstacles.get(current_region, []):
		if rect.grow(18.0 * WORLD_SCALE).has_point(position):
			return false
	return true

func _update_nearest_actor():
	var best = {}
	var best_distance = 108.0 * WORLD_SCALE
	for entry in actors:
		var distance = player_actor.position.distance_to(entry.node.position)
		entry.node.selected = false
		if distance < best_distance:
			best = entry
			best_distance = distance
	nearest_actor = best
	if nearest_actor.is_empty():
		action_button.text = "靠近人物或敌人后互动"
		action_button.disabled = true
	else:
		nearest_actor.node.selected = true
		action_button.disabled = false
		if nearest_actor.kind == "travel":
			action_button.text = "进入 · %s" % nearest_actor.name
		elif nearest_actor.kind == "discovery":
			action_button.text = "调查 · %s" % nearest_actor.name
		elif nearest_actor.id == "ship_owner" and state.is_trade_unlocked():
			action_button.text = "港口贸易 · 船老板"
		else:
			action_button.text = ("交谈 · " if nearest_actor.kind == "npc" else "挑战 · ") + nearest_actor.name

func _update_zone(force):
	var best_id = ""
	var best_distance = INF
	for location_id in region_zones.get(current_region, {}):
		var zone = region_zones[current_region][location_id]
		var distance = player_actor.position.distance_to(zone.point)
		if distance <= float(zone.radius) and distance < best_distance:
			best_distance = distance
			best_id = location_id
	if best_id == "":
		return
	if current_region in ["dungeon", "black_sail"]:
		var floor_lock = _dungeon_floor_lock(best_id)
		if floor_lock != "":
			hint_label.text = floor_lock
			return
	var state_location = str(state.player.location)
	var same_effective_location = best_id == state_location or (best_id == "venice_dock" and state_location in GameData.TRADE_PORTS)
	if best_id == current_zone and same_effective_location and not force:
		return
	var result = state.arrive_from_2d(best_id)
	if result.ok:
		current_zone = best_id
	_refresh_hud()
	if bool(result.get("quest_completed", false)):
		call_deferred("_show_quest_claim")

func _dungeon_floor_lock(location_id):
	var requirements = {
		"training_dungeon_2": "dungeon_guard",
		"training_dungeon_3": "stone_puppet",
		"training_dungeon_4": "tide_beast",
		"black_sail_2": "corsair_deckhand",
		"black_sail_3": "corsair_raider",
		"black_sail_4": "corsair_guard"
	}
	var required_enemy = str(requirements.get(location_id, ""))
	if required_enemy == "" or bool(state.dungeon_cleared.get(required_enemy, false)):
		return ""
	return "道路被封锁：先击败%s" % GameData.ENEMIES[required_enemy].name

func _refresh_hud():
	var location_id = str(state.player.location)
	var location_name = GameData.LOCATIONS.get(location_id, GameData.LOCATIONS.venice_square).name
	location_label.text = "◆ %s" % location_name
	stats_label.text = "Lv.%d  ♥%d  ◈%d" % [int(state.player.level), int(state.player.hp), int(state.player.silver)]
	var quest = state.get_current_quest()
	if quest.is_empty():
		var bounty = state.get_bounty()
		quest_label.text = "悬赏「%s」  %d/%d" % [bounty.title, state.bounty_progress, int(bounty.need)]
	else:
		quest_label.text = "主线「%s」  %d/%d" % [quest.title, state.quest_progress, int(quest.objective.need)]
	if is_instance_valid(waypoint_label):
		_refresh_waypoint()

func _interact():
	if nearest_actor.is_empty():
		return
	AudioDirector.play_sfx("interact")
	if nearest_actor.kind == "travel":
		_switch_region(str(nearest_actor.id), str(nearest_actor.location))
		return
	var actor_location = str(nearest_actor.get("location", ""))
	if current_region in ["dungeon", "black_sail"]:
		var floor_lock = _dungeon_floor_lock(actor_location)
		if floor_lock != "":
			_show_message("道路尚未开放", floor_lock)
			return
	if actor_location != "" and not (actor_location == "venice_dock" and str(state.player.location) in GameData.TRADE_PORTS):
		var arrival = state.arrive_from_2d(actor_location)
		if arrival.ok:
			current_zone = actor_location
			_refresh_hud()
	if nearest_actor.kind == "discovery":
		var discovery_result = state.claim_discovery(str(nearest_actor.id))
		_spawn_world_actors()
		_refresh_hud()
		if bool(discovery_result.get("ok", false)):
			_show_message("发现·%s" % str(discovery_result.get("name", "隐藏线索")), "%s\n\n获得：%s" % [str(discovery_result.get("lore", "")), str(discovery_result.get("reward_text", ""))])
		else:
			_show_message("无法调查", str(discovery_result.get("message", "这里什么也没有。")))
		return
	if nearest_actor.kind == "npc":
		if nearest_actor.id == "ship_owner" and state.is_trade_unlocked():
			_open_trade_2d()
			return
		var result = state.talk_to(nearest_actor.id)
		_refresh_hud()
		_show_dialog(nearest_actor.id, result)
	else:
		active_enemy_actor = nearest_actor
		var result = state.start_battle(nearest_actor.id)
		if result.ok:
			_open_battle(result)
		else:
			active_enemy_actor = {}
			_show_message("无法战斗", result.message)

func _switch_region(region_id, entrance_location):
	if region_id == "dungeon" and int(state.player.level) < 3:
		_show_message("经验副本尚未开放", "需要达到 Lv.3 才能进入四层经验副本。先完成城外任务提升等级。")
		return
	if region_id == "black_sail" and int(state.player.level) < 6:
		_show_message("黑帆据点尚未开放", "需要达到 Lv.6 并完成威尼斯试炼后才能追踪黑帆航线。")
		return
	var previous_region = current_region
	var dungeon_regions = ["dungeon", "black_sail"]
	if previous_region != region_id and (previous_region in dungeon_regions or region_id in dungeon_regions):
		state.dungeon_cleared = {}
	current_region = region_id
	AudioDirector.set_region(current_region)
	current_zone = ""
	var target_location = entrance_location
	if current_region == "dungeon" and _dungeon_floor_lock(target_location) != "":
		target_location = "training_dungeon_1"
	elif current_region == "black_sail" and _dungeon_floor_lock(target_location) != "":
		target_location = "black_sail_1"
	var arrival = state.arrive_from_2d(target_location)
	map_node.set_region(current_region)
	_spawn_world_actors()
	player_actor.position = _spawn_for_location(target_location)
	_update_camera(0.0, true)
	has_move_target = false
	joystick_direction = Vector2.ZERO
	if is_instance_valid(joystick):
		joystick._set_direction(Vector2.ZERO)
	_refresh_hud()
	_refresh_waypoint()
	if bool(arrival.get("quest_completed", false)):
		call_deferred("_show_quest_claim")

func _show_dialog(npc_id, result):
	if not result.ok:
		_show_message("无法交谈", result.message)
		return
	var content = VBoxContainer.new()
	content.add_theme_constant_override("separation", 16)
	content.add_child(_label(GameData.NPCS[npc_id].name, 26, GOLD))
	content.add_child(_label(GameData.NPCS[npc_id].role, 14, TEAL))
	var dialogue = _label(result.message, 17, INK)
	dialogue.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dialogue.custom_minimum_size.y = 150
	dialogue.add_theme_stylebox_override("normal", _style(Color(0.04, 0.15, 0.18, 0.9), 14, Color(TEAL, 0.4), 1, 18))
	content.add_child(dialogue)
	var close = _button("结束交谈", "primary")
	if bool(result.get("quest_completed", false)):
		close.text = "结束交谈并领取奖励"
		close.pressed.connect(_close_then_claim)
	else:
		close.pressed.connect(_close_overlay)
	content.add_child(close)
	_open_overlay(content)

func _close_then_claim():
	_close_overlay()
	call_deferred("_show_quest_claim")

func _show_quest_claim():
	if not state.quest_can_claim():
		return
	var quest = state.get_current_quest()
	var content = VBoxContainer.new()
	content.add_theme_constant_override("separation", 16)
	content.add_child(_label("任务完成", 28, GOLD))
	content.add_child(_label("「%s」" % quest.title, 20, INK))
	var goal = _label("目标已经达成  %d/%d" % [state.quest_progress, int(quest.objective.need)], 16, TEAL)
	goal.add_theme_stylebox_override("normal", _style(Color(0.04, 0.18, 0.18, 0.9), 12, Color(TEAL, 0.5), 1, 16))
	content.add_child(goal)
	var claim = _button("领取任务奖励", "gold")
	claim.pressed.connect(_claim_quest_2d)
	content.add_child(claim)
	_open_overlay(content, false)

func _claim_quest_2d():
	var result = state.claim_quest()
	_close_overlay()
	_refresh_hud()
	if not result.ok:
		_show_message("领取失败", result.message)
		return
	AudioDirector.play_sfx("reward")
	var content = VBoxContainer.new()
	content.add_theme_constant_override("separation", 16)
	content.add_child(_label("奖励已领取", 27, GOLD))
	content.add_child(_label(str(result.reward_text), 18, TEAL))
	var next_quest = state.get_current_quest()
	if next_quest.is_empty():
		content.add_child(_label("第一卷·黑帆之谜完成！你找回了自己的名字，但亚历山大灯塔下的真相仍在等待。", 17, INK))
	else:
		content.add_child(_label("下一个任务｜%s" % next_quest.title, 20, GOLD))
		var story = _label(next_quest.story, 16, MUTED)
		story.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		content.add_child(story)
	var continue_button = _button("继续2D冒险", "primary")
	continue_button.pressed.connect(_close_overlay)
	content.add_child(continue_button)
	_open_overlay(content)

func _open_battle(view):
	battle_result = {}
	auto_battle_running = false
	AudioDirector.enter_battle()
	var content = VBoxContainer.new()
	content.add_theme_constant_override("separation", 12)
	var heading = HBoxContainer.new()
	content.add_child(heading)
	battle_round_label = _label("遭遇战 · 第%d回合" % int(view.get("round", 1)), 24, GOLD)
	heading.add_child(battle_round_label)
	var spacer = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	heading.add_child(spacer)
	heading.add_child(_label("%s · %s" % [str(view.get("enemy_name", "敌人")), str(view.get("enemy_rank", "普通"))], 17, RED))
	var info_row = HBoxContainer.new()
	info_row.add_theme_constant_override("separation", 12)
	content.add_child(info_row)
	battle_player_info_label = _label("", 14, TEAL)
	battle_player_info_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	battle_player_info_label.add_theme_stylebox_override("normal", _style(Color(0.03, 0.16, 0.17, 0.9), 10, Color(TEAL, 0.55), 1, 9))
	info_row.add_child(battle_player_info_label)
	battle_enemy_info_label = _label("", 14, RED)
	battle_enemy_info_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	battle_enemy_info_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	battle_enemy_info_label.add_theme_stylebox_override("normal", _style(Color(0.18, 0.06, 0.07, 0.9), 10, Color(RED, 0.55), 1, 9))
	info_row.add_child(battle_enemy_info_label)
	battle_intent_label = _label("", 14, GOLD)
	battle_intent_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	battle_intent_label.custom_minimum_size.y = 30
	content.add_child(battle_intent_label)
	var stance_row = HBoxContainer.new()
	stance_row.add_theme_constant_override("separation", 7)
	content.add_child(stance_row)
	battle_stance_buttons = {}
	for stance_entry in [
		{"id": "assault", "name": "猛攻"}, {"id": "balanced", "name": "均衡"},
		{"id": "guard", "name": "坚守"}, {"id": "plunder", "name": "寻宝"}
	]:
		var stance_button = _button(stance_entry.name, "ghost")
		stance_button.custom_minimum_size.y = 46
		stance_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		stance_button.pressed.connect(_set_battle_stance_2d.bind(stance_entry.id))
		stance_row.add_child(stance_button)
		battle_stance_buttons[stance_entry.id] = stance_button
	var supply_row = HBoxContainer.new()
	supply_row.add_theme_constant_override("separation", 8)
	content.add_child(supply_row)
	battle_heal_button = _button("", "ghost")
	battle_heal_button.custom_minimum_size.y = 44
	battle_heal_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	battle_heal_button.pressed.connect(_cycle_auto_heal)
	supply_row.add_child(battle_heal_button)
	battle_cure_button = _button("", "ghost")
	battle_cure_button.custom_minimum_size.y = 44
	battle_cure_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	battle_cure_button.pressed.connect(_toggle_auto_cure)
	supply_row.add_child(battle_cure_button)
	_refresh_battle_info(view)
	_refresh_battle_tactics()
	battle_stage = BattleStageScript.new()
	battle_stage.custom_minimum_size = Vector2(640, 410)
	battle_stage.set_battle_values(view)
	content.add_child(battle_stage)
	battle_log_label = _label("双方在港口石路上展开对峙。", 14, MUTED)
	battle_log_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	battle_log_label.custom_minimum_size.y = 70
	content.add_child(battle_log_label)
	var actions = HBoxContainer.new()
	actions.add_theme_constant_override("separation", 10)
	content.add_child(actions)
	battle_action_button = _button("挥剑攻击", "primary")
	battle_action_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	battle_action_button.pressed.connect(_battle_attack)
	actions.add_child(battle_action_button)
	battle_auto_button = _button("自动战斗", "gold")
	battle_auto_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	battle_auto_button.pressed.connect(_battle_auto)
	actions.add_child(battle_auto_button)
	battle_skill_button = _button("破浪斩 0/3", "ghost")
	battle_skill_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	battle_skill_button.pressed.connect(_battle_skill)
	actions.add_child(battle_skill_button)
	_open_overlay(content, false, Vector2(686, 1080))

func _refresh_battle_info(view):
	if not is_instance_valid(battle_player_info_label) or not is_instance_valid(battle_enemy_info_label):
		return
	var enemy_id = str(view.get("enemy_id", ""))
	var enemy = GameData.ENEMIES.get(enemy_id, {})
	var enemy_level = int(view.get("enemy_level", enemy.get("level", 1)))
	var enemy_rank = str(view.get("enemy_rank", enemy.get("rank", "普通")))
	var enemy_name = str(view.get("enemy_name", enemy.get("name", "敌人")))
	if is_instance_valid(battle_round_label):
		if bool(view.get("battle_over", false)):
			battle_round_label.text = "战斗胜利" if bool(view.get("won", false)) else ("成功撤退" if bool(view.get("fled", false)) else "战斗失败")
		else:
			battle_round_label.text = "遭遇战 · 第%d回合" % int(view.get("round", 1))
	battle_player_info_label.text = "航者 Lv.%d\n体力 %d / %d" % [int(view.get("player_level", state.player.level)), int(view.get("player_hp", state.player.hp)), int(view.get("player_max_hp", state.get_stats().max_hp))]
	battle_enemy_info_label.text = "%s Lv.%d · %s\n体力 %d / %d" % [enemy_name, enemy_level, enemy_rank, int(view.get("enemy_hp", 0)), int(view.get("enemy_max_hp", enemy.get("hp", 1)))]
	if is_instance_valid(battle_intent_label):
		battle_intent_label.text = "敌方意图｜%s" % str(view.get("enemy_intent", "战斗已经结束")) if not bool(view.get("battle_over", false)) else "战斗已经结束"
	if is_instance_valid(battle_skill_button):
		var focus = int(view.get("focus", state.battle_focus()))
		battle_skill_button.text = "破浪斩 %d/3" % focus
		battle_skill_button.disabled = focus < 3 or bool(view.get("battle_over", false)) or auto_battle_running

func _set_battle_stance_2d(stance_id):
	if auto_battle_running or not battle_result.is_empty():
		return
	state.set_battle_stance(stance_id)
	_refresh_battle_tactics()
	if not state.active_battle.is_empty():
		_refresh_battle_info(state.get_battle_view())

func _refresh_battle_tactics():
	var names = {"assault": "猛攻", "balanced": "均衡", "guard": "坚守", "plunder": "寻宝"}
	for stance_id in battle_stance_buttons:
		var button = battle_stance_buttons[stance_id]
		if is_instance_valid(button):
			button.text = ("◆ " if str(state.battle_stance) == str(stance_id) else "") + str(names[stance_id])
	if is_instance_valid(battle_heal_button):
		battle_heal_button.text = "自动补血：关" if int(state.auto_heal_threshold) <= 0 else "自动补血：≤%d%%" % int(state.auto_heal_threshold)
	if is_instance_valid(battle_cure_button):
		battle_cure_button.text = "异常自动解：开" if state.auto_cure_status else "异常自动解：关"

func _cycle_auto_heal():
	if auto_battle_running:
		return
	var values = [35, 55, 0]
	var index = values.find(int(state.auto_heal_threshold))
	state.auto_heal_threshold = values[(index + 1) % values.size()] if index >= 0 else 35
	state.save_game()
	_refresh_battle_tactics()

func _toggle_auto_cure():
	if auto_battle_running:
		return
	state.auto_cure_status = not state.auto_cure_status
	state.save_game()
	_refresh_battle_tactics()

func _battle_attack():
	if auto_battle_running:
		return
	if not battle_result.is_empty():
		_finish_battle_overlay()
		return
	var player_hp_before = int(state.player.hp)
	AudioDirector.play_sfx("attack")
	var result = state.attack_once()
	battle_stage.animate_attack(true)
	if int(result.get("player_hp", player_hp_before)) < player_hp_before:
		AudioDirector.play_sfx("hit")
		battle_stage.animate_attack(false)
	battle_stage.set_battle_values(result)
	_update_battle_result(result)

func _battle_skill():
	if auto_battle_running or not battle_result.is_empty():
		return
	var player_hp_before = int(state.player.hp)
	AudioDirector.play_sfx("skill")
	var result = state.skill_attack()
	if not bool(result.get("ok", false)):
		battle_log_label.text = str(result.get("message", "潮势不足。"))
		return
	battle_stage.animate_attack(true)
	if int(result.get("player_hp", player_hp_before)) < player_hp_before:
		AudioDirector.play_sfx("hit")
		battle_stage.animate_attack(false)
	battle_stage.set_battle_values(result)
	_update_battle_result(result)

func _battle_auto():
	if auto_battle_running:
		return
	if not battle_result.is_empty():
		_finish_battle_overlay()
		return
	auto_battle_running = true
	battle_action_button.disabled = true
	battle_auto_button.disabled = true
	battle_auto_button.text = "自动战斗中…"
	battle_log_label.text = "自动战斗已开启，正在逐回合交战…"
	var safety_rounds = 0
	while auto_battle_running and not state.active_battle.is_empty() and safety_rounds < 40 and is_instance_valid(overlay):
		var supply_result = state.auto_use_battle_supplies()
		if bool(supply_result.get("used", false)):
			AudioDirector.play_sfx("heal")
			battle_log_label.text = "\n".join(supply_result.get("logs", []))
			_refresh_battle_info(state.get_battle_view())
			await get_tree().create_timer(AUTO_BATTLE_READ_DELAY).timeout
		var player_hp_before = int(state.player.hp)
		var should_counter = state.battle_focus() >= 3 and str(state.get_enemy_intent()).begins_with("⚠")
		AudioDirector.play_sfx("skill" if should_counter else "attack")
		var result = state.skill_attack() if should_counter else state.attack_once()
		if not bool(result.get("ok", false)):
			battle_log_label.text = str(result.get("message", "自动战斗中断。"))
			break
		battle_stage.animate_attack(true)
		await get_tree().create_timer(AUTO_BATTLE_HIT_DELAY).timeout
		if int(result.get("player_hp", player_hp_before)) < player_hp_before and is_instance_valid(battle_stage):
			AudioDirector.play_sfx("hit")
			battle_stage.animate_attack(false)
			await get_tree().create_timer(AUTO_BATTLE_HIT_DELAY).timeout
		if not is_instance_valid(battle_stage):
			break
		battle_stage.set_battle_values(result)
		_update_battle_result(result)
		safety_rounds += 1
		if bool(result.get("battle_over", false)):
			break
		await get_tree().create_timer(AUTO_BATTLE_READ_DELAY).timeout
	auto_battle_running = false
	if is_instance_valid(battle_action_button) and battle_result.is_empty():
		battle_action_button.disabled = false
	if is_instance_valid(battle_auto_button) and battle_result.is_empty():
		battle_auto_button.disabled = false
		battle_auto_button.text = "自动战斗"

func _update_battle_result(result):
	_refresh_battle_info(result)
	var logs = result.get("logs", [])
	if not logs.is_empty():
		battle_log_label.text = "\n".join(logs.slice(max(0, logs.size() - 2)))
	if bool(result.get("battle_over", false)):
		battle_result = result
		var won = bool(result.get("won", false))
		var fled = bool(result.get("fled", false))
		var resume_region = "city" if not won and not fled else current_region
		AudioDirector.end_battle(won, fled, resume_region)
		if won:
			if bool(result.get("quest_completed", false)):
				battle_action_button.text = "返回并领取主线奖励"
			elif bool(result.get("bounty_completed", false)):
				battle_action_button.text = "返回并领取悬赏"
			else:
				battle_action_button.text = "返回地图"
		elif fled:
			battle_action_button.text = "返回地图"
		else:
			battle_action_button.text = "返回威尼斯酒馆"
		battle_action_button.disabled = false
		if is_instance_valid(battle_auto_button):
			battle_auto_button.text = "战斗结束"
			battle_auto_button.disabled = true
		if is_instance_valid(battle_skill_button):
			battle_skill_button.disabled = true
		battle_log_label.add_theme_color_override("font_color", GOLD if bool(result.get("won", false)) else RED)
	_refresh_hud()
	if bool(result.get("battle_over", false)) and bool(result.get("won", false)):
		_despawn_defeated_enemy()

func _finish_battle_overlay():
	var should_claim = bool(battle_result.get("quest_completed", false))
	var should_claim_bounty = bool(battle_result.get("bounty_completed", false))
	var lost = bool(battle_result.get("battle_over", false)) and not bool(battle_result.get("won", false)) and not bool(battle_result.get("fled", false))
	var enemy_name = str(battle_result.get("enemy_name", "敌人"))
	_close_overlay()
	if lost:
		_return_to_tavern_after_defeat(enemy_name)
	elif should_claim:
		call_deferred("_show_quest_claim")
	elif should_claim_bounty:
		call_deferred("_show_bounty_claim")

func _show_bounty_claim():
	if not state.bounty_can_claim():
		return
	var bounty = state.get_bounty()
	var content = VBoxContainer.new()
	content.add_theme_constant_override("separation", 16)
	content.add_child(_label("悬赏完成", 28, GOLD))
	content.add_child(_label("「%s」" % bounty.title, 21, INK))
	content.add_child(_label("目标已清理  %d/%d" % [state.bounty_progress, int(bounty.need)], 16, TEAL))
	var claim = _button("领取悬赏奖励", "gold")
	claim.pressed.connect(_claim_bounty_2d)
	content.add_child(claim)
	_open_overlay(content, false)

func _claim_bounty_2d():
	var result = state.claim_bounty()
	_close_overlay()
	_refresh_hud()
	if not bool(result.get("ok", false)):
		_show_message("领取失败", str(result.get("message", "悬赏尚未完成。")))
		return
	AudioDirector.play_sfx("reward")
	var next_bounty = state.get_bounty()
	_show_message("悬赏奖励已领取", "%s\n\n新悬赏｜%s\n%s" % [str(result.message), str(next_bounty.title), str(next_bounty.description)])

func _return_to_tavern_after_defeat(enemy_name):
	_switch_region("city", "venice_tavern")
	var stats = state.get_stats()
	_show_message("战斗失败 · 已返回酒馆", "你被%s击倒。威尼斯巡逻队将你送回老海鸥酒馆，装备和银币没有损失。\n\n当前体力：%d / %d，可以与酒馆老板交谈并休息至完全恢复。" % [enemy_name, int(state.player.hp), int(stats.max_hp)])

func _open_inventory():
	var content = VBoxContainer.new()
	content.add_theme_constant_override("separation", 12)
	content.add_child(_label("冒险背包", 26, GOLD))
	var stats = state.get_stats()
	content.add_child(_label("战力%d  攻击%d  防御%d  速度%d" % [state.get_power(), int(stats.attack), int(stats.defense), int(stats.speed)], 15, TEAL))
	var equipped_names = []
	for slot in ["weapon", "head", "body", "waist", "boots", "charm"]:
		var equipped_id = str(state.equipment.get(slot, ""))
		if equipped_id != "" and GameData.ITEMS.has(equipped_id):
			equipped_names.append(str(GameData.ITEMS[equipped_id].name))
	var equipped_text = "当前装备：%s" % ("、".join(equipped_names) if not equipped_names.is_empty() else "无")
	var equipped_line = _label(equipped_text, 14, MUTED)
	equipped_line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(equipped_line)
	var card_name = "未启用"
	if state.active_card != "" and GameData.ITEMS.has(state.active_card):
		card_name = str(GameData.ITEMS[state.active_card].name)
	content.add_child(_label("当前怪物卡：%s｜同时只能启用1张" % card_name, 14, TEAL))
	if inventory_notice != "":
		var notice = _label(inventory_notice, 14, GOLD)
		notice.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		notice.add_theme_stylebox_override("normal", _style(Color(0.20, 0.14, 0.04, 0.9), 10, Color(GOLD, 0.6), 1, 10))
		content.add_child(notice)
		inventory_notice = ""
	var scroll = ScrollContainer.new()
	scroll.custom_minimum_size.y = 500
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	content.add_child(scroll)
	var items = VBoxContainer.new()
	items.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	items.add_theme_constant_override("separation", 8)
	scroll.add_child(items)
	items.add_child(_label("已装备强化｜贸易银币的主要成长用途", 15, GOLD))
	for slot in ["weapon", "head", "body", "waist", "boots", "charm"]:
		if str(state.equipment.get(slot, "")) != "":
			items.add_child(_equipped_upgrade_card_2d(slot))
	items.add_child(_label("背包物品", 15, GOLD))
	if state.inventory.is_empty():
		items.add_child(_label("背包是空的。", 16, MUTED))
	var item_ids = state.inventory.keys()
	item_ids.sort()
	for item_id in item_ids:
		if not GameData.ITEMS.has(item_id):
			continue
		var item = GameData.ITEMS[item_id]
		items.add_child(_inventory_item_card_2d(item_id, item, int(state.inventory[item_id])))
	var close = _button("返回地图", "primary")
	close.pressed.connect(_close_overlay)
	content.add_child(close)
	_open_overlay(content, true, Vector2(666, 960))

func _equipped_upgrade_card_2d(slot):
	var item_id = str(state.equipment.get(slot, ""))
	var item = GameData.ITEMS[item_id]
	var level = state.equipment_upgrade_level(item_id)
	var card = PanelContainer.new()
	card.add_theme_stylebox_override("panel", _style(Color(0.12, 0.10, 0.04, 0.92), 10, Color(GOLD, 0.38), 1, 10))
	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	card.add_child(row)
	var info = _label("%s｜%s +%d\n%s" % [GameData.SLOT_NAMES[slot], item.name, level, _item_stats_text_2d(item.get("stats", {}))], 13, INK)
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(info)
	var upgrade = _button("已满级" if level >= 3 else "强化 %d银" % state.equipment_upgrade_cost(slot), "gold")
	upgrade.custom_minimum_size = Vector2(142, 56)
	upgrade.disabled = level >= 3 or int(state.player.silver) < state.equipment_upgrade_cost(slot)
	upgrade.pressed.connect(_upgrade_equipped_2d.bind(slot))
	row.add_child(upgrade)
	return card

func _upgrade_equipped_2d(slot):
	var result = state.upgrade_equipped(slot)
	inventory_notice = ("✓ " if bool(result.get("ok", false)) else "！") + str(result.get("message", "强化失败"))
	_refresh_hud()
	_close_overlay()
	if bool(result.get("quest_completed", false)):
		call_deferred("_show_quest_claim")
	else:
		call_deferred("_open_inventory")

func _inventory_item_card_2d(item_id, item, count):
	var card = PanelContainer.new()
	card.add_theme_stylebox_override("panel", _style(Color(0.04, 0.13, 0.16, 0.92), 11, Color(TEAL, 0.3), 1, 12))
	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	card.add_child(row)
	var text_stack = VBoxContainer.new()
	text_stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_stack.add_theme_constant_override("separation", 3)
	row.add_child(text_stack)
	text_stack.add_child(_label("%s  ×%d · %s" % [item.name, count, str(item.rarity)], 15, INK))
	var description = _label(str(item.description), 12, MUTED)
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text_stack.add_child(description)
	if str(item.type) == "equipment":
		text_stack.add_child(_label(_item_stats_text_2d(item.get("stats", {})), 12, TEAL))
	var action = _button("收藏", "ghost")
	action.custom_minimum_size = Vector2(94, 58)
	match str(item.type):
		"equipment":
			action.text = "装备"
			action.pressed.connect(_equip_item_2d.bind(item_id))
		"consumable":
			action.text = "使用"
			action.pressed.connect(_use_item_2d.bind(item_id))
		"mystery":
			action.text = "鉴定" if str(state.player.location) == "venice_market" else "去市场"
			action.pressed.connect(_identify_item_2d)
		"card":
			action.text = "已启用" if str(state.active_card) == str(item_id) else "启用"
			action.disabled = str(state.active_card) == str(item_id)
			action.pressed.connect(_equip_card_2d.bind(item_id))
		_:
			action.disabled = true
	row.add_child(action)
	return card

func _item_stats_text_2d(item_stats):
	var parts = []
	var names = {"max_hp": "体力", "attack": "攻击", "defense": "防御", "speed": "速度"}
	for key in ["max_hp", "attack", "defense", "speed"]:
		if int(item_stats.get(key, 0)) != 0:
			parts.append("%s+%d" % [names[key], int(item_stats[key])])
	return "属性：%s" % ("、".join(parts) if not parts.is_empty() else "无")

func _equip_item_2d(item_id):
	var result = state.equip_item(item_id)
	inventory_notice = ("✓ " if bool(result.ok) else "！") + str(result.message)
	_refresh_hud()
	_close_overlay()
	call_deferred("_open_inventory")

func _use_item_2d(item_id):
	var result = state.use_item(item_id)
	if bool(result.ok):
		AudioDirector.play_sfx("heal")
	inventory_notice = ("✓ " if bool(result.ok) else "！") + str(result.message)
	_refresh_hud()
	_close_overlay()
	call_deferred("_open_inventory")

func _equip_card_2d(item_id):
	var result = state.equip_card(item_id)
	inventory_notice = ("✓ " if bool(result.ok) else "！") + str(result.message)
	_refresh_hud()
	_close_overlay()
	call_deferred("_open_inventory")

func _identify_item_2d():
	if str(state.player.location) != "venice_market":
		_close_overlay()
		_switch_region("city", "venice_market")
		hint_label.text = "已带你来到海风市场，重新打开背包即可鉴定未知道具。"
		return
	var result = state.identify_unknown()
	inventory_notice = ("✓ " if bool(result.ok) else "！") + str(result.message)
	_refresh_hud()
	_close_overlay()
	call_deferred("_open_inventory")

func _open_quest():
	var content = VBoxContainer.new()
	content.add_theme_constant_override("separation", 14)
	content.add_child(_label("航海任务", 26, GOLD))
	var quest = state.get_current_quest()
	if quest.is_empty():
		content.add_child(_label("第一卷·黑帆之谜已完成", 22, GOLD))
		var epilogue = _label("你取回了失去的名字——卡西安。海图指向亚历山大，而威尼斯的悬赏、贸易与副本仍会继续记录你的传奇。\n\n当前称号：%s" % str(state.player.title), 16, TEAL)
		epilogue.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		content.add_child(epilogue)
	else:
		content.add_child(_label(quest.title, 22, INK))
		var story = _label(quest.story, 17, MUTED)
		story.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		story.custom_minimum_size.y = 130
		content.add_child(story)
		content.add_child(_label("当前进度  %d / %d" % [state.quest_progress, int(quest.objective.need)], 18, TEAL))
		if state.quest_can_claim():
			var claim = _button("领取任务奖励", "gold")
			claim.pressed.connect(_claim_quest_2d)
			content.add_child(claim)
	if state.quest_index >= 3:
		var bounty = state.get_bounty()
		content.add_child(_label("城市悬赏｜%s" % bounty.title, 19, GOLD))
		var bounty_copy = _label("%s\n进度 %d/%d｜奖励 %d银币、%d经验" % [bounty.description, state.bounty_progress, int(bounty.need), int(bounty.silver) + state.bounty_cycles * 8, int(bounty.exp)], 15, MUTED)
		bounty_copy.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		content.add_child(bounty_copy)
		if state.bounty_can_claim():
			var bounty_claim = _button("领取悬赏奖励", "gold")
			bounty_claim.pressed.connect(_claim_bounty_2d)
			content.add_child(bounty_claim)
	var close = _button("返回地图", "primary")
	close.pressed.connect(_close_overlay)
	content.add_child(close)
	_open_overlay(content)

func _quest_navigation_target():
	var quest = state.get_current_quest()
	if quest.is_empty():
		var bounty = state.get_bounty()
		var bounty_location = "venice_square"
		for location_id in GameData.LOCATIONS:
			if str(bounty.target) in GameData.LOCATIONS[location_id].enemies:
				bounty_location = str(location_id)
				break
		return {
			"region": str(region_by_location.get(bounty_location, "city")),
			"location": bounty_location,
			"actor_id": str(bounty.target),
			"name": "悬赏·%s" % GameData.ENEMIES[str(bounty.target)].name
		}
	var objective = quest.objective
	var target_location = ""
	if objective.type == "visit":
		target_location = str(objective.target)
	elif objective.type == "talk":
		for location_id in GameData.LOCATIONS:
			if str(objective.target) in GameData.LOCATIONS[location_id].npcs:
				target_location = location_id
				break
	elif objective.type == "kill":
		for location_id in GameData.LOCATIONS:
			if str(objective.target) in GameData.LOCATIONS[location_id].enemies:
				target_location = location_id
				break
	elif objective.type in ["trade_buy", "trade_sell", "upgrade_ship"]:
		target_location = str(state.player.location) if str(state.player.location) in GameData.TRADE_PORTS else "venice_dock"
	elif objective.type == "upgrade_equipment":
		target_location = str(state.player.location)
	if target_location == "training_dungeon_4":
		if not bool(state.dungeon_cleared.get("dungeon_guard", false)):
			return {"region": "dungeon", "location": "training_dungeon_1", "actor_id": "dungeon_guard", "name": "一层训练卫兵"}
		if not bool(state.dungeon_cleared.get("stone_puppet", false)):
			return {"region": "dungeon", "location": "training_dungeon_2", "actor_id": "stone_puppet", "name": "二层石傀儡"}
		if not bool(state.dungeon_cleared.get("tide_beast", false)):
			return {"region": "dungeon", "location": "training_dungeon_3", "actor_id": "tide_beast", "name": "三层潮汐兽"}
	if target_location == "":
		target_location = "venice_square"
	var actor_id = "" if objective.type == "visit" else str(objective.target)
	return {
		"region": str(region_by_location.get(target_location, "city")),
		"location": target_location, "actor_id": actor_id,
		"name": GameData.objective_name(objective)
	}

func _refresh_waypoint():
	if not is_instance_valid(waypoint_label) or not is_instance_valid(navigation_button):
		return
	var target = _quest_navigation_target()
	navigation_button.text = "◆ 导航 · %s" % target.name
	if str(target.region) != current_region:
		waypoint_world_target = Vector2.ZERO
		waypoint_label.visible = false
		hint_label.text = "任务目标在%s，点击“任务导航”快速前往" % _region_name(str(target.region))
		return
	var target_position = Vector2.ZERO
	for entry in actors:
		if str(entry.id) == str(target.actor_id) and target.actor_id != "":
			target_position = entry.node.position
			break
	if target_position == Vector2.ZERO:
		var zone = region_zones.get(current_region, {}).get(str(target.location), {})
		if not zone.is_empty():
			target_position = zone.point
	if target_position == Vector2.ZERO:
		waypoint_world_target = Vector2.ZERO
		waypoint_label.visible = false
		return
	waypoint_label.visible = true
	waypoint_label.text = "◆ %s" % target.name
	waypoint_world_target = target_position
	_update_waypoint_screen_position()
	hint_label.text = "金色标记：%s｜也可点击任务导航" % target.name

func _update_waypoint_screen_position():
	if not is_instance_valid(waypoint_label) or not waypoint_label.visible or waypoint_world_target == Vector2.ZERO:
		return
	var screen_position = world_layer.position + waypoint_world_target
	waypoint_label.position = Vector2(clamp(screen_position.x - 75.0, 8.0, 562.0), clamp(screen_position.y - 92.0, 195.0, 1040.0))

func _navigate_to_quest():
	var quest = state.get_current_quest()
	if not quest.is_empty() and str(quest.objective.type) == "visit" and str(quest.objective.target) in GameData.TRADE_PORTS:
		_open_trade_2d()
		return
	if not quest.is_empty() and str(quest.objective.type) == "upgrade_equipment":
		_open_inventory()
		return
	if not quest.is_empty() and str(quest.objective.type) in ["trade_buy", "trade_sell", "upgrade_ship"]:
		_open_trade_2d()
		return
	var target = _quest_navigation_target()
	_switch_region(str(target.region), str(target.location))
	if is_instance_valid(overlay):
		return
	var target_position = Vector2.ZERO
	for entry in actors:
		if str(entry.id) == str(target.actor_id) and target.actor_id != "":
			target_position = entry.node.position
			break
	if target_position == Vector2.ZERO:
		var zone = region_zones.get(current_region, {}).get(str(target.location), {})
		if not zone.is_empty():
			target_position = zone.point
	if target_position != Vector2.ZERO:
		move_target = target_position
		has_move_target = true
		hint_label.text = "正在前往：%s" % target.name

func _open_world_map():
	var content = VBoxContainer.new()
	content.add_theme_constant_override("separation", 10)
	content.add_child(_label("2D区域地图", 26, GOLD))
	var guide = _label("所有主线地点都可以从这里进入。带锁的副本楼层需要逐层击败守卫。", 15, MUTED)
	guide.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(guide)
	var scroll = ScrollContainer.new()
	scroll.custom_minimum_size.y = 520
	content.add_child(scroll)
	var list = VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 8)
	scroll.add_child(list)
	for group in [
		{"title": "威尼斯城内", "locations": ["alisa_hut", "venice_tavern", "venice_square", "venice_market", "venice_dock", "venice_north_gate"]},
		{"title": "威尼斯城外", "locations": ["residential_quarter", "venice_mine", "venice_back_hill", "venice_wildwood"]},
		{"title": "四层经验副本", "locations": ["training_dungeon_1", "training_dungeon_2", "training_dungeon_3", "training_dungeon_4"]}
		,{"title": "黑帆据点", "locations": ["black_sail_1", "black_sail_2", "black_sail_3", "black_sail_4"]}
	]:
		list.add_child(_label(group.title, 17, TEAL))
		for location_id in group.locations:
			var destination = _button(GameData.LOCATIONS[location_id].name, "ghost")
			var is_training = str(location_id).begins_with("training_dungeon_")
			var is_black_sail = str(location_id).begins_with("black_sail_")
			var lock_text = _dungeon_floor_lock(location_id) if is_training or is_black_sail else ""
			destination.disabled = lock_text != "" or (is_training and int(state.player.level) < 3) or (is_black_sail and (int(state.player.level) < 6 or state.quest_index < 12))
			destination.tooltip_text = lock_text
			destination.pressed.connect(_travel_to_location.bind(location_id))
			list.add_child(destination)
	var close = _button("返回地图", "primary")
	close.pressed.connect(_close_overlay)
	content.add_child(close)
	_open_overlay(content, true, Vector2(666, 960))

func _travel_to_location(location_id):
	var region = str(region_by_location.get(location_id, "city"))
	_close_overlay()
	call_deferred("_switch_region", region, location_id)

func _region_name(region_id):
	match region_id:
		"field": return "威尼斯城外"
		"dungeon": return "四层经验副本"
		"black_sail": return "黑帆据点"
		_: return "威尼斯城内"

func _open_trade_2d():
	if not state.is_trade_unlocked():
		_show_message("港口尚未开放", "完成威尼斯四层试炼后，船老板会将贸易船海燕号交给你。")
		return
	if not GameData.TRADE_PORTS.has(state.player.location):
		state.player.location = "venice_dock"
	var port_id = str(state.player.location)
	var port = GameData.TRADE_PORTS[port_id]
	var market_event = GameData.trade_event(state.trade_day)
	var content = VBoxContainer.new()
	content.add_theme_constant_override("separation", 10)
	content.add_child(_label("%s港口市场" % port.name, 25, GOLD))
	content.add_child(_label("第%d日 · 银币%d · 货舱%d/%d · 船速Lv.%d · 护甲Lv.%d" % [state.trade_day, int(state.player.silver), state.cargo_used(), state.cargo_capacity(), int(state.ship.speed), int(state.ship.get("armor", 0))], 14, TEAL))
	var scroll = ScrollContainer.new()
	scroll.custom_minimum_size.y = 560
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	content.add_child(scroll)
	var list = VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 8)
	scroll.add_child(list)
	var event_copy = _label("今日行情｜%s\n%s" % [market_event.name, market_event.description], 14, GOLD)
	event_copy.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	event_copy.add_theme_stylebox_override("normal", _style(Color(0.18, 0.12, 0.03, 0.92), 10, Color(GOLD, 0.55), 1, 10))
	list.add_child(event_copy)
	var opportunity = state.best_trade_opportunity()
	if not opportunity.is_empty():
		var good = GameData.TRADE_GOODS[str(opportunity.good_id)]
		var destination = GameData.TRADE_PORTS[str(opportunity.destination)]
		var forecast = _label("商会推荐｜%s → %s\n按满货舱%d件估算，%d日后净利约%d银币（行情会随日期波动）" % [good.name, destination.name, int(opportunity.units), int(opportunity.days), int(opportunity.total_profit)], 13, TEAL)
		forecast.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		forecast.add_theme_stylebox_override("normal", _style(Color(0.03, 0.17, 0.15, 0.92), 10, Color(TEAL, 0.5), 1, 10))
		list.add_child(forecast)
	var contract = HBoxContainer.new()
	contract.add_theme_constant_override("separation", 8)
	var contract_target = state.trade_contract_target()
	var contract_reward = 90 + state.trade_contract_count * 35
	var contract_info = _label("商会委托·第%d轮｜贸易净利润达到%d\n进度 %d/%d · 奖励%d银币与未知道具" % [state.trade_contract_count + 1, contract_target, state.trade_contract_progress(), contract_target, contract_reward], 13, INK)
	contract_info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	contract.add_child(contract_info)
	var contract_claim = _button("领取", "gold")
	contract_claim.disabled = not state.trade_contract_can_claim()
	contract_claim.pressed.connect(_claim_trade_contract_2d)
	contract.add_child(contract_claim)
	list.add_child(contract)
	for good_id in GameData.TRADE_GOODS:
		var good = GameData.TRADE_GOODS[good_id]
		var row = HBoxContainer.new()
		row.add_theme_constant_override("separation", 7)
		var info = _label("%s\n买%d / 卖%d · 持有%d" % [good.name, state.trade_buy_price(good_id), state.trade_sell_price(good_id), int(state.cargo.get(good_id, 0))], 14, INK)
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(info)
		var buy = _button("买1", "primary")
		buy.disabled = state.cargo_used() + int(good.space) > state.cargo_capacity() or int(state.player.silver) < state.trade_buy_price(good_id)
		buy.pressed.connect(_trade_buy_2d.bind(good_id))
		row.add_child(buy)
		var sell = _button("卖1", "ghost")
		sell.disabled = int(state.cargo.get(good_id, 0)) <= 0
		sell.pressed.connect(_trade_sell_2d.bind(good_id))
		row.add_child(sell)
		var card = PanelContainer.new()
		card.add_theme_stylebox_override("panel", _style(Color(0.04, 0.13, 0.16, 0.92), 10, Color(TEAL, 0.3), 1, 10))
		card.add_child(row)
		list.add_child(card)
	list.add_child(_label("选择航线", 16, GOLD))
	for destination in GameData.TRADE_PORTS:
		if destination == port_id:
			continue
		var route = GameData.trade_route(port_id, destination)
		var days = max(1, int(route.days) - (int(state.ship.speed) - 1))
		var card_risk_bonus = 4 if state.active_card == "corsair_card" else 0
		var risk = max(4, int(route.get("risk", 15)) - int(state.ship.get("armor", 0)) * 6 - card_risk_bonus)
		var sail = _button("启航前往%s · %d日 · %d银币 · 风险%d%%" % [GameData.TRADE_PORTS[destination].name, days, int(route.fee), risk], "gold")
		sail.disabled = int(state.player.silver) < int(route.fee)
		sail.pressed.connect(_trade_sail_2d.bind(destination))
		list.add_child(sail)
	list.add_child(_label("船只改造", 16, GOLD))
	for upgrade_entry in [
		{"id": "hold", "text": "扩建货舱 +6"},
		{"id": "speed", "text": "升级船帆 -1日"},
		{"id": "armor", "text": "加固船体 -6%风险"}
	]:
		var upgrade_button = _button(upgrade_entry.text, "ghost")
		upgrade_button.disabled = (upgrade_entry.id == "hold" and state.cargo_capacity() >= 30) or (upgrade_entry.id == "speed" and int(state.ship.speed) >= 4) or (upgrade_entry.id == "armor" and int(state.ship.get("armor", 0)) >= 3)
		upgrade_button.pressed.connect(_trade_upgrade_2d.bind(upgrade_entry.id))
		list.add_child(upgrade_button)
	var close = _button("返回港口地图", "primary")
	close.pressed.connect(_close_overlay)
	content.add_child(close)
	_open_overlay(content, true, Vector2(666, 980))

func _trade_buy_2d(good_id):
	var result = state.buy_cargo(good_id)
	_refresh_hud()
	_close_overlay()
	if bool(result.get("quest_completed", false)):
		call_deferred("_show_quest_claim")
	else:
		call_deferred("_open_trade_2d")

func _trade_sell_2d(good_id):
	var result = state.sell_cargo(good_id)
	_refresh_hud()
	_close_overlay()
	if bool(result.get("quest_completed", false)):
		call_deferred("_show_quest_claim")
	else:
		call_deferred("_open_trade_2d")

func _trade_upgrade_2d(kind):
	var result = state.upgrade_ship(kind)
	_refresh_hud()
	_close_overlay()
	if bool(result.get("quest_completed", false)):
		call_deferred("_show_quest_claim")
	elif bool(result.get("ok", false)):
		call_deferred("_open_trade_2d")
	else:
		_show_message("改造失败", str(result.get("message", "无法改造船只")))

func _claim_trade_contract_2d():
	var result = state.claim_trade_contract()
	if bool(result.get("ok", false)):
		AudioDirector.play_sfx("reward")
	_refresh_hud()
	_close_overlay()
	_show_message("商会委托", str(result.get("message", "领取失败")))

func _trade_sail_2d(destination):
	var result = state.sail_to(destination)
	if bool(result.get("ok", false)):
		AudioDirector.play_sfx("sail")
		_spawn_world_actors()
		player_actor.position = _spawn_for_location(str(state.player.location))
		_update_camera(0.0, true)
	_refresh_hud()
	_close_overlay()
	if bool(result.get("quest_completed", false)):
		hint_label.text = str(result.get("message", "航行抵达"))
		call_deferred("_show_quest_claim")
	elif result.ok:
		_show_message("航行抵达", result.message)
	else:
		_show_message("无法启航", result.message)

func _open_full_journal():
	state.save_game()
	get_tree().change_scene_to_file("res://scenes/main.tscn")

func _show_message(title, message):
	var content = VBoxContainer.new()
	content.add_theme_constant_override("separation", 18)
	content.add_child(_label(title, 26, GOLD))
	var copy = _label(message, 17, INK)
	copy.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	copy.custom_minimum_size.y = 140
	content.add_child(copy)
	var close = _button("知道了", "primary")
	close.pressed.connect(_close_overlay)
	content.add_child(close)
	_open_overlay(content)

func _open_overlay(content, allow_close = true, panel_size = Vector2(660, 760)):
	if is_instance_valid(overlay):
		overlay.queue_free()
	overlay = null
	overlay = ColorRect.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.color = Color(0.008, 0.025, 0.035, 0.88)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.z_index = 100
	add_child(overlay)
	var center = CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(center)
	var panel = PanelContainer.new()
	panel.custom_minimum_size = panel_size
	panel.add_theme_stylebox_override("panel", _style(PANEL, 20, Color(TEAL, 0.7), 2, 20))
	center.add_child(panel)
	var box = VBoxContainer.new()
	box.add_theme_constant_override("separation", 14)
	panel.add_child(box)
	if allow_close:
		var close_row = HBoxContainer.new()
		box.add_child(close_row)
		var filler = Control.new()
		filler.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		close_row.add_child(filler)
		var close = _button("关闭", "ghost")
		close.pressed.connect(_close_overlay)
		close_row.add_child(close)
	box.add_child(content)

func _close_overlay():
	auto_battle_running = false
	if is_instance_valid(overlay):
		overlay.queue_free()
	overlay = null
	battle_stage = null
	battle_log_label = null
	battle_action_button = null
	battle_auto_button = null
	battle_round_label = null
	battle_player_info_label = null
	battle_enemy_info_label = null
	battle_intent_label = null
	battle_stance_buttons = {}
	battle_heal_button = null
	battle_cure_button = null

func _label(text, font_size, color):
	var label = Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label

func _button(text, kind = "primary"):
	var button = Button.new()
	button.pressed.connect(func(): AudioDirector.play_sfx("ui"))
	button.text = text
	button.custom_minimum_size.y = 62
	button.add_theme_font_size_override("font_size", 16)
	var normal = Color(0.04, 0.15, 0.18, 0.96)
	var border = Color(TEAL, 0.55)
	var font = INK
	if kind == "primary":
		normal = Color(0.05, 0.34, 0.32, 0.98)
		border = TEAL
	elif kind == "gold":
		normal = Color(0.38, 0.27, 0.08, 0.98)
		border = GOLD
		font = Color("ffe8aa")
	button.add_theme_color_override("font_color", font)
	button.add_theme_color_override("font_disabled_color", Color("65777b"))
	button.add_theme_stylebox_override("normal", _style(normal, 12, border, 1, 10))
	button.add_theme_stylebox_override("hover", _style(normal.lightened(0.1), 12, border.lightened(0.15), 1, 10))
	button.add_theme_stylebox_override("pressed", _style(normal.darkened(0.1), 12, border, 1, 10))
	button.add_theme_stylebox_override("disabled", _style(Color(0.025, 0.07, 0.08, 0.85), 12, Color(0.15, 0.22, 0.23, 0.5), 1, 10))
	return button

func _style(color, radius, border_color = Color.TRANSPARENT, border_width = 0, padding = 0):
	var style = StyleBoxFlat.new()
	style.bg_color = color
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_left = radius
	style.corner_radius_bottom_right = radius
	style.border_width_left = border_width
	style.border_width_right = border_width
	style.border_width_top = border_width
	style.border_width_bottom = border_width
	style.border_color = border_color
	style.content_margin_left = padding
	style.content_margin_right = padding
	style.content_margin_top = padding
	style.content_margin_bottom = padding
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.28)
	style.shadow_size = 4
	style.shadow_offset = Vector2(0, 3)
	return style
