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
const SailingMapScript = preload("res://scripts/sailing_map_2d.gd")
const SeaWorldMapScript = preload("res://scripts/sea_world_2d.gd")
const ActorScript = preload("res://scripts/actor_2d.gd")
const BattleStageScript = preload("res://scripts/battle_stage_2d.gd")
const JoystickScript = preload("res://scripts/virtual_joystick.gd")
const ItemIconScript = preload("res://scripts/item_icon_2d.gd")
const PlayerPortraitTexture = preload("res://assets/art/characters/player_walk_v1.png")
const PlayerShipTexture = preload("res://assets/art/ships/player_ship_atlas_v1.png")
const MONSTER_RESPAWN_SECONDS = GameState.ENEMY_RESPAWN_SECONDS
const MONSTER_RESPAWN_RETRY_SECONDS = 1.5
const MONSTER_RESPAWN_SAFE_DISTANCE = 170.0
const AUTO_BATTLE_HIT_DELAY = 0.16
const AUTO_BATTLE_READ_DELAY = 0.30
const NAVIGATION_GRID_SIZE = 42.0
const NAVIGATION_REACH_DISTANCE = 12.0
const OVERLAY_DRAG_THRESHOLD = 10.0
const SEA_PIRATE_AGGRO_RADIUS = 380.0
const SEA_MONSTER_AGGRO_RADIUS = 330.0
const SEA_HARBOR_GUARD_RADIUS = 155.0
const SEA_ENCOUNTER_DISTANCE = 82.0

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
	,"wreck_crab": {"region": "white_whale", "name": "覆甲礁蟹", "position": Vector2(360, 930), "color": Color("536f72"), "accent": Color("d7c58b"), "location": "white_whale_1"}
	,"drowned_sailor": {"region": "white_whale", "name": "溺潮水手", "position": Vector2(360, 680), "color": Color("315b67"), "accent": Color("79cbd0"), "location": "white_whale_2"}
	,"fog_siren": {"region": "white_whale", "name": "雾歌海妖", "position": Vector2(360, 425), "color": Color("55718b"), "accent": Color("b5e8e4"), "location": "white_whale_3"}
	,"abyss_siren": {"region": "white_whale", "name": "深渊海妖·涅瑞娅", "position": Vector2(360, 225), "color": Color("203e61"), "accent": Color("6be1d3"), "location": "white_whale_4"}
	,"basin_leviathan": {"region": "legacy", "name": "北河吞金兽", "position": Vector2(360, 500), "color": Color("756332"), "accent": GOLD, "location": "legacy_basin"}
	,"nine_tail_fox": {"region": "legacy", "name": "九尾灯妖·妲罗", "position": Vector2(360, 500), "color": Color("8b4566"), "accent": Color("ffb36d"), "location": "legacy_changan"}
	,"earth_demon_king": {"region": "legacy", "name": "地魔王·摩罗", "position": Vector2(360, 500), "color": Color("594637"), "accent": Color("d0a557"), "location": "legacy_earth"}
	,"tira_guardian": {"region": "legacy", "name": "蒂拉守剑人", "position": Vector2(360, 500), "color": Color("3e6673"), "accent": Color("8ce6dc"), "location": "legacy_tira"}
	,"celestial_demon_general": {"region": "legacy", "name": "天魔将·破军", "position": Vector2(360, 500), "color": Color("4e376f"), "accent": Color("d98cff"), "location": "legacy_demon_legend"}
	,"jade_dream_queen": {"region": "legacy", "name": "织梦妖后", "position": Vector2(360, 500), "color": Color("396b63"), "accent": Color("a5f0c8"), "location": "legacy_jade"}
	,"black_furnace_lord": {"region": "legacy", "name": "黑炉领主", "position": Vector2(360, 500), "color": Color("602f2b"), "accent": Color("ff845e"), "location": "legacy_fire"}
	,"returned_demon_king": {"region": "legacy", "name": "归来天魔王", "position": Vector2(360, 500), "color": Color("38265f"), "accent": Color("cb8aff"), "location": "legacy_return"}
	,"clockwork_tailor": {"region": "legacy", "name": "傀儡天工师", "position": Vector2(360, 500), "color": Color("5f594b"), "accent": Color("f0c66d"), "location": "legacy_shears"}
	,"tide_void_emperor": {"region": "legacy", "name": "潮虚帝", "position": Vector2(360, 500), "color": Color("192c52"), "accent": Color("55f0df"), "location": "legacy_seal"}
	,"coastal_pirate": {"region": "sea", "name": "近海海盗", "position": Vector2(360, 687), "color": Color("5b3540"), "accent": RED, "location": ""}
	,"reef_serpent": {"region": "sea", "name": "礁海长蛇", "position": Vector2(360, 687), "color": Color("326f72"), "accent": Color("72e0c7"), "location": ""}
	,"ocean_raider": {"region": "sea", "name": "远洋掠夺者", "position": Vector2(360, 687), "color": Color("443547"), "accent": GOLD, "location": ""}
	,"abyss_kraken": {"region": "sea", "name": "深海巨章", "position": Vector2(360, 687), "color": Color("493567"), "accent": Color("d18cf0"), "location": ""}
	,"black_flag_privateer": {"region": "sea", "name": "黑旗私掠舰", "position": Vector2(360, 687), "color": Color("252a3d"), "accent": RED, "location": ""}
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
var currency_label
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
var enemy_respawn_markers = {}
var current_zone = ""
var current_region = "city"
var joystick
var joystick_direction = Vector2.ZERO
var waypoint_label
var waypoint_world_target = Vector2.ZERO
var navigation_button
var inventory_notice = ""
var settings_button
var footstep_timer = 0.0
var task_navigation_active = false
var task_navigation_target = {}
var task_navigation_portal = {}
var task_navigation_path = PackedVector2Array()
var task_navigation_path_index = 0
var task_navigation_open_service = ""
var sailing_map
var sailing_destination = ""
var sailing_route_label
var sailing_confirm_button
var sailing_transfer_button
var sea_save_timer = 0.0
var overlay_scroll
var overlay_drag_pointer = -99
var overlay_drag_distance = 0.0
var overlay_dragging = false

var region_by_location = {
	"alisa_hut": "city", "venice_tavern": "city", "venice_square": "city",
	"venice_market": "city", "venice_dock": "city", "venice_north_gate": "city",
	"ragusa_dock": "city", "alexandria_dock": "city", "malta_dock": "city",
	"cape_town_dock": "city", "quanzhou_dock": "city", "athens_dock": "city", "yangzhou_dock": "city", "amsterdam_dock": "city",
	"residential_quarter": "field", "venice_mine": "field", "venice_back_hill": "field", "venice_wildwood": "field",
	"training_dungeon_1": "dungeon", "training_dungeon_2": "dungeon", "training_dungeon_3": "dungeon", "training_dungeon_4": "dungeon"
	,"black_sail_1": "black_sail", "black_sail_2": "black_sail", "black_sail_3": "black_sail", "black_sail_4": "black_sail"
	,"white_whale_1": "white_whale", "white_whale_2": "white_whale", "white_whale_3": "white_whale", "white_whale_4": "white_whale"
	,"legacy_basin": "legacy", "legacy_changan": "legacy", "legacy_earth": "legacy", "legacy_tira": "legacy", "legacy_demon_legend": "legacy",
	"legacy_jade": "legacy", "legacy_fire": "legacy", "legacy_return": "legacy", "legacy_shears": "legacy", "legacy_seal": "legacy"
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
	},
	"white_whale": {
		"white_whale_1": {"point": Vector2(360, 970), "radius": 115},
		"white_whale_2": {"point": Vector2(360, 720), "radius": 105},
		"white_whale_3": {"point": Vector2(360, 465), "radius": 105},
		"white_whale_4": {"point": Vector2(360, 210), "radius": 115}
	},
	"legacy": {}
}

var region_obstacles = {
	"city": [Rect2(20, 160, 170, 190), Rect2(20, 730, 210, 190), Rect2(530, 160, 170, 230), Rect2(235, 25, 80, 200), Rect2(405, 25, 80, 200)],
	"field": [Rect2(495, 135, 225, 285), Rect2(20, 835, 235, 195), Rect2(465, 815, 235, 205)],
	"dungeon": [Rect2(0, 285, 295, 58), Rect2(425, 285, 295, 58), Rect2(0, 540, 295, 58), Rect2(425, 540, 295, 58), Rect2(0, 795, 295, 58), Rect2(425, 795, 295, 58)],
	"black_sail": [Rect2(0, 285, 295, 58), Rect2(425, 285, 295, 58), Rect2(0, 540, 295, 58), Rect2(425, 540, 295, 58), Rect2(0, 795, 295, 58), Rect2(425, 795, 295, 58)],
	"white_whale": [Rect2(0, 285, 295, 58), Rect2(425, 285, 295, 58), Rect2(0, 540, 295, 58), Rect2(425, 540, 295, 58), Rect2(0, 795, 295, 58), Rect2(425, 795, 295, 58)]
	,"legacy": [Rect2(0, 285, 250, 58), Rect2(470, 285, 250, 58), Rect2(0, 760, 250, 58), Rect2(470, 760, 250, 58)]
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
	current_region = "sea" if not state.active_voyage.is_empty() else str(region_by_location.get(str(state.player.location), "city"))
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
	map_node = SeaWorldMapScript.new() if current_region == "sea" else WorldMapScript.new()
	if current_region == "sea":
		map_node.configure(state.active_voyage)
	else:
		map_node.set_region(current_region)
		if current_region == "city":
			map_node.set_city_port(_active_city_port_id())
	world_layer.add_child(map_node)
	player_actor = ActorScript.new()
	player_actor.z_index = 10
	player_actor.configure("player", Color("278e93"), GOLD, "player_ship" if current_region == "sea" else "player")
	if current_region == "sea":
		player_actor.set_ship_hull(str(state.ship.get("hull_id", "sea_swallow")))
	player_actor.scale = Vector2.ONE * (1.28 if current_region == "sea" else 1.12)
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
func _active_city_port_id():
	var location_id = str(state.player.location)
	return location_id if GameData.TRADE_PORTS.has(location_id) else "venice_dock"

func _world_point(point):
	return Vector2(point) * WORLD_SCALE

func _world_rect(rect):
	return Rect2(rect.position * WORLD_SCALE, rect.size * WORLD_SCALE)

func _active_world_size():
	if current_region == "sea" and is_instance_valid(map_node) and map_node.has_method("get_world_size"):
		return Vector2(map_node.get_world_size())
	return WORLD_SIZE

func _sea_origin_position():
	return Vector2(map_node.get_origin_position()) if is_instance_valid(map_node) and map_node.has_method("get_origin_position") else SeaWorldMapScript.DEFAULT_ORIGIN_POSITION

func _sea_destination_position():
	return Vector2(map_node.get_destination_position()) if is_instance_valid(map_node) and map_node.has_method("get_destination_position") else SeaWorldMapScript.DEFAULT_DESTINATION_POSITION

func _sea_treasure_position():
	return Vector2(map_node.get_treasure_position()) if is_instance_valid(map_node) and map_node.has_method("get_treasure_position") else SeaWorldMapScript.DEFAULT_TREASURE_POSITION

func _sea_storm_position():
	return Vector2(map_node.get_storm_position()) if is_instance_valid(map_node) and map_node.has_method("get_storm_position") else SeaWorldMapScript.DEFAULT_STORM_POSITION

func _sea_storm_radius():
	return float(map_node.get_storm_radius()) if is_instance_valid(map_node) and map_node.has_method("get_storm_radius") else SeaWorldMapScript.DEFAULT_STORM_RADIUS

func _spawn_world_actors():
	for entry in actors:
		if is_instance_valid(entry.node):
			entry.node.queue_free()
	for marker in enemy_respawn_markers.values():
		if is_instance_valid(marker):
			marker.queue_free()
	actors = []
	enemy_respawn_markers = {}
	nearest_actor = {}
	if current_region == "sea":
		if state.active_voyage.is_empty():
			return
		var origin_id = str(state.active_voyage.origin)
		var destination_id = str(state.active_voyage.destination)
		for port_id in Array(state.active_voyage.get("unlocked_ports", [origin_id, destination_id])):
			var resolved_port = str(port_id)
			var port_position = GameData.sea_port_position(resolved_port)
			var port_label = ("计划靠港 · " if resolved_port == destination_id else ("返航 · " if resolved_port == origin_id else "可改靠 · ")) + str(GameData.TRADE_PORTS[resolved_port].name)
			_add_actor("sea_port", resolved_port, port_label, port_position / WORLD_SCALE, Color("4b806d") if resolved_port != origin_id else Color("4c6871"), GOLD if resolved_port == destination_id else TEAL, resolved_port)
		for encounter in Array(state.active_voyage.get("encounters", [])):
			if bool(encounter.get("defeated", false)):
				continue
			var enemy_id = str(encounter.get("enemy_id", "coastal_pirate"))
			var spawn = ENEMY_SPAWNS.get(enemy_id, ENEMY_SPAWNS.coastal_pirate)
			var sea_position = Vector2(float(encounter.get("x", GameData.SEA_WORLD_WIDTH * 0.5)), float(encounter.get("y", GameData.sea_route_position(int(state.active_voyage.get("distance_nm", 1000)), 0.5).y)))
			var threat_level = int(encounter.get("threat_level", GameData.ENEMIES[enemy_id].level))
			var enemy_label = "%s · Lv.%d" % [str(GameData.ENEMIES[enemy_id].name), threat_level]
			_add_actor("enemy", enemy_id, enemy_label, sea_position / WORLD_SCALE, spawn.color, spawn.accent, "", {"encounter_id": str(encounter.get("id", "")), "encounter_kind": str(encounter.get("kind", "pirate")), "threat_level": threat_level})
		if not bool(state.active_voyage.get("treasure_claimed", false)):
			_add_actor("sea_treasure", "drifting_cargo", "漂流货箱", _sea_treasure_position() / WORLD_SCALE, Color("735a2f"), GOLD, "")
	elif current_region == "city":
		var active_port = _active_city_port_id()
		var city_layout = GameData.PORT_CITY_MAPS.get(active_port, GameData.PORT_CITY_MAPS.venice_dock)
		var npc_positions = Dictionary(city_layout.get("npc_positions", {}))
		var npc_locations = Dictionary(city_layout.get("npc_locations", {}))
		var port_npc_colors = [Color("49697a"), Color("7b5944"), Color("506f61"), Color("6f526e"), Color("6a6945")]
		for npc_index in range(Array(city_layout.get("npc_ids", [])).size()):
			var city_npc_id = str(Array(city_layout.npc_ids)[npc_index])
			if not GameData.NPCS.has(city_npc_id) or not npc_positions.has(city_npc_id):
				continue
			var npc_location = str(npc_locations.get(city_npc_id, active_port))
			_add_actor("npc", city_npc_id, str(GameData.NPCS[city_npc_id].name), Vector2(npc_positions[city_npc_id]), port_npc_colors[npc_index % port_npc_colors.size()], GOLD, npc_location)
		if active_port == "venice_dock":
			_spawn_enemy_if_ready("drunk_sailor")
			_add_actor("travel", "field", "前往城外", Vector2(455, 285), Color("547b61"), GOLD, "residential_quarter")
		elif active_port == "malta_dock" and state.quest_index >= 32:
			_add_actor("travel", "white_whale", "白鲸号残骸", Vector2(600, 950), Color("315d66"), TEAL, "white_whale_1")
		if (active_port == "venice_dock" or active_port not in GameData.TRADE_PORTS) and state.quest_index >= 12:
			_add_actor("travel", "black_sail", "黑帆据点", Vector2(550, 950), Color("493b45"), RED, "black_sail_1")
		var active_expedition = _current_story_expedition()
		if not active_expedition.is_empty() and str(active_expedition.port) == active_port and state.quest_index >= int(active_expedition.quest_start) + 3:
			_add_actor("travel", "legacy", str(active_expedition.name), Vector2(550, 950), Color("40556f"), GOLD, str(active_expedition.location))
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
	elif current_region == "black_sail":
		_spawn_next_dungeon_enemy(["corsair_deckhand", "corsair_raider", "corsair_guard", "corsair_captain"])
		_add_actor("travel", "city", "返回港口", Vector2(215, 1080), Color("4e7781"), GOLD, "venice_dock")
	elif current_region == "white_whale":
		_spawn_next_dungeon_enemy(["wreck_crab", "drowned_sailor", "fog_siren", "abyss_siren"])
		_add_actor("travel", "city", "返回马耳他", Vector2(215, 1080), Color("4e7781"), GOLD, "malta_dock")
	else:
		var expedition = _expedition_for_location(str(state.player.location))
		if not expedition.is_empty():
			_spawn_enemy_if_ready(str(expedition.enemy))
			_add_actor("travel", "city", "返回%s" % GameData.TRADE_PORTS[str(expedition.port)].name, Vector2(215, 1080), Color("4e7781"), GOLD, str(expedition.port))
	for discovery_id in DISCOVERY_SPAWNS:
		_spawn_discovery_if_available(discovery_id)

func _spawn_next_dungeon_enemy(enemy_ids):
	for enemy_id in enemy_ids:
		if not bool(state.dungeon_cleared.get(enemy_id, false)):
			_spawn_enemy_if_ready(enemy_id)
			return

func _current_story_expedition():
	for expedition_id in GameData.EXPEDITIONS:
		var expedition = GameData.EXPEDITIONS[expedition_id]
		if state.quest_index >= int(expedition.quest_start) and state.quest_index <= int(expedition.quest_start) + 5:
			var result = expedition.duplicate(true)
			result.id = str(expedition_id)
			return result
	return {}

func _expedition_for_location(location_id):
	for expedition_id in GameData.EXPEDITIONS:
		var expedition = GameData.EXPEDITIONS[expedition_id]
		if str(expedition.location) == str(location_id):
			var result = expedition.duplicate(true)
			result.id = str(expedition_id)
			return result
	return {}

func _spawn_discovery_if_available(discovery_id):
	if bool(state.discoveries.get(discovery_id, false)) or not DISCOVERY_SPAWNS.has(discovery_id):
		return
	var spawn = DISCOVERY_SPAWNS[discovery_id]
	if str(spawn.region) != current_region:
		return
	if current_region in ["dungeon", "black_sail", "white_whale", "legacy"] and _dungeon_floor_lock(str(spawn.location)) != "":
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
		_show_enemy_respawn_marker(enemy_id, remaining)
		_schedule_enemy_respawn(enemy_id, remaining)
		return
	state.enemy_respawns.erase(key)
	enemy_respawn_scheduled.erase(key)
	_remove_enemy_respawn_marker(key)
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

func _show_enemy_respawn_marker(enemy_id, remaining):
	if not ENEMY_SPAWNS.has(enemy_id) or current_region in ["sea", "dungeon", "black_sail", "white_whale", "legacy"]:
		return
	var key = _enemy_spawn_key(enemy_id)
	var marker = enemy_respawn_markers.get(key)
	if not is_instance_valid(marker):
		var data = ENEMY_SPAWNS[enemy_id]
		marker = Label.new()
		marker.name = "RespawnMarker_%s" % enemy_id
		marker.position = _world_point(data.position) + Vector2(-105, -112)
		marker.size = Vector2(210, 66)
		marker.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		marker.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		marker.mouse_filter = Control.MOUSE_FILTER_IGNORE
		marker.z_index = 32
		marker.add_theme_font_size_override("font_size", 14)
		marker.add_theme_color_override("font_color", Color("d9f7f1"))
		marker.add_theme_stylebox_override("normal", _style(Color(0.02, 0.09, 0.11, 0.92), 12, Color(TEAL, 0.78), 2, 7))
		world_layer.add_child(marker)
		enemy_respawn_markers[key] = marker
	_update_enemy_respawn_marker(enemy_id, float(remaining))

func _update_enemy_respawn_marker(enemy_id, remaining):
	var key = _enemy_spawn_key(enemy_id)
	var marker = enemy_respawn_markers.get(key)
	if not is_instance_valid(marker) or not ENEMY_SPAWNS.has(enemy_id):
		return
	var seconds = max(0, int(ceil(float(remaining))))
	var minutes = int(seconds / 60)
	marker.text = "%s刷新中\n◇ %02d:%02d" % [str(ENEMY_SPAWNS[enemy_id].name), minutes, seconds % 60]

func _refresh_enemy_respawn_markers():
	var now = _world_time_seconds()
	for key in Array(enemy_respawn_markers.keys()):
		var marker = enemy_respawn_markers.get(key)
		if not is_instance_valid(marker):
			enemy_respawn_markers.erase(key)
			continue
		var deadline = max(float(state.enemy_respawns.get(key, 0.0)), float(enemy_respawn_scheduled.get(key, 0.0)))
		_update_enemy_respawn_marker(str(key), max(0.0, deadline - now))

func _remove_enemy_respawn_marker(key):
	var marker = enemy_respawn_markers.get(str(key))
	if is_instance_valid(marker):
		marker.queue_free()
	enemy_respawn_markers.erase(str(key))

func _defer_enemy_respawn(enemy_id):
	var key = _enemy_spawn_key(enemy_id)
	var retry_deadline = _world_time_seconds() + MONSTER_RESPAWN_RETRY_SECONDS
	enemy_respawn_scheduled[key] = retry_deadline
	_show_enemy_respawn_marker(enemy_id, MONSTER_RESPAWN_RETRY_SECONDS)
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
		_show_enemy_respawn_marker(enemy_id, remaining)
		_schedule_enemy_respawn(enemy_id, remaining)
		return
	var data = ENEMY_SPAWNS.get(enemy_id, {})
	if data.is_empty():
		return
	if str(data.region) in ["dungeon", "black_sail", "white_whale", "legacy"] and bool(state.dungeon_cleared.get(enemy_id, false)):
		state.enemy_respawns.erase(key)
		_remove_enemy_respawn_marker(key)
		return
	if str(data.region) != current_region:
		state.enemy_respawns.erase(key)
		_remove_enemy_respawn_marker(key)
		return
	if _has_actor_id(enemy_id):
		state.enemy_respawns.erase(key)
		_remove_enemy_respawn_marker(key)
		return
	if _respawn_is_blocked(data):
		_defer_enemy_respawn(enemy_id)
		if not is_instance_valid(overlay):
			hint_label.text = "%s将在你离开刷新点后重新出现。" % data.name
		return
	state.enemy_respawns.erase(key)
	_remove_enemy_respawn_marker(key)
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
	if current_region == "sea":
		var remaining = state.sea_encounters_remaining()
		hint_label.text = "%s已被击退，航程还剩%d处海上威胁。" % [defeated.name, remaining] if remaining > 0 else "%s已被击退，本段航路已经安全。" % defeated.name
		_refresh_waypoint()
		return
	if current_region in ["dungeon", "black_sail", "white_whale", "legacy"]:
		state.enemy_respawns.erase(_enemy_spawn_key(enemy_id))
		call_deferred("_spawn_world_actors")
		call_deferred("_refresh_waypoint")
		hint_label.text = "%s已被击败，下一层道路已开放。" % defeated.name
		return
	var key = _enemy_spawn_key(enemy_id)
	if state.enemy_respawn_remaining(enemy_id) <= 0.0:
		state.enemy_respawns[key] = _world_time_seconds() + MONSTER_RESPAWN_SECONDS
		state.save_game()
	var respawn_remaining = state.enemy_respawn_remaining(enemy_id)
	_show_enemy_respawn_marker(enemy_id, respawn_remaining)
	_schedule_enemy_respawn(enemy_id, respawn_remaining)
	hint_label.text = "%s已被击败并消失，%d秒后在原地刷新。" % [defeated.name, int(MONSTER_RESPAWN_SECONDS)]

func _add_actor(kind, id, display_name, position, color, accent, location_id = "", metadata = {}):
	var actor = ActorScript.new()
	actor.position = _world_point(position)
	actor.z_index = 10
	actor.scale = Vector2.ONE * 1.12
	actor.configure(kind, color, accent, id)
	world_layer.add_child(actor)
	var nameplate = Label.new()
	nameplate.text = "%s\n◆ %s" % [display_name, GameData.npc_service_label(id)] if kind == "npc" and GameData.NPCS.has(str(id)) else display_name
	nameplate.position = Vector2(-90, 48)
	nameplate.size = Vector2(180, 45 if kind == "npc" else 31)
	nameplate.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nameplate.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	nameplate.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	nameplate.add_theme_font_size_override("font_size", 12 if kind == "npc" else 15)
	nameplate.add_theme_color_override("font_color", Color("fff4d1"))
	nameplate.add_theme_stylebox_override("normal", _style(Color(0.025, 0.055, 0.065, 0.88), 9, Color(GOLD, 0.48), 1, 5))
	actor.add_child(nameplate)
	var entry = {"kind": kind, "id": id, "name": display_name, "node": actor, "location": location_id}
	entry.merge(Dictionary(metadata), true)
	actors.append(entry)

func _spawn_for_location(location_id):
	if current_region == "sea" and not state.active_voyage.is_empty():
		var saved_position = state.voyage_position()
		return saved_position if saved_position != Vector2.ZERO else _sea_origin_position()
	var overrides = {
		"alisa_hut": Vector2(250, 365), "venice_tavern": Vector2(250, 690),
		"venice_square": Vector2(360, 790), "venice_market": Vector2(450, 700),
		"venice_dock": Vector2(360, 915), "venice_north_gate": Vector2(360, 365),
		"ragusa_dock": Vector2(360, 915), "alexandria_dock": Vector2(360, 915), "malta_dock": Vector2(360, 915),
		"cape_town_dock": Vector2(360, 915), "quanzhou_dock": Vector2(360, 915), "athens_dock": Vector2(360, 915), "yangzhou_dock": Vector2(360, 915), "amsterdam_dock": Vector2(360, 915),
		"residential_quarter": Vector2(350, 1045), "venice_mine": Vector2(500, 505),
		"venice_back_hill": Vector2(230, 450), "venice_wildwood": Vector2(500, 820),
		"training_dungeon_1": Vector2(360, 1025), "training_dungeon_2": Vector2(360, 775),
		"training_dungeon_3": Vector2(360, 520), "training_dungeon_4": Vector2(360, 285)
		,"black_sail_1": Vector2(360, 1025), "black_sail_2": Vector2(360, 775),
		"black_sail_3": Vector2(360, 520), "black_sail_4": Vector2(360, 285),
		"white_whale_1": Vector2(360, 1025), "white_whale_2": Vector2(360, 775),
		"white_whale_3": Vector2(360, 520), "white_whale_4": Vector2(360, 285),
		"legacy_basin": Vector2(360, 980), "legacy_changan": Vector2(360, 980), "legacy_earth": Vector2(360, 980), "legacy_tira": Vector2(360, 980),
		"legacy_demon_legend": Vector2(360, 980), "legacy_jade": Vector2(360, 980), "legacy_fire": Vector2(360, 980), "legacy_return": Vector2(360, 980),
		"legacy_shears": Vector2(360, 980), "legacy_seal": Vector2(360, 980)
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
	currency_label = _label("", 14, GOLD)
	currency_label.custom_minimum_size = Vector2(104, 42)
	currency_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	currency_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	currency_label.add_theme_stylebox_override("normal", _style(Color(0.18, 0.13, 0.03, 0.92), 11, Color(GOLD, 0.62), 1, 8))
	row.add_child(currency_label)
	settings_button = _button("设置", "ghost")
	settings_button.custom_minimum_size = Vector2(66, 42)
	settings_button.add_theme_font_size_override("font_size", 13)
	settings_button.pressed.connect(_open_settings)
	row.add_child(settings_button)
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
		{"text": "角色", "call": _open_character},
		{"text": "背包", "call": _open_inventory},
		{"text": "任务", "call": _open_quest},
		{"text": "地图", "call": _open_world_map},
		{"text": "日志", "call": _open_full_journal}
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
	hint_label.text = "背景音乐与音效已开启。" if is_enabled else "背景音乐与音效已关闭。"
	call_deferred("_open_settings")

func _open_settings():
	var content = VBoxContainer.new()
	content.add_theme_constant_override("separation", 14)
	content.add_child(_label("游戏难度", 22, GOLD))
	var current = _label("当前：%s难度" % state.difficulty_name(), 15, TEAL)
	current.add_theme_stylebox_override("normal", _style(Color(0.04, 0.18, 0.18, 0.88), 12, Color(TEAL, 0.55), 1, 10))
	content.add_child(current)
	var mode_row = HBoxContainer.new()
	mode_row.add_theme_constant_override("separation", 10)
	content.add_child(mode_row)
	for mode in [
		{"id": GameState.DIFFICULTY_NORMAL, "name": "普通", "note": "当前标准数值，适合剧情与轻松成长。"},
		{"id": GameState.DIFFICULTY_ADVENTURE, "name": "冒险", "note": "敌人耐久+25%、攻击+12%、航行风险+6；战斗经验与银币+20%、掉落率+10%。"}
	]:
		var card = VBoxContainer.new()
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		card.add_theme_constant_override("separation", 7)
		var selected = str(state.difficulty) == str(mode.id)
		var choose = _button(("◆ " if selected else "") + str(mode.name), "gold" if selected else "ghost")
		choose.disabled = selected
		choose.pressed.connect(_set_difficulty_from_settings.bind(str(mode.id)))
		card.add_child(choose)
		var note = _label(str(mode.note), 12, INK if selected else MUTED)
		note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		note.custom_minimum_size.y = 72
		card.add_child(note)
		mode_row.add_child(card)
	content.add_child(HSeparator.new())
	content.add_child(_label("声音", 18, TEAL))
	var audio = _button("背景音乐与音效：开" if AudioDirector.is_audio_enabled() else "背景音乐与音效：关", "ghost")
	audio.pressed.connect(_toggle_audio)
	content.add_child(audio)
	content.add_child(HSeparator.new())
	content.add_child(_label("存档管理", 18, RED))
	var reset_note = _label("重置会清除等级、任务、装备、货物、船队与航行进度；难度和声音设置会保留。", 13, MUTED)
	reset_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(reset_note)
	var reset = _button("重置游戏进度", "ghost")
	reset.add_theme_color_override("font_color", RED)
	reset.pressed.connect(_open_reset_confirmation)
	content.add_child(reset)
	_open_overlay(content, true, Vector2(666, 760))

func _set_difficulty_from_settings(mode):
	var result = state.set_difficulty(str(mode))
	hint_label.text = str(result.get("message", "难度切换失败。"))
	call_deferred("_open_settings")

func _open_reset_confirmation():
	var content = VBoxContainer.new()
	content.add_theme_constant_override("separation", 15)
	content.add_child(_label("确定重置全部游戏进度？", 22, RED))
	var warning = _label("此操作无法撤销。当前角色、十三卷任务、背包装备、贸易货物、船只和地图进度都会从头开始。", 15, INK)
	warning.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(warning)
	var buttons = HBoxContainer.new()
	buttons.add_theme_constant_override("separation", 10)
	content.add_child(buttons)
	var cancel = _button("取消，返回设置", "ghost")
	cancel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cancel.pressed.connect(_open_settings)
	buttons.add_child(cancel)
	var confirm = _button("确认重置", "primary")
	confirm.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	confirm.add_theme_color_override("font_color", Color("ffd6d8"))
	confirm.pressed.connect(_confirm_reset_game)
	buttons.add_child(confirm)
	_open_overlay(content, true, Vector2(666, 470))

func _confirm_reset_game():
	state.reset_progress()
	get_tree().reload_current_scene()

func _process(delta):
	_refresh_enemy_respawn_markers()
	if is_instance_valid(overlay):
		return
	var keyboard = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var direction = joystick_direction if joystick_direction.length() > 0.08 else keyboard
	if direction.length() < 0.1 and has_move_target:
		var difference = move_target - player_actor.position
		if difference.length() < NAVIGATION_REACH_DISTANCE:
			if task_navigation_active and _advance_task_navigation_waypoint():
				difference = move_target - player_actor.position
				direction = difference.normalized()
			else:
				has_move_target = false
				if task_navigation_active:
					_finish_task_navigation_leg()
		else:
			direction = difference.normalized()
	elif direction.length() > 0.1:
		has_move_target = false
		_cancel_task_navigation()
	var previous_position = player_actor.position
	if direction.length() > 0.05:
		var movement_speed = float(state.ship_speed_profile().world_speed) if current_region == "sea" else 245.0
		var movement = direction.normalized() * movement_speed * delta
		var next_position = player_actor.position + movement
		var active_size = _active_world_size()
		next_position.x = clamp(next_position.x, 28.0 * WORLD_SCALE, active_size.x - 28.0 * WORLD_SCALE)
		next_position.y = clamp(next_position.y, 210.0 * WORLD_SCALE, active_size.y - 200.0)
		if _is_walkable(next_position):
			player_actor.position = next_position
		else:
			# Slide along obstacle edges instead of feeling stuck on a corner.
			var horizontal = Vector2(clamp(player_actor.position.x + movement.x, 28.0 * WORLD_SCALE, active_size.x - 28.0 * WORLD_SCALE), player_actor.position.y)
			var vertical = Vector2(player_actor.position.x, clamp(player_actor.position.y + movement.y, 210.0 * WORLD_SCALE, active_size.y - 200.0))
			if abs(movement.x) >= abs(movement.y) and _is_walkable(horizontal):
				player_actor.position = horizontal
			elif _is_walkable(vertical):
				player_actor.position = vertical
			elif _is_walkable(horizontal):
				player_actor.position = horizontal
	if current_region != "sea" and player_actor.position.distance_to(previous_position) > 0.5:
		footstep_timer -= delta
		if footstep_timer <= 0.0:
			AudioDirector.play_sfx("step")
			footstep_timer = 0.34
	else:
		footstep_timer = min(footstep_timer, 0.08)
	player_actor.set_motion(direction if direction.length() > 0.05 else Vector2.ZERO)
	_update_camera(delta)
	_update_nearest_actor()
	if current_region == "sea":
		_update_sea_voyage(delta)
	else:
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
	_cancel_task_navigation()

func _update_camera(delta, snap = false):
	if not is_instance_valid(world_layer) or not is_instance_valid(player_actor):
		return
	var desired = CAMERA_FOCUS - player_actor.position
	var active_size = _active_world_size()
	desired.x = clamp(desired.x, MAP_SIZE.x - active_size.x, 0.0)
	desired.y = clamp(desired.y, MAP_SIZE.y - active_size.y, 0.0)
	if snap or delta <= 0.0:
		world_layer.position = desired
	else:
		world_layer.position = world_layer.position.lerp(desired, min(1.0, delta * CAMERA_SMOOTH_SPEED))

func _on_joystick_direction(value):
	joystick_direction = value
	if value.length() > 0.08:
		has_move_target = false
		_cancel_task_navigation()

func _is_walkable(position):
	if current_region == "sea" and is_instance_valid(map_node) and map_node.has_method("is_navigable"):
		return bool(map_node.is_navigable(position))
	# 城市只允许在视觉上明确的主广场内行走；远景建筑、水面与城墙不再
	# 叠加房屋碰撞框，也不会出现与美术错位的方形障碍。
	if current_region == "city":
		var city_layout = GameData.PORT_CITY_MAPS.get(_active_city_port_id(), GameData.PORT_CITY_MAPS.venice_dock)
		var plaza_bounds = _world_rect(Rect2(city_layout.get("plaza_rect", Rect2(45, 220, 630, 790)))).grow(14.0 * WORLD_SCALE)
		return plaza_bounds.has_point(position)
	var active_obstacles = [] if current_region == "city" else region_obstacles.get(current_region, [])
	for rect in active_obstacles:
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
		action_button.text = "靠近港口、海盗或宝藏后互动" if current_region == "sea" else "靠近人物或敌人后互动"
		action_button.disabled = true
	else:
		nearest_actor.node.selected = true
		action_button.disabled = false
		if nearest_actor.kind == "sea_port":
			action_button.text = ("返航 · " if str(nearest_actor.id) == str(state.active_voyage.origin) else "靠港 · ") + str(GameData.TRADE_PORTS[str(nearest_actor.id)].name)
		elif nearest_actor.kind == "sea_return":
			action_button.text = "放弃航程 · 返回%s" % GameData.TRADE_PORTS[str(nearest_actor.id)].name
		elif nearest_actor.kind == "sea_treasure":
			action_button.text = "打捞 · 漂流货箱"
		elif nearest_actor.kind == "travel":
			action_button.text = "进入 · %s" % nearest_actor.name
		elif nearest_actor.kind == "discovery":
			action_button.text = "调查 · %s" % nearest_actor.name
		elif nearest_actor.kind == "npc" and state.is_trade_unlocked() and not _is_current_talk_target(str(nearest_actor.id)) and _npc_service(str(nearest_actor.id)) in ["market", "harbor", "shipyard", "cook", "trade_order"]:
			var service_title = {"market": "货物买卖", "harbor": "航线出港", "shipyard": "买船改造", "cook": "烹制补给", "trade_order": "商会交付"}.get(_npc_service(str(nearest_actor.id)), "港口服务")
			action_button.text = "%s · %s" % [service_title, str(nearest_actor.name)]
		elif nearest_actor.kind == "npc" and _npc_service(str(nearest_actor.id)) == "rest" and not _is_current_talk_target(str(nearest_actor.id)):
			action_button.text = "恢复补给 · %s" % str(nearest_actor.name)
		elif nearest_actor.kind == "npc" and _npc_service(str(nearest_actor.id)) == "jewelry_shop" and not _is_current_talk_target(str(nearest_actor.id)):
			action_button.text = "选购珠宝 · %s" % str(nearest_actor.name)
		elif nearest_actor.kind == "npc" and _npc_service(str(nearest_actor.id)) == "tavern_shop" and not _is_current_talk_target(str(nearest_actor.id)):
			action_button.text = "购买食物 · %s" % str(nearest_actor.name)
		else:
			action_button.text = ("交谈 · " if nearest_actor.kind == "npc" else "挑战 · ") + nearest_actor.name

func _update_sea_voyage(delta):
	if state.active_voyage.is_empty():
		return
	sea_save_timer += delta
	state.update_voyage_position(player_actor.position, sea_save_timer >= 1.5)
	if sea_save_timer >= 1.5:
		sea_save_timer = 0.0
	if player_actor.position.distance_to(_sea_destination_position()) <= 82.0:
		has_move_target = false
		player_actor.set_motion(Vector2.ZERO)
		_complete_sea_voyage()
		return
	if not bool(state.active_voyage.get("storm_resolved", false)) and player_actor.position.distance_to(_sea_storm_position()) <= _sea_storm_radius():
		has_move_target = false
		player_actor.set_motion(Vector2.ZERO)
		var storm_result = state.resolve_sea_storm()
		_refresh_hud()
		_show_message("遭遇风暴", str(storm_result.get("message", "海燕号穿过了风暴。")))
		return
	_update_sea_enemy_pursuit(delta)
	for entry in actors:
		if str(entry.kind) == "enemy" and player_actor.position.distance_to(entry.node.position) <= SEA_ENCOUNTER_DISTANCE:
			has_move_target = false
			player_actor.set_motion(Vector2.ZERO)
			active_enemy_actor = entry
			var battle = state.start_sea_encounter(str(entry.get("encounter_id", "")))
			if bool(battle.get("ok", false)):
				_open_battle(battle)
			else:
				active_enemy_actor = {}
				_show_message("无法交战", str(battle.get("message", "海盗已经离开。")))
			return

func _update_sea_enemy_pursuit(delta):
	if current_region != "sea" or state.active_voyage.is_empty() or not is_instance_valid(map_node):
		return
	var player_in_harbor = map_node.has_method("is_in_harbor_safe_zone") and bool(map_node.is_in_harbor_safe_zone(player_actor.position, SEA_HARBOR_GUARD_RADIUS))
	for entry in actors:
		if str(entry.kind) != "enemy" or not is_instance_valid(entry.node):
			continue
		var offset = player_actor.position - entry.node.position
		var distance = offset.length()
		var aggro_radius = SEA_PIRATE_AGGRO_RADIUS if str(entry.get("encounter_kind", "monster")) == "pirate" else SEA_MONSTER_AGGRO_RADIUS
		if player_in_harbor or distance <= SEA_ENCOUNTER_DISTANCE or distance > aggro_radius:
			entry.node.set_motion(Vector2.ZERO)
			continue
		var enemy_level = int(entry.get("threat_level", GameData.ENEMIES[str(entry.id)].level))
		var chase_speed = clamp(42.0 + float(enemy_level) * 0.55, 45.0, 72.0)
		var chase_direction = offset.normalized()
		var movement = chase_direction * chase_speed * float(delta)
		var candidates = [entry.node.position + movement, entry.node.position + movement.rotated(0.58), entry.node.position + movement.rotated(-0.58)]
		for candidate in candidates:
			if not _is_walkable(Vector2(candidate)):
				continue
			if map_node.has_method("is_in_harbor_safe_zone") and bool(map_node.is_in_harbor_safe_zone(Vector2(candidate), SEA_HARBOR_GUARD_RADIUS)):
				continue
			entry.node.position = Vector2(candidate)
			entry.node.set_motion(chase_direction)
			var encounter_id = str(entry.get("encounter_id", ""))
			state.update_sea_encounter_position(encounter_id, entry.node.position)
			if map_node.has_method("update_encounter_position"):
				map_node.update_encounter_position(encounter_id, entry.node.position)
			break

func _complete_sea_voyage(port_id = ""):
	if current_region != "sea" or state.active_voyage.is_empty():
		return
	var arrival_port = str(port_id) if str(port_id) != "" else str(state.active_voyage.destination)
	if arrival_port == str(state.active_voyage.origin):
		_show_sea_return_prompt()
		return
	var result = state.complete_voyage(arrival_port)
	if not bool(result.get("ok", false)):
		_show_message("无法靠港", str(result.get("message", "航程状态异常。")))
		return
	AudioDirector.play_sfx("sail")
	_leave_sea_to_port(str(result.destination))
	if bool(result.get("quest_completed", false)):
		hint_label.text = str(result.message)
		call_deferred("_show_quest_claim")
	else:
		_show_message("航行抵达", str(result.message))

func _show_sea_return_prompt():
	if state.active_voyage.is_empty():
		return
	var origin = str(state.active_voyage.origin)
	var content = VBoxContainer.new()
	content.add_theme_constant_override("separation", 16)
	content.add_child(_label("放弃本次航程？", 26, GOLD))
	var copy = _label("返航至%s不会推进贸易日期，已经打捞的奖励会保留。" % GameData.TRADE_PORTS[origin].name, 16, INK)
	copy.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(copy)
	var confirm = _button("确认返航", "gold")
	confirm.pressed.connect(_abort_sea_voyage)
	content.add_child(confirm)
	var cancel = _button("继续航行", "primary")
	cancel.pressed.connect(_close_overlay)
	content.add_child(cancel)
	_open_overlay(content)

func _show_sea_treasure_prompt():
	if state.active_voyage.is_empty() or bool(state.active_voyage.get("treasure_claimed", false)):
		_show_message("海上打捞", "这片水域已经没有可打捞的货箱。")
		return
	var content = VBoxContainer.new()
	content.add_theme_constant_override("separation", 14)
	content.add_child(_label("漂流货箱 · 选择打捞方式", 25, GOLD))
	var chance = int(state.active_voyage.get("dive_chance", 35))
	var copy = _label("稳妥打捞可直接获得银币；潜水寻宝有%d%%概率找到本海域的珠宝、卡片或未知装备，失败只带回少量银币。每段航程只能选择一次。" % chance, 16, INK)
	copy.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(copy)
	var salvage = _button("稳妥打捞 · 保证获得银币", "gold")
	salvage.pressed.connect(_claim_sea_treasure_2d.bind("salvage"))
	content.add_child(salvage)
	var dive = _button("潜水寻宝 · %d%%发现遗物" % chance, "primary")
	dive.pressed.connect(_claim_sea_treasure_2d.bind("dive"))
	content.add_child(dive)
	var leave = _button("暂时离开", "ghost")
	leave.pressed.connect(_close_overlay)
	content.add_child(leave)
	_open_overlay(content)

func _claim_sea_treasure_2d(mode):
	var result = state.claim_sea_treasure(str(mode))
	_close_overlay()
	_spawn_world_actors()
	_refresh_hud()
	if bool(result.get("ok", false)):
		AudioDirector.play_sfx("reward")
	_show_message("潜水寻宝" if str(mode) == "dive" else "海上打捞", str(result.get("message", "货箱已经空了。")))

func _abort_sea_voyage():
	var result = state.abort_voyage()
	_close_overlay()
	if bool(result.get("ok", false)):
		_leave_sea_to_port(str(result.origin))
		_show_message("已经返航", str(result.message))

func _replace_world_map(region_id):
	if is_instance_valid(map_node):
		world_layer.remove_child(map_node)
		map_node.queue_free()
	map_node = SeaWorldMapScript.new() if str(region_id) == "sea" else WorldMapScript.new()
	if str(region_id) == "sea":
		map_node.configure(state.active_voyage)
	else:
		map_node.set_region(str(region_id))
		if str(region_id) == "city":
			map_node.set_city_port(_active_city_port_id())
	world_layer.add_child(map_node)
	world_layer.move_child(map_node, 0)

func _enter_active_voyage():
	if state.active_voyage.is_empty():
		return
	current_region = "sea"
	current_zone = ""
	_replace_world_map("sea")
	player_actor.configure("player", Color("278e93"), GOLD, "player_ship")
	player_actor.set_ship_hull(str(state.ship.get("hull_id", "sea_swallow")))
	player_actor.scale = Vector2.ONE * 1.28
	_spawn_world_actors()
	player_actor.position = state.voyage_position()
	_update_camera(0.0, true)
	has_move_target = false
	joystick_direction = Vector2.ZERO
	sea_save_timer = 0.0
	if is_instance_valid(joystick):
		joystick._set_direction(Vector2.ZERO)
	AudioDirector.set_region("sea")
	_refresh_hud()
	_refresh_waypoint()
	hint_label.text = "港湾内受守卫保护 · 离港后海盗与海怪会从警戒圈主动追击"

func _leave_sea_to_port(port_id):
	current_region = "city"
	current_zone = ""
	_replace_world_map("city")
	player_actor.rotation = 0.0
	player_actor.configure("player", Color("278e93"), GOLD, "player")
	player_actor.scale = Vector2.ONE * 1.12
	_spawn_world_actors()
	player_actor.position = _spawn_for_location(str(port_id))
	_update_camera(0.0, true)
	has_move_target = false
	joystick_direction = Vector2.ZERO
	if is_instance_valid(joystick):
		joystick._set_direction(Vector2.ZERO)
	AudioDirector.set_region("city")
	_refresh_hud()
	_refresh_waypoint()

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
	if current_region in ["dungeon", "black_sail", "white_whale", "legacy"]:
		var floor_lock = _dungeon_floor_lock(best_id)
		if floor_lock != "":
			hint_label.text = floor_lock
			return
	var state_location = str(state.player.location)
	# 港口城现在是统一开放广场。只要玩家仍处在港口状态，走过旧版街区
	# 热区就不能把真实地点改写成威尼斯酒馆/市场等遗留地点。
	if current_region == "city" and state_location in GameData.TRADE_PORTS:
		current_zone = "venice_dock"
		_refresh_hud()
		return
	var same_effective_location = best_id == state_location or (best_id == "venice_dock" and state_location in GameData.TRADE_PORTS)
	# 进入城市街区时保留真实远洋港口，避免导航途中改写存档。
	if best_id == "venice_dock" and state_location in GameData.TRADE_PORTS:
		current_zone = best_id
		_refresh_hud()
		return
	if best_id == current_zone and same_effective_location and not force:
		return
	var result = state.arrive_from_2d(best_id)
	if result.ok:
		current_zone = best_id
	_refresh_hud()
	if bool(result.get("quest_completed", false)):
		_cancel_task_navigation()
		has_move_target = false
		call_deferred("_show_quest_claim")

func _dungeon_floor_lock(location_id):
	var requirements = {
		"training_dungeon_2": "dungeon_guard",
		"training_dungeon_3": "stone_puppet",
		"training_dungeon_4": "tide_beast",
		"black_sail_2": "corsair_deckhand",
		"black_sail_3": "corsair_raider",
		"black_sail_4": "corsair_guard",
		"white_whale_2": "wreck_crab",
		"white_whale_3": "drowned_sailor",
		"white_whale_4": "fog_siren"
	}
	var required_enemy = str(requirements.get(location_id, ""))
	if required_enemy == "" or bool(state.dungeon_cleared.get(required_enemy, false)):
		return ""
	return "道路被封锁：先击败%s" % GameData.ENEMIES[required_enemy].name

func _refresh_hud():
	if current_region == "sea" and not state.active_voyage.is_empty():
		var voyage = state.active_voyage
		location_label.text = "◆ %s" % GameData.SEA_REGIONS[str(voyage.region)].name
		var speed_profile = state.ship_speed_profile()
		stats_label.text = "%s · %.1f节｜航程%d%% · 剩余%d海里" % [str(state.ship.name), float(speed_profile.knots), int(round(state.voyage_progress() * 100.0)), state.voyage_remaining_distance()]
		currency_label.text = "银币 %d" % int(state.player.silver)
		var salvage_status = "已打捞" if bool(voyage.get("treasure_claimed", false)) else "可潜水"
		quest_label.text = "%s → %s｜%s · %d日｜威胁%d/%d｜%s｜货舱%d/%d" % [GameData.TRADE_PORTS[str(voyage.origin)].name, GameData.TRADE_PORTS[str(voyage.destination)].name, str(voyage.get("tier_name", "航行")), int(voyage.days), state.sea_encounters_remaining(), Array(voyage.get("encounters", [])).size(), salvage_status, state.cargo_used(), state.cargo_capacity()]
		if is_instance_valid(waypoint_label):
			_refresh_waypoint()
		return
	var location_id = str(state.player.location)
	var location_name = GameData.LOCATIONS.get(location_id, GameData.LOCATIONS.venice_square).name
	location_label.text = "◆ %s" % location_name
	stats_label.text = "Lv.%d  体力%d" % [int(state.player.level), int(state.player.hp)]
	currency_label.text = "银币 %d" % int(state.player.silver)
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
	_cancel_task_navigation()
	AudioDirector.play_sfx("interact")
	if nearest_actor.kind == "sea_port":
		_complete_sea_voyage(str(nearest_actor.id))
		return
	if nearest_actor.kind == "sea_return":
		_show_sea_return_prompt()
		return
	if nearest_actor.kind == "sea_treasure":
		_show_sea_treasure_prompt()
		return
	if nearest_actor.kind == "travel":
		_switch_region(str(nearest_actor.id), str(nearest_actor.location))
		return
	var actor_location = str(nearest_actor.get("location", ""))
	if current_region in ["dungeon", "black_sail", "white_whale", "legacy"]:
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
		var npc_id = str(nearest_actor.id)
		var service = _npc_service(npc_id)
		if service == "market" and state.is_trade_unlocked() and not _is_current_talk_target(npc_id):
			_open_trade_2d(npc_id)
			return
		if service == "harbor" and state.is_trade_unlocked() and not _is_current_talk_target(npc_id):
			_open_port_harbor_2d(npc_id)
			return
		if service == "shipyard" and state.is_trade_unlocked() and not _is_current_talk_target(npc_id):
			_open_port_shipyard_2d(npc_id)
			return
		if service == "cook" and state.is_trade_unlocked() and not _is_current_talk_target(npc_id):
			_open_port_kitchen_2d(npc_id)
			return
		if service == "trade_order" and state.is_trade_unlocked() and not _is_current_talk_target(npc_id):
			_open_port_orders_2d(npc_id)
			return
		if service == "rest" and not _is_current_talk_target(npc_id):
			_open_vendor_shop_2d(npc_id)
			return
		if service in ["jewelry_shop", "tavern_shop"] and not _is_current_talk_target(npc_id):
			_open_vendor_shop_2d(npc_id)
			return
		var result = state.talk_to(npc_id)
		_refresh_hud()
		_show_dialog(npc_id, result)
	else:
		active_enemy_actor = nearest_actor
		var result = state.start_battle(nearest_actor.id)
		if result.ok:
			_open_battle(result)
		else:
			active_enemy_actor = {}
			_show_message("无法战斗", result.message)

func _is_current_talk_target(npc_id):
	var quest = state.get_current_quest()
	return not quest.is_empty() and str(quest.objective.type) == "talk" and str(quest.objective.target) == str(npc_id)

func _npc_service(npc_id):
	return str(GameData.NPCS.get(str(npc_id), {}).get("service", ""))

func _switch_region(region_id, entrance_location):
	if region_id == "dungeon" and int(state.player.level) < 3:
		_show_message("经验副本尚未开放", "需要达到 Lv.3 才能进入四层经验副本。先完成城外任务提升等级。")
		return
	if region_id == "black_sail" and int(state.player.level) < 6:
		_show_message("黑帆据点尚未开放", "需要达到 Lv.6 并完成威尼斯试炼后才能追踪黑帆航线。")
		return
	if region_id == "white_whale" and int(state.player.level) < 20:
		_show_message("残骸海域尚未开放", "需要达到 Lv.20，并在马耳他准备好远航补给。")
		return
	if region_id == "legacy":
		var expedition_lock = _expedition_for_location(str(entrance_location))
		if not expedition_lock.is_empty() and int(state.player.level) < int(expedition_lock.min_level):
			_show_message("远征战力不足", "%s建议达到 Lv.%d 后进入。" % [str(expedition_lock.name), int(expedition_lock.min_level)])
			return
	var previous_region = current_region
	var dungeon_regions = ["dungeon", "black_sail", "white_whale", "legacy"]
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
	elif current_region == "white_whale" and _dungeon_floor_lock(target_location) != "":
		target_location = "white_whale_1"
	var arrival = state.arrive_from_2d(target_location)
	_replace_world_map(current_region)
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
		_cancel_task_navigation()
		has_move_target = false
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
	_spawn_world_actors()
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
		content.add_child(_label("第十三卷·封印迷阵完成！你已平定十三卷潮灾，成为守护四海航路的人。", 17, INK))
	else:
		content.add_child(_label("下一个任务｜%s" % next_quest.title, 20, GOLD))
		var story = _label(next_quest.story, 16, MUTED)
		story.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		content.add_child(story)
	var continue_button = _button("继续冒险", "primary")
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
	battle_round_label = _label("遭遇战 · %s · 第%d回合" % [str(view.get("difficulty_name", state.difficulty_name())), int(view.get("round", 1))], 24, GOLD)
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
	battle_log_label = _label("两船抢占上风位，舰炮已经装填。" if bool(view.get("sea_battle", false)) else "双方在港口石路上展开对峙。", 14, MUTED)
	battle_log_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	battle_log_label.custom_minimum_size.y = 70
	content.add_child(battle_log_label)
	var actions = HBoxContainer.new()
	actions.add_theme_constant_override("separation", 10)
	content.add_child(actions)
	battle_action_button = _button("舰炮射击" if bool(view.get("sea_battle", false)) else "挥剑攻击", "primary")
	battle_action_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	battle_action_button.pressed.connect(_battle_attack)
	actions.add_child(battle_action_button)
	battle_auto_button = _button("自动战斗", "gold")
	battle_auto_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	battle_auto_button.pressed.connect(_battle_auto)
	actions.add_child(battle_auto_button)
	battle_skill_button = _button("舷炮齐射 0/3" if bool(view.get("sea_battle", false)) else "破浪斩 0/3", "ghost")
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
			battle_round_label.text = "遭遇战 · %s · 第%d回合" % [str(view.get("difficulty_name", state.difficulty_name())), int(view.get("round", 1))]
	if bool(view.get("sea_battle", false)):
		battle_player_info_label.text = "%s · %s\n体力 %d/%d · 攻%d 防%d" % [str(view.get("combatant_name", state.ship.name)), str(view.get("ship_role", state.ship_role())), int(view.get("player_hp", state.player.hp)), int(view.get("player_max_hp", state.get_stats().max_hp)), int(view.get("player_attack", 0)), int(view.get("player_defense", 0))]
	else:
		battle_player_info_label.text = "航者 Lv.%d\n体力 %d / %d" % [int(view.get("player_level", state.player.level)), int(view.get("player_hp", state.player.hp)), int(view.get("player_max_hp", state.get_stats().max_hp))]
	var enemy_detail = "%s Lv.%d · %s\n体力 %d / %d" % [enemy_name, enemy_level, enemy_rank, int(view.get("enemy_hp", 0)), int(view.get("enemy_max_hp", enemy.get("hp", 1)))]
	if bool(view.get("sea_battle", false)):
		enemy_detail += "\n%s动态威胁 · 掉落%s" % [str(view.get("sea_zone_name", "未知海域")), str(view.get("loot_tier_name", "航海装备"))]
	battle_enemy_info_label.text = enemy_detail
	if is_instance_valid(battle_intent_label):
		battle_intent_label.text = "敌方意图｜%s" % str(view.get("enemy_intent", "战斗已经结束")) if not bool(view.get("battle_over", false)) else "战斗已经结束"
	if is_instance_valid(battle_skill_button):
		var focus = int(view.get("focus", state.battle_focus()))
		battle_skill_button.text = ("舷炮齐射 %d/3" if bool(view.get("sea_battle", false)) else "破浪斩 %d/3") % focus
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
			var return_port = str(result.get("return_port", ""))
			battle_action_button.text = "返回%s" % GameData.TRADE_PORTS[return_port].name if bool(result.get("lost_at_sea", false)) and GameData.TRADE_PORTS.has(return_port) else "返回威尼斯酒馆"
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
	var finished_result = battle_result.duplicate(true)
	_close_overlay()
	if lost:
		_return_to_tavern_after_defeat(enemy_name, finished_result)
	elif bool(finished_result.get("fled", false)) and current_region == "sea":
		_retreat_from_sea_encounter()
	elif should_claim:
		call_deferred("_show_quest_claim")
	elif should_claim_bounty:
		call_deferred("_show_bounty_claim")

func _retreat_from_sea_encounter():
	var enemy_position = player_actor.position - Vector2(0, 82)
	if not active_enemy_actor.is_empty() and is_instance_valid(active_enemy_actor.get("node")):
		enemy_position = active_enemy_actor.node.position
	var away = player_actor.position - enemy_position
	if away.length() < 0.1:
		away = Vector2.DOWN
	away = away.normalized()
	var retreat_position = player_actor.position
	for angle in [0.0, 0.72, -0.72, PI]:
		var candidate = player_actor.position + away.rotated(float(angle)) * 155.0
		var active_size = _active_world_size()
		candidate.x = clamp(candidate.x, 70.0, active_size.x - 70.0)
		candidate.y = clamp(candidate.y, 210.0, active_size.y - 110.0)
		if map_node.has_method("is_navigable") and map_node.is_navigable(candidate) and candidate.distance_to(enemy_position) >= 125.0:
			retreat_position = candidate
			break
	player_actor.position = retreat_position
	player_actor.set_motion(Vector2.ZERO)
	has_move_target = false
	joystick_direction = Vector2.ZERO
	active_enemy_actor = {}
	nearest_actor = {}
	if not state.active_voyage.is_empty():
		state.active_voyage.current_encounter_id = ""
	state.update_voyage_position(player_actor.position, true)
	hint_label.text = "已经撤到安全水域。海盗和海怪不会消失，可转动船头绕行。"

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

func _return_to_tavern_after_defeat(enemy_name, result = {}):
	if bool(result.get("lost_at_sea", false)):
		var return_port = str(result.get("return_port", "venice_dock"))
		_leave_sea_to_port(return_port)
		var port_name = str(GameData.TRADE_PORTS.get(return_port, GameData.TRADE_PORTS.venice_dock).name)
		_show_message("海战失败 · 已被送回港口", "你被%s击败。护航船把海燕号拖回%s，装备、银币和货物没有额外损失。\n\n当前体力：%d / %d，可以先整理装备和补给，或付费传送返回威尼斯休整。" % [enemy_name, port_name, int(state.player.hp), int(state.get_stats().max_hp)])
		return
	_switch_region("city", "venice_tavern")
	var stats = state.get_stats()
	_show_message("战斗失败 · 已返回酒馆", "你被%s击倒。威尼斯巡逻队将你送回老海鸥酒馆，装备和银币没有损失。\n\n当前体力：%d / %d，可以与酒馆老板交谈并休息至完全恢复。" % [enemy_name, int(state.player.hp), int(stats.max_hp)])

func _open_character():
	var content = VBoxContainer.new()
	content.add_theme_constant_override("separation", 10)
	content.add_child(_label("角色信息 · 已装备", 26, GOLD))
	var stats = state.get_stats()
	var identity_panel = PanelContainer.new()
	identity_panel.add_theme_stylebox_override("panel", _style(Color(0.03, 0.13, 0.16, 0.96), 14, Color(GOLD, 0.55), 2, 12))
	var identity_row = HBoxContainer.new()
	identity_row.add_theme_constant_override("separation", 14)
	identity_panel.add_child(identity_row)
	var portrait_frame = PanelContainer.new()
	portrait_frame.custom_minimum_size = Vector2(170, 205)
	portrait_frame.add_theme_stylebox_override("panel", _style(Color(0.07, 0.18, 0.19, 0.96), 16, Color(TEAL, 0.62), 2, 5))
	var portrait = TextureRect.new()
	portrait.name = "CharacterPortrait"
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	var portrait_atlas = AtlasTexture.new()
	portrait_atlas.atlas = PlayerPortraitTexture
	portrait_atlas.region = Rect2(0, 0, PlayerPortraitTexture.get_width() / 4.0, PlayerPortraitTexture.get_height() / 2.0)
	portrait.texture = portrait_atlas
	portrait_frame.add_child(portrait)
	identity_row.add_child(portrait_frame)
	var identity = VBoxContainer.new()
	identity.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	identity.add_theme_constant_override("separation", 7)
	identity_row.add_child(identity)
	identity.add_child(_label(str(state.player.name), 22, INK))
	identity.add_child(_label("称号｜%s" % str(state.player.title), 14, GOLD))
	identity.add_child(_label("等级 Lv.%d / %d" % [int(state.player.level), GameData.MAX_LEVEL], 15, TEAL))
	identity.add_child(_character_progress_2d("体力 %d / %d" % [int(state.player.hp), int(stats.max_hp)], int(state.player.hp), int(stats.max_hp), TEAL))
	var xp_needed = GameData.xp_needed(int(state.player.level)) if int(state.player.level) < GameData.MAX_LEVEL else 1
	var xp_value = int(state.player.xp) if int(state.player.level) < GameData.MAX_LEVEL else 1
	var xp_copy = "经验 已满级" if int(state.player.level) >= GameData.MAX_LEVEL else "经验 %d / %d" % [xp_value, xp_needed]
	identity.add_child(_character_progress_2d(xp_copy, xp_value, xp_needed, GOLD))
	identity.add_child(_label("战斗%d场 · 胜利%d场\n银币 %d" % [int(state.player.battles), int(state.player.victories), int(state.player.silver)], 13, MUTED))
	content.add_child(identity_panel)
	var stat_grid = GridContainer.new()
	stat_grid.columns = 4
	stat_grid.add_theme_constant_override("h_separation", 7)
	stat_grid.add_theme_constant_override("v_separation", 7)
	for stat_entry in [
		{"icon": "⚔", "name": "攻击", "value": int(stats.attack), "color": RED},
		{"icon": "◆", "name": "防御", "value": int(stats.defense), "color": TEAL},
		{"icon": "➤", "name": "速度", "value": int(stats.speed), "color": Color("65aee8")},
		{"icon": "✦", "name": "寻宝", "value": "%d%%" % int(round(float(stats.drop_bonus) * 100.0)), "color": GOLD}
	]:
		var stat_card = Label.new()
		stat_card.text = "%s %s\n%s" % [stat_entry.icon, stat_entry.name, str(stat_entry.value)]
		stat_card.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		stat_card.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		stat_card.custom_minimum_size = Vector2(140, 68)
		stat_card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		stat_card.add_theme_font_size_override("font_size", 14)
		stat_card.add_theme_color_override("font_color", Color(stat_entry.color))
		stat_card.add_theme_stylebox_override("normal", _style(Color(0.025, 0.095, 0.115, 0.96), 11, Color(stat_entry.color, 0.48), 1, 7))
		stat_grid.add_child(stat_card)
	content.add_child(stat_grid)
	var recommend = _button("一键换上背包中的推荐装备", "gold")
	recommend.pressed.connect(_equip_recommended_2d)
	content.add_child(recommend)
	if inventory_notice != "":
		var notice = _label(inventory_notice, 14, GOLD)
		notice.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		notice.add_theme_stylebox_override("normal", _style(Color(0.20, 0.14, 0.04, 0.9), 10, Color(GOLD, 0.6), 1, 9))
		content.add_child(notice)
		inventory_notice = ""
	var scroll = ScrollContainer.new()
	scroll.custom_minimum_size.y = 365
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	content.add_child(scroll)
	var equipment_stack = VBoxContainer.new()
	equipment_stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	equipment_stack.add_theme_constant_override("separation", 8)
	scroll.add_child(equipment_stack)
	equipment_stack.add_child(_character_ship_card_2d())
	equipment_stack.add_child(_label("当前已装备｜最高强化 +10", 16, GOLD))
	var equipment_grid = GridContainer.new()
	equipment_grid.columns = 2
	equipment_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	equipment_grid.add_theme_constant_override("h_separation", 8)
	equipment_grid.add_theme_constant_override("v_separation", 8)
	for slot in ["weapon", "head", "body", "waist", "boots", "charm"]:
		equipment_grid.add_child(_equipped_upgrade_card_2d(slot))
	equipment_stack.add_child(equipment_grid)
	equipment_stack.add_child(_label("套装共鸣｜凑齐指定件数逐级激活", 16, GOLD))
	var visible_set_count = 0
	for set_progress in state.equipment_set_progress():
		if int(set_progress.count) <= 0:
			continue
		visible_set_count += 1
		equipment_stack.add_child(_equipment_set_card_2d(set_progress))
	if visible_set_count == 0:
		equipment_stack.add_child(_label("尚未穿戴套装装备。副本 Boss 会掉落带套装标记的部件。", 13, MUTED))
	equipment_stack.add_child(_character_ship_catalog_2d())
	var bag = _button("打开物品背包", "primary")
	bag.pressed.connect(_switch_overlay_to_inventory)
	content.add_child(bag)
	var close = _button("返回地图", "ghost")
	close.pressed.connect(_close_overlay)
	content.add_child(close)
	_open_overlay(content, true, Vector2(666, 1020))

func _character_ship_card_2d():
	var hull_id = str(state.ship.get("hull_id", "sea_swallow"))
	var hull = Dictionary(GameData.SHIP_HULLS.get(hull_id, GameData.SHIP_HULLS.sea_swallow))
	var sales_port = str(hull.get("sales_port", "venice_dock"))
	var port = Dictionary(GameData.TRADE_PORTS.get(sales_port, GameData.TRADE_PORTS.venice_dock))
	var profile = state.ship_speed_profile()
	var panel = PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _style(Color(0.035, 0.14, 0.18, 0.97), 13, Color(TEAL, 0.58), 2, 10))
	var stack = VBoxContainer.new()
	stack.add_theme_constant_override("separation", 7)
	panel.add_child(stack)
	stack.add_child(_label("座舰系统｜当前船只", 16, GOLD))
	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 11)
	stack.add_child(row)
	row.add_child(_ship_visual_2d(hull_id, 116))
	var info = VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_theme_constant_override("separation", 4)
	row.add_child(info)
	info.add_child(_label("Lv.%d  %s｜%s" % [int(hull.level), str(hull.name), str(hull.role)], 18, INK))
	info.add_child(_label("航速 %.1f节 · %d海里/日\n货舱 %d/%d格 · 船甲%d · 舰炮%d" % [float(profile.knots), int(profile.nm_per_day), state.cargo_used(), state.cargo_capacity(), state.ship_armor(), state.ship_cannon_power()], 13, TEAL))
	info.add_child(_label("帆装Lv.%d · 舱板Lv.%d · 装甲Lv.%d · 舰炮Lv.%d" % [int(state.ship.get("speed", 1)), int(state.ship.get("hold_level", 0)), int(state.ship.get("armor", 0)), int(state.ship.get("cannon_level", 0))], 12, MUTED))
	var trait_label = _label("船型专长｜%s\n船队收藏｜%d/9艘 · 产地｜%s · %s船行" % [str(hull.trait), state.owned_ship_ids().size(), str(port.name), str(port.get("ship_seller", "船老板"))], 12, GOLD)
	trait_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	stack.add_child(trait_label)
	var at_port = GameData.TRADE_PORTS.has(str(state.player.location))
	var local_port = Dictionary(GameData.TRADE_PORTS.get(str(state.player.location), {}))
	var local_offer = Dictionary(GameData.SHIP_HULLS.get(str(local_port.get("ship_offer", "")), {}))
	var shipyard = _button("查看本港船坞 · Lv.%d %s" % [int(local_offer.get("level", 0)), str(local_offer.get("name", "未发现"))] if at_port else "抵达港口后可查看当地船坞", "gold")
	shipyard.disabled = not at_port or not state.is_trade_unlocked()
	shipyard.pressed.connect(_open_shipyard_from_character_2d)
	stack.add_child(shipyard)
	return panel

func _ship_visual_2d(hull_id, icon_size):
	var frame = PanelContainer.new()
	frame.custom_minimum_size = Vector2(icon_size, icon_size)
	frame.add_theme_stylebox_override("panel", _style(Color(0.015, 0.075, 0.10, 0.98), 12, Color(GOLD, 0.46), 1, 5))
	var visual = TextureRect.new()
	visual.name = "CurrentShipModel"
	visual.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	visual.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	var texture = AtlasTexture.new()
	var cell_size = Vector2(PlayerShipTexture.get_width(), PlayerShipTexture.get_height()) / 3.0
	var hull = Dictionary(GameData.SHIP_HULLS.get(str(hull_id), GameData.SHIP_HULLS.sea_swallow))
	texture.atlas = PlayerShipTexture
	texture.region = Rect2(Vector2(hull.get("visual_cell", Vector2i.ZERO)) * cell_size, cell_size)
	visual.texture = texture
	frame.add_child(visual)
	return frame

func _character_ship_catalog_2d():
	var stack = VBoxContainer.new()
	stack.add_theme_constant_override("separation", 6)
	stack.add_child(_label("九港船型图鉴｜购入后永久加入船队，可在任一船坞换乘", 16, GOLD))
	var current_hull_id = str(state.ship.get("hull_id", "sea_swallow"))
	for hull_id in GameData.ship_hull_ids_by_level():
		var hull = Dictionary(GameData.SHIP_HULLS[str(hull_id)])
		var port_id = str(hull.sales_port)
		var port = Dictionary(GameData.TRADE_PORTS[port_id])
		var unlocked = state.is_port_unlocked(port_id)
		var owned = state.owns_ship(str(hull_id))
		var marker = "◆ 当前" if str(hull_id) == current_hull_id else ("● 已拥有" if owned else ("○ 可购买" if unlocked else "◇ 未发现"))
		var price_copy = "初始座舰" if int(hull.price) <= 0 else "%d银币" % int(hull.price)
		var copy = "%s｜Lv.%d %s · %s\n%s · %s船行｜%.1f节 · %d格 · 船甲%d · 舰炮%d · %s" % [marker, int(hull.level), str(hull.name), str(hull.role), str(port.name), str(port.get("ship_seller", "船老板")), float(hull.base_knots), int(hull.capacity), int(hull.armor), int(hull.cannon), price_copy if unlocked else "随主线解锁港口"]
		var row = _label(copy, 12, TEAL if unlocked else MUTED)
		row.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		row.add_theme_stylebox_override("normal", _style(Color(0.025, 0.095, 0.115, 0.88), 9, Color(TEAL if unlocked else MUTED, 0.35), 1, 7))
		stack.add_child(row)
	return stack

func _open_shipyard_from_character_2d():
	_close_overlay()
	call_deferred("_open_port_shipyard_2d", GameData.port_service_npc(str(state.player.location), "shipyard"))

func _character_progress_2d(copy, value, maximum, color):
	var stack = VBoxContainer.new()
	stack.add_theme_constant_override("separation", 2)
	stack.add_child(_label(str(copy), 12, Color(color)))
	var bar = ProgressBar.new()
	bar.max_value = max(1, int(maximum))
	bar.value = clamp(int(value), 0, int(maximum))
	bar.show_percentage = false
	bar.custom_minimum_size.y = 12
	bar.add_theme_stylebox_override("background", _style(Color(0.015, 0.055, 0.07, 0.95), 6))
	bar.add_theme_stylebox_override("fill", _style(Color(color, 0.82), 6))
	stack.add_child(bar)
	return stack

func _switch_overlay_to_inventory():
	_close_overlay()
	call_deferred("_open_inventory")

func _switch_overlay_to_character():
	_close_overlay()
	call_deferred("_open_character")

func _open_inventory():
	var content = VBoxContainer.new()
	content.add_theme_constant_override("separation", 10)
	content.add_child(_label("物品背包", 26, GOLD))
	var inventory_counts = _inventory_counts_2d()
	var bag_panel = PanelContainer.new()
	bag_panel.add_theme_stylebox_override("panel", _style(Color(0.03, 0.15, 0.17, 0.94), 12, Color(TEAL, 0.48), 1, 10))
	bag_panel.add_child(_label("◈ 银币 %d｜装备%d · 补给%d · 材料%d · 卡片%d\n装备后物品会移入独立的角色装备页" % [int(state.player.silver), int(inventory_counts.equipment), int(inventory_counts.consumable), int(inventory_counts.material), int(inventory_counts.card)], 14, TEAL))
	content.add_child(bag_panel)
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
	items.add_child(_label("背包物品｜按装备、补给、卡片分类排列", 16, GOLD))
	if state.inventory.is_empty():
		items.add_child(_label("背包是空的。", 16, MUTED))
	var item_ids = state.inventory.keys()
	item_ids.sort_custom(func(a, b): return _inventory_sort_key_2d(str(a)) < _inventory_sort_key_2d(str(b)))
	for item_id in item_ids:
		if not GameData.ITEMS.has(item_id):
			continue
		var item = GameData.ITEMS[item_id]
		items.add_child(_inventory_item_card_2d(item_id, item, int(state.inventory[item_id])))
	var character = _button("查看角色与已装备", "gold")
	character.pressed.connect(_switch_overlay_to_character)
	content.add_child(character)
	var close = _button("返回地图", "primary")
	close.pressed.connect(_close_overlay)
	content.add_child(close)
	_open_overlay(content, true, Vector2(666, 960))

func _equipped_upgrade_card_2d(slot):
	var item_id = str(state.equipment.get(slot, ""))
	var item = GameData.ITEMS.get(item_id, {})
	var level = state.equipment_upgrade_level(item_id) if item_id != "" else 0
	var rarity = str(item.get("rarity", "普通"))
	var card = PanelContainer.new()
	card.custom_minimum_size = Vector2(288, 168)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.add_theme_stylebox_override("panel", _style(Color(0.07, 0.105, 0.105, 0.95), 11, _rarity_color_2d(rarity), 2 if item_id != "" else 1, 9))
	var stack = VBoxContainer.new()
	stack.add_theme_constant_override("separation", 6)
	card.add_child(stack)
	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	stack.add_child(row)
	row.add_child(_item_visual_2d("equipment", item_id if item_id != "" else slot, rarity, slot, item_id != "", 62))
	var item_name = str(item.get("name", "尚未装备"))
	var stats_text = _item_stats_text_2d(item.get("stats", {})) if item_id != "" else "从背包选择该槽位装备"
	var set_name = state.equipment_set_name(item_id)
	var set_text = "\n套装 · %s" % set_name if set_name != "" else ""
	var info = _label("%s\n%s%s\n%s%s" % [GameData.SLOT_NAMES[slot], item_name, "  +%d" % level if level > 0 else "", stats_text, set_text], 12, INK if item_id != "" else MUTED)
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	row.add_child(info)
	var upgrade = _button("空槽位" if item_id == "" else ("已强化满级 +10" if level >= 10 else "强化至 +%d\n%s" % [level + 1, state.equipment_upgrade_requirement_text(slot)]), "gold")
	upgrade.custom_minimum_size = Vector2(0, 48)
	upgrade.add_theme_font_size_override("font_size", 13)
	upgrade.disabled = item_id == "" or level >= 10
	upgrade.pressed.connect(_upgrade_equipped_2d.bind(slot))
	stack.add_child(upgrade)
	return card

func _equipment_set_card_2d(set_progress):
	var card = PanelContainer.new()
	card.add_theme_stylebox_override("panel", _style(Color(0.10, 0.11, 0.08, 0.95), 11, Color(GOLD, 0.58), 1, 10))
	var stack = VBoxContainer.new()
	stack.add_theme_constant_override("separation", 4)
	card.add_child(stack)
	stack.add_child(_label("%s  %d/%d" % [str(set_progress.name), int(set_progress.count), int(set_progress.total)], 14, GOLD))
	for stage in Array(set_progress.stages):
		stack.add_child(_label("%s %d件｜%s" % ["✓" if bool(stage.active) else "○", int(stage.pieces), str(stage.text)], 12, TEAL if bool(stage.active) else MUTED))
	return card

func _upgrade_equipped_2d(slot):
	var result = state.upgrade_equipped(slot)
	inventory_notice = ("✓ " if bool(result.get("ok", false)) else "！") + str(result.get("message", "强化失败"))
	_refresh_hud()
	_close_overlay()
	if bool(result.get("quest_completed", false)):
		call_deferred("_show_quest_claim")
	else:
		call_deferred("_open_character")

func _inventory_item_card_2d(item_id, item, count):
	var card = PanelContainer.new()
	card.add_theme_stylebox_override("panel", _style(Color(0.04, 0.13, 0.16, 0.92), 11, _rarity_color_2d(str(item.rarity)), 2, 10))
	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	card.add_child(row)
	row.add_child(_item_visual_2d(str(item.type), item_id, str(item.rarity), str(item.get("slot", "")), false, 76))
	var text_stack = VBoxContainer.new()
	text_stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_stack.add_theme_constant_override("separation", 3)
	row.add_child(text_stack)
	text_stack.add_child(_label("%s  ×%d" % [item.name, count], 15, INK))
	text_stack.add_child(_label("%s%s" % [str(item.rarity), " · %s" % GameData.SLOT_NAMES[str(item.slot)] if str(item.type) == "equipment" else ""], 12, _rarity_color_2d(str(item.rarity))))
	var description = _label(str(item.description), 12, MUTED)
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text_stack.add_child(description)
	if str(item.type) == "equipment":
		text_stack.add_child(_label(_item_stats_text_2d(item.get("stats", {})), 12, TEAL))
		var set_name = state.equipment_set_name(item_id)
		if set_name != "":
			text_stack.add_child(_label("套装 · %s" % set_name, 12, GOLD))
		var delta = state.equipment_score_delta(item_id)
		var comparison = "较当前战力 %+d" % delta if delta != 0 else "与当前装备战力相当"
		text_stack.add_child(_label(comparison, 12, GOLD if delta > 0 else MUTED))
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
		"material":
			action.text = "锻造材料"
			action.disabled = true
		_:
			action.disabled = true
	row.add_child(action)
	return card

func _inventory_counts_2d():
	var counts = {"equipment": 0, "consumable": 0, "material": 0, "card": 0, "other": 0}
	for item_id in state.inventory:
		if not GameData.ITEMS.has(str(item_id)):
			continue
		var item_type = str(GameData.ITEMS[str(item_id)].get("type", "other"))
		var bucket = item_type if counts.has(item_type) else "other"
		counts[bucket] += int(state.inventory[item_id])
	return counts

func _inventory_sort_key_2d(item_id):
	if not GameData.ITEMS.has(item_id):
		return "9_%s" % item_id
	var item = GameData.ITEMS[item_id]
	var type_order = {"equipment": "0", "consumable": "1", "material": "2", "mystery": "3", "card": "4"}
	var rarity_order = {"唯一": "0", "神话": "1", "传说": "2", "史诗": "3", "珍稀": "4", "优秀": "5", "普通": "6", "稀有补给": "3", "远航餐食": "4", "补给": "5", "酒馆食物": "6", "未知": "7"}
	return "%s_%s_%s" % [str(type_order.get(str(item.type), "8")), str(rarity_order.get(str(item.rarity), "8")), str(item.name)]

func _rarity_color_2d(rarity):
	var colors = {
		"普通": MUTED, "补给": Color("69c8a8"), "酒馆食物": Color("d5a867"),
		"稀有补给": Color("62b8ef"), "远航餐食": Color("64d9c6"), "优秀": Color("54c8a8"),
		"珍稀": Color("65aee8"), "史诗": Color("bb7bea"), "传说": Color("efb95f"),
		"神话": Color("ef785f"), "唯一": Color("f6df8b"), "未知": Color("88949d")
	}
	return Color(colors.get(str(rarity), MUTED))

func _item_visual_2d(kind, item_id, rarity = "普通", slot = "", equipped = false, icon_size = 76):
	var visual = ItemIconScript.new()
	visual.custom_minimum_size = Vector2(icon_size, icon_size)
	visual.configure(str(kind), str(item_id), str(rarity), str(slot), bool(equipped))
	return visual

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

func _equip_recommended_2d():
	var result = state.equip_recommended()
	inventory_notice = ("✓ " if bool(result.get("ok", false)) else "· ") + str(result.get("message", ""))
	_refresh_hud()
	_close_overlay()
	call_deferred("_open_character")

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
	var progress = state.story_progress()
	content.add_child(_label("%s %d/%d｜%s %d/%d" % [str(progress.volume), int(progress.volume_completed), int(progress.volume_total), str(progress.chapter), int(progress.chapter_completed), int(progress.chapter_total)], 15, TEAL))
	content.add_child(_label("持有银币：%d" % int(state.player.silver), 14, GOLD))
	var recap_titles = state.completed_story_titles(3)
	if not recap_titles.is_empty():
		var recap = _label("剧情回顾｜已完成：%s\n%s" % [" → ".join(recap_titles), str(progress.summary)], 14, MUTED)
		recap.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		recap.add_theme_stylebox_override("normal", _style(Color(0.04, 0.13, 0.16, 0.92), 10, Color(TEAL, 0.28), 1, 10))
		content.add_child(recap)
	var quest = state.get_current_quest()
	if quest.is_empty():
		content.add_child(_label("第十三卷·封印迷阵已完成", 22, GOLD))
		var epilogue = _label("从威尼斯的海边小屋到扬州终潮阵，你走遍九港、破除十三卷潮灾，并把失落的航路重新交还给普通水手。贸易订单、料理、悬赏与远征仍会继续记录你的四海生涯。\n\n当前称号：%s" % str(state.player.title), 16, TEAL)
		epilogue.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		content.add_child(epilogue)
	else:
		content.add_child(_label(quest.title, 22, INK))
		var story = _label(quest.story, 17, MUTED)
		story.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		story.custom_minimum_size.y = 130
		content.add_child(story)
		content.add_child(_label("当前进度  %d / %d" % [state.quest_progress, int(quest.objective.need)], 18, TEAL))
		content.add_child(_label("下一步｜%s" % GameData.objective_name(quest.objective), 15, GOLD))
		var action_plan = _label("行动清单\n• %s" % "\n• ".join(state.quest_action_steps()), 14, Color("8ecbd0"))
		action_plan.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		action_plan.add_theme_stylebox_override("normal", _style(Color(0.04, 0.16, 0.19, 0.88), 11, Color(TEAL, 0.38), 1, 12))
		content.add_child(action_plan)
		if state.quest_can_claim():
			var claim = _button("领取任务奖励", "gold")
			claim.pressed.connect(_claim_quest_2d)
			content.add_child(claim)
		else:
			var navigate = _button("导航到当前任务", "primary")
			navigate.pressed.connect(_navigate_to_quest)
			content.add_child(navigate)
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
	var target_actor_id = ""
	var target_name_override = ""
	if objective.type == "visit":
		for cargo_id in Dictionary(objective.get("cargo", {})):
			var cargo_need = int(objective.cargo[cargo_id])
			var cargo_held = int(state.cargo.get(str(cargo_id), 0))
			if cargo_held < cargo_need:
				target_location = str(GameData.TRADE_GOODS[str(cargo_id)].origin)
				target_actor_id = str(GameData.TRADE_PORTS.get(target_location, {}).get("merchant_npc", ""))
				target_name_override = "远航准备·%s %d/%d" % [GameData.TRADE_GOODS[str(cargo_id)].name, cargo_held, cargo_need]
				break
		if target_location == "":
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
	elif objective.type == "trade_order":
		var order = GameData.TRADE_ORDERS.get(str(objective.target), {})
		var good_id = str(order.get("good", ""))
		var needed = int(order.get("amount", 1))
		var held = int(state.cargo.get(good_id, 0))
		if GameData.TRADE_GOODS.has(good_id) and held < needed:
			target_location = str(GameData.TRADE_GOODS[good_id].origin)
			target_actor_id = str(GameData.TRADE_PORTS.get(target_location, {}).get("merchant_npc", ""))
			target_name_override = "采购%s %d/%d" % [GameData.TRADE_GOODS[good_id].name, held, needed]
		else:
			target_location = str(order.get("port", "venice_dock"))
			target_actor_id = str(GameData.TRADE_PORTS.get(target_location, {}).get("order_npc", ""))
	elif objective.type == "cook":
		var recipe = GameData.RECIPES.get(str(objective.target), {"port": "malta_dock", "cargo": {}})
		for good_id in recipe.cargo:
			var needed = int(recipe.cargo[good_id])
			var held = int(state.cargo.get(str(good_id), 0))
			if held < needed:
				target_location = str(GameData.TRADE_GOODS[str(good_id)].origin)
				target_actor_id = str(GameData.TRADE_PORTS.get(target_location, {}).get("merchant_npc", ""))
				target_name_override = "采购%s %d/%d" % [GameData.TRADE_GOODS[str(good_id)].name, held, needed]
				break
		if target_location == "":
			target_location = str(recipe.port)
			target_actor_id = _port_service_npc(target_location, "cook")
			target_name_override = "%s厨房" % GameData.TRADE_PORTS[target_location].name
	elif objective.type == "trade_buy":
		target_location = str(GameData.TRADE_GOODS.get(str(objective.target), {"origin": "venice_dock"}).origin)
		target_actor_id = str(GameData.TRADE_PORTS.get(target_location, {}).get("merchant_npc", ""))
	elif objective.type == "trade_sell":
		target_location = str(objective.get("location", ""))
		if target_location == "":
			target_location = str(state.player.location) if str(state.player.location) in GameData.TRADE_PORTS else "venice_dock"
		target_actor_id = str(GameData.TRADE_PORTS.get(target_location, {}).get("merchant_npc", ""))
	elif objective.type == "trade_reputation":
		target_location = str(state.player.location) if str(state.player.location) in GameData.TRADE_PORTS else "venice_dock"
		target_actor_id = GameData.port_service_npc(target_location, "trade_order")
		if target_actor_id == "":
			target_actor_id = GameData.port_service_npc(target_location, "market")
	elif objective.type == "prepare_voyage":
		target_location = str(state.player.location) if str(state.player.location) in GameData.TRADE_PORTS else "venice_dock"
		target_actor_id = GameData.port_service_npc(target_location, "harbor")
	elif objective.type == "upgrade_ship":
		target_location = str(state.player.location) if str(state.player.location) in GameData.TRADE_PORTS else "venice_dock"
		target_actor_id = _port_service_npc(target_location, "shipyard")
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
	var actor_id = target_actor_id if target_actor_id != "" else ("" if objective.type in ["visit", "trade_order", "trade_reputation", "prepare_voyage", "trade_buy", "trade_sell", "upgrade_ship", "cook"] else str(objective.target))
	var target_name = target_name_override if target_name_override != "" else GameData.objective_name(objective)
	if target_name_override == "" and objective.type == "trade_order" and target_location in GameData.TRADE_PORTS:
		target_name = "%s商会" % GameData.TRADE_PORTS[target_location].name
	return {
		"region": str(region_by_location.get(target_location, "city")),
		"location": target_location, "actor_id": actor_id,
		"name": target_name
	}

func _port_service_npc(port_id, service_id):
	var resolved_port = str(port_id)
	if not GameData.LOCATIONS.has(resolved_port):
		return ""
	for npc_id in GameData.LOCATIONS[resolved_port].npcs:
		if str(GameData.NPCS.get(str(npc_id), {}).get("service", "")) == str(service_id):
			return str(npc_id)
	return str(GameData.TRADE_PORTS.get(resolved_port, {}).get("merchant_npc", ""))

func _refresh_waypoint():
	if not is_instance_valid(waypoint_label) or not is_instance_valid(navigation_button):
		return
	if current_region == "sea" and not state.active_voyage.is_empty():
		var destination = str(state.active_voyage.destination)
		navigation_button.text = "◆ 自动航行 · %s" % GameData.TRADE_PORTS[destination].name
		waypoint_label.visible = true
		waypoint_label.text = "◆ %s港" % GameData.TRADE_PORTS[destination].name
		waypoint_world_target = _sea_destination_position()
		_update_waypoint_screen_position()
		return
	var target = _quest_navigation_target()
	var crosses_ports = str(target.location) in GameData.TRADE_PORTS and str(state.player.location) in GameData.TRADE_PORTS and str(target.location) != str(state.player.location)
	navigation_button.text = ("◆ 航线导航 · %s" if crosses_ports else "◆ 步行导航 · %s") % target.name
	if str(target.region) != current_region:
		waypoint_world_target = Vector2.ZERO
		waypoint_label.visible = false
		hint_label.text = "任务目标在%s，点击“步行导航”自动沿路前往" % _region_name(str(target.region))
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
	if current_region == "sea" and not state.active_voyage.is_empty():
		_cancel_task_navigation()
		move_target = _sea_destination_position()
		has_move_target = true
		hint_label.text = "自动航行沿主航道前进并迎战挡路威胁；想避战请拖动摇杆绕行。"
		return
	var quest = state.get_current_quest()
	if not quest.is_empty() and str(quest.objective.type) == "upgrade_equipment":
		_open_character()
		return
	var navigation_target = _quest_navigation_target()
	var objective_type = str(quest.objective.type) if not quest.is_empty() else ""
	var needs_harbor = not quest.is_empty() and (objective_type in ["trade_buy", "trade_sell", "trade_order", "trade_reputation", "prepare_voyage", "upgrade_ship", "cook"] or (objective_type == "visit" and str(quest.objective.target) in GameData.TRADE_PORTS))
	if needs_harbor:
		var target_port = str(navigation_target.get("location", ""))
		var objective_service = {"trade_buy": "market", "trade_sell": "market", "trade_order": "orders", "trade_reputation": "orders", "prepare_voyage": "harbor", "upgrade_ship": "shipyard", "cook": "kitchen"}.get(objective_type, "")
		var target_actor_service = _npc_service(str(navigation_target.get("actor_id", "")))
		if target_actor_service != "":
			objective_service = {"market": "market", "harbor": "harbor", "shipyard": "shipyard", "trade_order": "orders", "cook": "kitchen"}.get(target_actor_service, objective_service)
		if target_port in GameData.TRADE_PORTS and str(state.player.location) in GameData.TRADE_PORTS and str(state.player.location) != target_port:
			_open_task_sailing_route(target_port)
			return
		if str(state.player.location) == target_port:
			task_navigation_open_service = str(objective_service)
		elif target_port in GameData.TRADE_PORTS:
			task_navigation_open_service = "sail:%s" % target_port
		else:
			task_navigation_open_service = str(objective_service)
	else:
		task_navigation_open_service = ""
	if is_instance_valid(overlay):
		_close_overlay()
	task_navigation_target = navigation_target
	task_navigation_active = true
	_continue_task_navigation()

func _open_task_sailing_route(target_port):
	var destination = str(target_port)
	if not state.is_port_unlocked(destination):
		_show_message("航线尚未发现", "继续推进主线，取得前往%s的海图后再来。" % GameData.TRADE_PORTS[destination].name)
		return
	var unlocked_ports = []
	for port_id in GameData.TRADE_PORTS:
		if state.is_port_unlocked(str(port_id)):
			unlocked_ports.append(str(port_id))
	var path = GameData.trade_route_path(str(state.player.location), destination, unlocked_ports)
	if path.size() < 2:
		_show_message("暂时无法规划航线", "%s尚未加入当前海图。" % GameData.TRADE_PORTS[destination].name)
		return
	_open_sailing_map(destination)

func _continue_task_navigation():
	if not task_navigation_active or task_navigation_target.is_empty():
		return
	if str(task_navigation_target.region) == current_region:
		task_navigation_portal = {}
		var target_position = _task_target_position(task_navigation_target)
		if target_position == Vector2.ZERO:
			_cancel_task_navigation()
			hint_label.text = "暂时无法找到%s，请查看区域地图。" % str(task_navigation_target.name)
			return
		_set_task_navigation_destination(target_position)
		hint_label.text = "正在沿道路前往：%s" % str(task_navigation_target.name)
		return
	var next_region = _task_navigation_next_region(current_region, str(task_navigation_target.region))
	var portal = _task_navigation_portal_to(next_region)
	if portal.is_empty():
		_cancel_task_navigation()
		hint_label.text = "当前区域没有通往%s的道路入口。" % _region_name(next_region)
		return
	task_navigation_portal = portal
	_set_task_navigation_destination(portal.node.position)
	hint_label.text = "正在步行前往%s，再去%s" % [str(portal.name), str(task_navigation_target.name)]

func _task_target_position(target):
	var target_position = Vector2.ZERO
	for entry in actors:
		if str(entry.id) == str(target.actor_id) and str(target.actor_id) != "":
			target_position = entry.node.position
			break
	if target_position == Vector2.ZERO:
		var location_id = str(target.location)
		if location_id in GameData.TRADE_PORTS:
			location_id = "venice_dock"
		var zone = region_zones.get(current_region, {}).get(location_id, {})
		if not zone.is_empty():
			target_position = zone.point
	return target_position

func _task_navigation_next_region(from_region, target_region):
	if str(from_region) == str(target_region):
		return str(target_region)
	match str(from_region):
		"city":
			if str(target_region) in ["black_sail", "white_whale", "legacy"]:
				return str(target_region)
			return "field"
		"field":
			return "dungeon" if str(target_region) == "dungeon" else "city"
		"dungeon":
			return "field"
		"black_sail":
			return "city"
		"white_whale":
			return "city"
		"legacy":
			return "city"
		_:
			return str(target_region)

func _task_navigation_portal_to(region_id):
	for entry in actors:
		if str(entry.kind) == "travel" and str(entry.id) == str(region_id):
			return entry
	return {}

func _set_task_navigation_destination(destination):
	task_navigation_path = _build_task_navigation_path(player_actor.position, Vector2(destination))
	task_navigation_path_index = 0
	if task_navigation_path.is_empty():
		task_navigation_path.append(Vector2(destination))
	move_target = task_navigation_path[0]
	has_move_target = true

func _advance_task_navigation_waypoint():
	task_navigation_path_index += 1
	if task_navigation_path_index >= task_navigation_path.size():
		return false
	move_target = task_navigation_path[task_navigation_path_index]
	return true

func _finish_task_navigation_leg():
	if not task_navigation_active:
		return
	if not task_navigation_portal.is_empty():
		var portal = task_navigation_portal
		task_navigation_portal = {}
		_switch_region(str(portal.id), str(portal.location))
		if task_navigation_active:
			_continue_task_navigation()
		return
	var target_name = str(task_navigation_target.get("name", "任务目标"))
	var open_service = task_navigation_open_service
	has_move_target = false
	move_target = player_actor.position
	player_actor.set_motion(Vector2.ZERO)
	task_navigation_active = false
	task_navigation_target = {}
	task_navigation_path = PackedVector2Array()
	task_navigation_path_index = 0
	task_navigation_open_service = ""
	_update_nearest_actor()
	hint_label.text = "已步行到达：%s｜靠近后点击互动" % target_name
	if open_service == "market":
		call_deferred("_open_trade_2d")
	elif open_service == "harbor":
		call_deferred("_open_port_harbor_2d")
	elif open_service == "shipyard":
		call_deferred("_open_port_shipyard_2d")
	elif open_service == "orders":
		call_deferred("_open_port_orders_2d")
	elif open_service == "kitchen":
		call_deferred("_open_port_kitchen_2d")
	elif open_service.begins_with("sail:"):
		call_deferred("_open_sailing_map", open_service.trim_prefix("sail:"))

func _cancel_task_navigation():
	task_navigation_active = false
	task_navigation_target = {}
	task_navigation_portal = {}
	task_navigation_path = PackedVector2Array()
	task_navigation_path_index = 0
	task_navigation_open_service = ""

func _build_task_navigation_path(from_position, destination):
	var columns = int(ceil(WORLD_SIZE.x / NAVIGATION_GRID_SIZE))
	var rows = int(ceil(WORLD_SIZE.y / NAVIGATION_GRID_SIZE))
	var grid = AStarGrid2D.new()
	grid.region = Rect2i(0, 0, columns, rows)
	grid.cell_size = Vector2.ONE * NAVIGATION_GRID_SIZE
	grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	grid.update()
	for y in range(rows):
		for x in range(columns):
			var point = Vector2(x * NAVIGATION_GRID_SIZE, y * NAVIGATION_GRID_SIZE)
			if not _is_walkable(point):
				grid.set_point_solid(Vector2i(x, y), true)
	var start_id = _nearest_open_navigation_cell(grid, _navigation_cell(from_position, columns, rows), columns, rows)
	var end_id = _nearest_open_navigation_cell(grid, _navigation_cell(destination, columns, rows), columns, rows)
	if grid.is_point_solid(start_id) or grid.is_point_solid(end_id):
		return PackedVector2Array([destination])
	var raw_path = grid.get_point_path(start_id, end_id)
	var path = PackedVector2Array()
	for point in raw_path:
		if Vector2(point).distance_to(from_position) > NAVIGATION_GRID_SIZE * 0.45:
			path.append(Vector2(point))
	if path.is_empty() or path[path.size() - 1].distance_to(destination) > NAVIGATION_REACH_DISTANCE:
		path.append(destination)
	return path

func _navigation_cell(position, columns, rows):
	return Vector2i(clamp(int(round(float(position.x) / NAVIGATION_GRID_SIZE)), 0, columns - 1), clamp(int(round(float(position.y) / NAVIGATION_GRID_SIZE)), 0, rows - 1))

func _nearest_open_navigation_cell(grid, origin, columns, rows):
	if not grid.is_point_solid(origin):
		return origin
	for radius in range(1, 7):
		for y in range(origin.y - radius, origin.y + radius + 1):
			for x in range(origin.x - radius, origin.x + radius + 1):
				var candidate = Vector2i(x, y)
				if x >= 0 and x < columns and y >= 0 and y < rows and not grid.is_point_solid(candidate):
					return candidate
	return origin

func _open_world_map():
	var content = VBoxContainer.new()
	content.add_theme_constant_override("separation", 10)
	var active_port = _active_city_port_id()
	var city_data = GameData.PORT_CITY_MAPS[active_port]
	content.add_child(_label("%s · 城内地图" % GameData.TRADE_PORTS[active_port].name, 26, GOLD))
	var guide = _label("%s｜%s\n选择人物或地点后，角色会沿道路步行前往；跨城市必须从港务官处出航。" % [str(city_data.title), str(city_data.landmark)], 15, MUTED)
	guide.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(guide)
	if state.is_trade_unlocked():
		var sea_map_button = _button("打开九港航海图 · 查看航线与港口", "gold")
		sea_map_button.pressed.connect(_open_sailing_map)
		content.add_child(sea_map_button)
	var scroll = ScrollContainer.new()
	scroll.custom_minimum_size.y = 520
	content.add_child(scroll)
	var list = VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 8)
	scroll.add_child(list)
	list.add_child(_label("城市地标", 17, TEAL))
	var districts = _label("◆ %s" % "　◆ ".join(Array(city_data.districts)), 14, INK)
	districts.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	list.add_child(districts)
	list.add_child(_label("开放广场", 17, TEAL))
	var plaza_guide = _label("本城不设置可进入房屋；所有人物都在广场上，可直接步行接近并按职能互动。", 14, INK)
	plaza_guide.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	list.add_child(plaza_guide)
	list.add_child(_label("城内人物与职能", 17, TEAL))
	for npc_id in Dictionary(city_data.npc_positions):
		if not GameData.NPCS.has(str(npc_id)):
			continue
		var npc = GameData.NPCS[str(npc_id)]
		var npc_destination = _button("步行前往 · %s｜%s" % [str(npc.name), GameData.npc_service_label(str(npc_id))], "ghost")
		npc_destination.pressed.connect(_travel_to_city_npc.bind(active_port, str(npc_id)))
		list.add_child(npc_destination)
	if active_port != "venice_dock":
		var local_expedition = _current_story_expedition()
		if not local_expedition.is_empty() and str(local_expedition.port) == active_port and state.quest_index >= int(local_expedition.quest_start) + 3:
			list.add_child(_label("本城远征入口", 17, TEAL))
			var expedition_button = _button("步行前往 · %s" % str(local_expedition.name), "gold")
			expedition_button.pressed.connect(_travel_to_location.bind(str(local_expedition.location)))
			list.add_child(expedition_button)
		var remote_close = _button("返回%s街道" % GameData.TRADE_PORTS[active_port].name, "primary")
		remote_close.pressed.connect(_close_overlay)
		content.add_child(remote_close)
		_open_overlay(content, true, Vector2(666, 960))
		return
	for group in [
		{"title": "威尼斯城内", "locations": ["alisa_hut", "venice_tavern", "venice_square", "venice_market", "venice_dock", "venice_north_gate"]},
		{"title": "威尼斯城外", "locations": ["residential_quarter", "venice_mine", "venice_back_hill", "venice_wildwood"]},
		{"title": "四层经验副本", "locations": ["training_dungeon_1", "training_dungeon_2", "training_dungeon_3", "training_dungeon_4"]}
		,{"title": "黑帆据点", "locations": ["black_sail_1", "black_sail_2", "black_sail_3", "black_sail_4"]}
		,{"title": "白鲸号残骸", "locations": ["white_whale_1", "white_whale_2", "white_whale_3", "white_whale_4"]}
		,{"title": "终局潮汐远征", "locations": ["legacy_basin", "legacy_changan", "legacy_earth", "legacy_tira", "legacy_demon_legend", "legacy_jade", "legacy_fire", "legacy_return", "legacy_shears", "legacy_seal"]}
	]:
		list.add_child(_label(group.title, 17, TEAL))
		for location_id in group.locations:
			var destination = _button("步行前往 · %s" % GameData.LOCATIONS[location_id].name, "ghost")
			var is_training = str(location_id).begins_with("training_dungeon_")
			var is_black_sail = str(location_id).begins_with("black_sail_")
			var is_white_whale = str(location_id).begins_with("white_whale_")
			var is_legacy = str(location_id).begins_with("legacy_")
			var lock_text = _dungeon_floor_lock(location_id) if is_training or is_black_sail or is_white_whale else ""
			if is_legacy:
				var expedition = _expedition_for_location(location_id)
				if not expedition.is_empty() and (state.quest_index < int(expedition.quest_start) + 3 or int(state.player.level) < int(expedition.min_level)):
					lock_text = "随主线抵达%s并完成远征准备后开放" % GameData.TRADE_PORTS[str(expedition.port)].name
			destination.disabled = lock_text != "" or (is_training and int(state.player.level) < 3) or (is_black_sail and (int(state.player.level) < 6 or state.quest_index < 12)) or (is_white_whale and (int(state.player.level) < 20 or state.quest_index < 32))
			destination.tooltip_text = lock_text
			destination.pressed.connect(_travel_to_location.bind(location_id))
			list.add_child(destination)
	var close = _button("返回地图", "primary")
	close.pressed.connect(_close_overlay)
	content.add_child(close)
	_open_overlay(content, true, Vector2(666, 960))

func _travel_to_city_npc(port_id, npc_id):
	_close_overlay()
	task_navigation_open_service = ""
	task_navigation_target = {
		"region": "city",
		"location": str(port_id),
		"actor_id": str(npc_id),
		"name": "%s · %s" % [str(GameData.NPCS[str(npc_id)].name), GameData.npc_service_label(str(npc_id))]
	}
	task_navigation_active = true
	_continue_task_navigation()

func _travel_to_location(location_id):
	var region = str(region_by_location.get(location_id, "city"))
	var current_location = str(state.player.location)
	var at_remote_port = current_location in GameData.TRADE_PORTS and current_location != "venice_dock"
	var local_expedition_available = region not in ["city", "field", "dungeon"] and not _task_navigation_portal_to(region).is_empty()
	if at_remote_port and not local_expedition_available:
		_close_overlay()
		_show_message("需要先乘船返航", "你现在停泊在%s，不能从区域地图直接跳回威尼斯。请打开九港航海图，乘船返回威尼斯后再步行前往%s。" % [GameData.TRADE_PORTS[current_location].name, GameData.LOCATIONS[location_id].name])
		return
	_close_overlay()
	task_navigation_open_service = ""
	task_navigation_target = {
		"region": region,
		"location": str(location_id),
		"actor_id": "",
		"name": str(GameData.LOCATIONS[location_id].name)
	}
	task_navigation_active = true
	_continue_task_navigation()

func _region_name(region_id):
	match region_id:
		"sea": return "航行海域"
		"field": return "威尼斯城外"
		"dungeon": return "四层经验副本"
		"black_sail": return "黑帆据点"
		"white_whale": return "白鲸号残骸"
		"legacy": return "终局潮汐远征"
		_: return "%s城内" % GameData.TRADE_PORTS[_active_city_port_id()].name

func _open_sailing_map(preselect = ""):
	if not state.is_trade_unlocked():
		_show_message("航海图尚未开放", "完成威尼斯四层试炼后，船老板会交给你海燕号与第一张航线图。")
		return
	var content = VBoxContainer.new()
	content.add_theme_constant_override("separation", 10)
	content.add_child(_label("九港航海图", 26, GOLD))
	var at_port = GameData.TRADE_PORTS.has(str(state.player.location))
	var current_name = GameData.TRADE_PORTS[str(state.player.location)].name if at_port else GameData.LOCATIONS.get(str(state.player.location), GameData.LOCATIONS.venice_square).name
	var guide_text = "①选择已发现港口　②检查体力、风险与货舱　③正常出航进入海域驾驶；付费传送直接抵港。\n当前停泊：%s" % current_name if at_port else "你正在%s。可以查看海图，但启航前需要先走到港口。" % current_name
	var guide = _label(guide_text, 14, MUTED)
	guide.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(guide)
	sailing_map = SailingMapScript.new()
	sailing_map.game_state = state
	sailing_map.custom_minimum_size = Vector2(610, 500)
	sailing_map.port_selected.connect(_select_sailing_destination)
	content.add_child(sailing_map)
	sailing_route_label = _label("自由航线：任意两座已发现港口均可直航。距离决定航期，航经海域决定敌人与怪物。", 15, INK)
	sailing_route_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	sailing_route_label.custom_minimum_size.y = 70
	sailing_route_label.add_theme_stylebox_override("normal", _style(Color(0.03, 0.14, 0.17, 0.94), 10, Color(TEAL, 0.45), 1, 10))
	content.add_child(sailing_route_label)
	sailing_confirm_button = _button("选择目的港后正常出航", "gold")
	sailing_confirm_button.disabled = true
	sailing_confirm_button.pressed.connect(_start_sailing_voyage)
	content.add_child(sailing_confirm_button)
	sailing_transfer_button = _button("选择目的港后付费传送", "ghost")
	sailing_transfer_button.disabled = true
	sailing_transfer_button.pressed.connect(_transfer_sailing_destination)
	content.add_child(sailing_transfer_button)
	var close = _button("返回港口", "primary")
	close.pressed.connect(_close_overlay)
	content.add_child(close)
	_open_overlay(content, false, Vector2(666, 1040))
	sailing_map.configure(state)
	if str(preselect) != "":
		sailing_map.select_port(str(preselect))

func _select_sailing_destination(port_id):
	sailing_destination = str(port_id)
	if not GameData.TRADE_PORTS.has(str(state.player.location)):
		sailing_route_label.text = "这里不是港口。请关闭海图，按照任务导航步行前往码头后再启航。"
		sailing_confirm_button.disabled = true
		sailing_transfer_button.disabled = true
		return
	if sailing_destination == str(state.player.location):
		sailing_route_label.text = "海燕号当前就停泊在%s。请选择另一座港口。" % GameData.TRADE_PORTS[sailing_destination].name
		sailing_confirm_button.disabled = true
		sailing_transfer_button.disabled = true
		return
	var route = GameData.trade_route(str(state.player.location), sailing_destination)
	if route.is_empty():
		sailing_route_label.text = "无法取得%s与%s之间的航海距离。" % [GameData.TRADE_PORTS[str(state.player.location)].name, GameData.TRADE_PORTS[sailing_destination].name]
		sailing_confirm_button.disabled = true
		sailing_transfer_button.disabled = true
		return
	var plan = state.voyage_plan(sailing_destination)
	var days = int(plan.days)
	var risk = int(plan.risk)
	var destination = GameData.TRADE_PORTS[sailing_destination]
	var threats = []
	var planned_enemy_ids = Array(plan.enemy_ids)
	var planned_enemy_levels = Array(plan.get("enemy_levels", []))
	for index in range(planned_enemy_ids.size()):
		var enemy_id = str(planned_enemy_ids[index])
		var threat_level = int(planned_enemy_levels[index]) if index < planned_enemy_levels.size() else int(GameData.ENEMIES[enemy_id].level)
		threats.append("%sLv.%d" % [GameData.ENEMIES[enemy_id].name, threat_level])
	var stamina_cost = int(plan.stamina_cost)
	var hp_after = int(state.player.hp) - stamina_cost
	var storm_loss = 2 if str(plan.tier) == "oceanic" else 1
	sailing_route_label.text = "%s → %s｜九港大地图 · %s｜%d海里 · 预计%d日｜风险%d%%\n%s · 帆装Lv.%d · %.1f节 · %d海里/日｜货舱%d格 · 船甲%d\n航经：%s｜威胁情报：%s｜动态建议Lv.%d（随角色与任务阶段匹配）；附近敌人会主动追击\n正常出航免费：消耗%d体力（%d→%d）｜潜水寻宝%d%%｜无护航遇风暴最多损失%d单位货物\n付费传送：%d银币 · 1日直达 · 无海战/打捞｜特产：%s" % [GameData.TRADE_PORTS[str(state.player.location)].name, destination.name, str(plan.tier_name), int(plan.distance_nm), days, risk, str(state.ship.name), int(plan.ship_level), float(plan.speed_knots), int(plan.nm_per_day), state.cargo_capacity(), state.ship_armor(), str(plan.waters_text), "、".join(threats), int(plan.recommended_level), stamina_cost, int(state.player.hp), max(0, hp_after), int(plan.dive_chance), storm_loss, int(route.fee), destination.specialty]
	if int(state.player.level) + 5 < int(plan.recommended_level):
		sailing_route_label.text += "\n⚠ 当前等级偏低：建议手动绕开强敌、强化装备，或使用付费传送。"
	elif state.voyage_protection > 0:
		sailing_route_label.text += "\n护航物资将在本次启航时消耗，并保护一次风暴。"
	sailing_confirm_button.text = "正常出航 · %d体力 · 前往%s" % [stamina_cost, destination.name]
	sailing_confirm_button.disabled = int(state.player.hp) <= stamina_cost
	if sailing_confirm_button.disabled:
		sailing_route_label.text += "\n⚠ 体力不足：先住宿或使用补给；不能以0体力离港。"
	sailing_transfer_button.text = "付费传送至%s · %d银币" % [destination.name, int(route.fee)]
	sailing_transfer_button.disabled = int(state.player.silver) < int(route.fee)
	if sailing_transfer_button.disabled:
		sailing_route_label.text += "\n传送银币不足，还差%d；仍可免费正常出航。" % (int(route.fee) - int(state.player.silver))

func _start_sailing_voyage(duration = 2.2):
	if sailing_destination == "" or not is_instance_valid(sailing_map):
		return
	var departure = state.begin_voyage(sailing_destination)
	if not bool(departure.get("ok", false)):
		_show_message("无法启航", str(departure.get("message", "航线不可用")))
		return
	AudioDirector.play_sfx("sail")
	_close_overlay()
	_enter_active_voyage()

func _transfer_sailing_destination():
	if sailing_destination == "":
		return
	var result = state.transfer_to(sailing_destination)
	if not bool(result.get("ok", false)):
		_show_message("无法传送", str(result.get("message", "传送船不可用。")))
		return
	AudioDirector.play_sfx("sail")
	_close_overlay()
	_spawn_world_actors()
	player_actor.position = _spawn_for_location(str(state.player.location))
	_update_camera(0.0, true)
	_refresh_hud()
	if bool(result.get("quest_completed", false)):
		hint_label.text = str(result.message)
		call_deferred("_show_quest_claim")
	else:
		_show_message("港口传送", str(result.message))

func _open_vendor_shop_2d(npc_id):
	var vendor_id = str(npc_id)
	if not GameData.VENDOR_SHOPS.has(vendor_id):
		_show_message("商店尚未营业", "这位人物暂时没有可出售的商品。")
		return
	var shop = GameData.VENDOR_SHOPS[vendor_id]
	var content = VBoxContainer.new()
	content.add_theme_constant_override("separation", 11)
	content.add_child(_label(str(shop.name), 25, GOLD))
	var intro = _label("%s\n持有银币：%d" % [str(shop.description), int(state.player.silver)], 15, TEAL)
	intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(intro)
	if inventory_notice != "":
		content.add_child(_label(inventory_notice, 14, GOLD))
		inventory_notice = ""
	var scroll = ScrollContainer.new()
	scroll.custom_minimum_size.y = 440
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	content.add_child(scroll)
	var stock_list = VBoxContainer.new()
	stock_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stock_list.add_theme_constant_override("separation", 9)
	scroll.add_child(stock_list)
	for item_id in GameData.vendor_stock(vendor_id):
		var item = GameData.ITEMS[str(item_id)]
		var row = HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)
		row.add_child(_item_visual_2d(str(item.type), str(item_id), str(item.rarity), str(item.get("slot", "")), false, 72))
		var text_stack = VBoxContainer.new()
		text_stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(text_stack)
		text_stack.add_child(_label("%s · %s" % [str(item.name), str(item.rarity)], 15, INK))
		var description = _label(str(item.description), 12, MUTED)
		description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		text_stack.add_child(description)
		if str(item.type) == "equipment":
			text_stack.add_child(_label(_item_stats_text_2d(item.get("stats", {})), 12, TEAL))
		text_stack.add_child(_label("持有%d件" % int(state.inventory.get(str(item_id), 0)), 12, MUTED))
		var buy = _button("%d银\n购买" % int(item.price), "gold")
		buy.custom_minimum_size.x = 116
		buy.disabled = int(state.player.silver) < int(item.price)
		buy.pressed.connect(_buy_vendor_item_2d.bind(vendor_id, str(item_id)))
		row.add_child(buy)
		var card = PanelContainer.new()
		card.add_theme_stylebox_override("panel", _style(Color(0.04, 0.13, 0.16, 0.92), 10, _rarity_color_2d(str(item.rarity)), 2, 10))
		card.add_child(row)
		stock_list.add_child(card)
	if vendor_id == "jeweler":
		var unknown_count = int(state.inventory.get("unknown_equipment", 0))
		var identify = _button("鉴定未知道具 · 持有%d件 · 每件5银" % unknown_count, "primary")
		identify.disabled = unknown_count <= 0 or int(state.player.silver) < 5
		identify.pressed.connect(_identify_at_jeweler_2d)
		content.add_child(identify)
	elif _npc_service(vendor_id) in ["tavern_shop", "rest"]:
		var rest_button = _button("在酒馆免费休息 · 恢复全部体力与状态", "primary")
		rest_button.pressed.connect(_rest_at_vendor_2d.bind(vendor_id))
		content.add_child(rest_button)
	var close = _button("返回地图", "ghost")
	close.pressed.connect(_close_overlay)
	content.add_child(close)
	_open_overlay(content, true, Vector2(666, 870))

func _buy_vendor_item_2d(npc_id, item_id):
	var result = state.buy_vendor_item(npc_id, item_id)
	inventory_notice = ("✓ " if bool(result.ok) else "！") + str(result.message)
	_refresh_hud()
	_close_overlay()
	call_deferred("_open_vendor_shop_2d", npc_id)

func _identify_at_jeweler_2d():
	var result = state.identify_unknown()
	inventory_notice = ("✓ " if bool(result.ok) else "！") + str(result.message)
	_refresh_hud()
	_close_overlay()
	call_deferred("_open_vendor_shop_2d", "jeweler")

func _rest_at_vendor_2d(vendor_id = "tavern_keeper"):
	var result = state.rest()
	if bool(result.ok):
		AudioDirector.play_sfx("heal")
	_refresh_hud()
	_close_overlay()
	call_deferred("_open_vendor_shop_2d", str(vendor_id))

func _port_service_ready_2d():
	if not state.is_trade_unlocked():
		_show_message("港口尚未开放", "完成威尼斯四层试炼后，船老板会将贸易船海燕号交给你。")
		return false
	if not GameData.TRADE_PORTS.has(state.player.location):
		_show_message("这里不是港口", "港口业务必须在真实港口找对应人物办理。请通过区域地图步行前往威尼斯码头；远洋港口之间需要乘船航行。")
		return false
	return true

func _port_service_identity_2d(service, npc_id = ""):
	var resolved_id = str(npc_id)
	if resolved_id == "":
		resolved_id = GameData.port_service_npc(str(state.player.location), str(service))
	return GameData.NPCS.get(resolved_id, {"name": "港口职员", "role": GameData.NPC_SERVICE_LABELS.get(str(service), "港口服务")})

func _port_service_intro_2d(content, service, npc_id, description):
	var npc = _port_service_identity_2d(service, npc_id)
	var intro = _label("◆ %s｜%s\n%s" % [str(npc.name), str(npc.role), str(description)], 14, TEAL)
	intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	intro.add_theme_stylebox_override("normal", _style(Color(0.03, 0.17, 0.15, 0.92), 10, Color(TEAL, 0.5), 1, 10))
	content.add_child(intro)

func _consume_port_notice_2d(content):
	if inventory_notice == "":
		return
	var notice = _label(inventory_notice, 14, GOLD)
	notice.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(notice)
	inventory_notice = ""

func _port_service_scroll_2d(content, height = 560):
	var scroll = ScrollContainer.new()
	scroll.custom_minimum_size.y = height
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	content.add_child(scroll)
	var list = VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 9)
	scroll.add_child(list)
	return list

func _finish_port_service_overlay_2d(content):
	var close = _button("返回港口地图", "primary")
	close.pressed.connect(_close_overlay)
	content.add_child(close)
	_open_overlay(content, true, Vector2(666, 940))

func _open_trade_2d(npc_id = ""):
	if not _port_service_ready_2d():
		return
	var port_id = str(state.player.location)
	var port = GameData.TRADE_PORTS[port_id]
	var content = VBoxContainer.new()
	content.add_theme_constant_override("separation", 10)
	content.add_child(_label("%s · 本地货栈" % port.name, 25, GOLD))
	_port_service_intro_2d(content, "market", npc_id, "只办理本港特产买卖、外来货收购和商会订单；航线与船只改造请找其他 NPC。")
	content.add_child(_trade_dashboard_2d(port_id))
	_consume_port_notice_2d(content)
	var list = _port_service_scroll_2d(content)
	var market_event = GameData.trade_event(state.trade_day)
	list.add_child(_label("今日行情｜%s\n%s" % [market_event.name, market_event.description], 14, GOLD))
	var opportunity = state.best_trade_opportunity()
	if not opportunity.is_empty():
		list.add_child(_label("商路推荐｜%s → %s · %d日后满舱约赚%d银" % [GameData.TRADE_GOODS[str(opportunity.good_id)].name, GameData.TRADE_PORTS[str(opportunity.destination)].name, int(opportunity.days), int(opportunity.total_profit)], 13, TEAL))
	var local_stock = GameData.port_stock(port_id)
	list.add_child(_label("本港产地货栈 · 仅出售%s" % str(port.specialty), 16, GOLD))
	for good_id in local_stock:
		_add_trade_good_card_2d(list, str(good_id), true)
	var foreign_cargo = []
	for good_id in state.cargo:
		if int(state.cargo.get(good_id, 0)) > 0 and GameData.TRADE_GOODS.has(good_id) and str(good_id) not in local_stock:
			foreign_cargo.append(str(good_id))
	if not foreign_cargo.is_empty():
		list.add_child(_label("船上外来货 · 本港只收购、不出售", 16, TEAL))
		for good_id in foreign_cargo:
			_add_trade_good_card_2d(list, str(good_id), false)
	var orders = _button("打开商会订单柜台", "gold")
	var order_npc_id = GameData.port_service_npc(port_id, "trade_order")
	orders.pressed.connect(_open_port_orders_2d.bind(order_npc_id if order_npc_id != "" else GameData.port_service_npc(port_id, "market")))
	list.add_child(orders)
	_finish_port_service_overlay_2d(content)

func _open_port_harbor_2d(npc_id = ""):
	if not _port_service_ready_2d():
		return
	var port_id = str(state.player.location)
	var port = GameData.TRADE_PORTS[port_id]
	var content = VBoxContainer.new()
	content.add_theme_constant_override("separation", 10)
	content.add_child(_label("%s · 港务处" % port.name, 25, GOLD))
	_port_service_intro_2d(content, "harbor", npc_id, "只办理航线规划、出航和护航补给；货物买卖请找本港货栈。")
	_consume_port_notice_2d(content)
	var profile = state.ship_speed_profile()
	content.add_child(_label("当前船只｜%s · %.1f节 · %d海里/日｜货舱%d/%d｜船甲%d" % [str(state.ship.name), float(profile.knots), int(profile.nm_per_day), state.cargo_used(), state.cargo_capacity(), state.ship_armor()], 14, GOLD))
	var list = _port_service_scroll_2d(content)
	var chart = _button("打开九港航海大地图", "gold")
	chart.pressed.connect(_open_sailing_map)
	list.add_child(chart)
	var protection_text = "护航物资已装船｜下次风暴免损" if state.voyage_protection > 0 else "购买护航物资 45银｜降低风险并免除一次风暴损失"
	var protection = _button(protection_text, "primary" if state.voyage_protection <= 0 else "ghost")
	protection.disabled = state.voyage_protection > 0 or int(state.player.silver) < 45
	protection.pressed.connect(_buy_voyage_protection_2d)
	list.add_child(protection)
	list.add_child(_label("自由航线 · 选择任一已发现港口出航", 16, GOLD))
	for destination in GameData.TRADE_PORTS:
		if destination == port_id or not state.is_port_unlocked(str(destination)):
			continue
		var plan = state.voyage_plan(destination)
		var sail = _button("出航%s｜%d海里 · %d日 · 风险%d%% · 威胁%d处" % [GameData.TRADE_PORTS[destination].name, int(plan.distance_nm), int(plan.days), int(plan.risk), int(plan.threat_count)], "gold")
		sail.pressed.connect(_trade_sail_2d.bind(destination))
		list.add_child(sail)
	_finish_port_service_overlay_2d(content)

func _open_port_shipyard_2d(npc_id = ""):
	if not _port_service_ready_2d():
		return
	var port_id = str(state.player.location)
	var port = GameData.TRADE_PORTS[port_id]
	var offered_hull_id = str(port.get("ship_offer", "sea_swallow"))
	var offered_hull = Dictionary(GameData.SHIP_HULLS[offered_hull_id])
	var content = VBoxContainer.new()
	content.add_theme_constant_override("separation", 10)
	content.add_child(_label("%s · 船坞" % port.name, 25, GOLD))
	_port_service_intro_2d(content, "shipyard", npc_id, "出售本港独有船型；购入后永久收藏，可在任一船坞换乘并转装帆、舱、甲、炮。")
	_consume_port_notice_2d(content)
	var list = _port_service_scroll_2d(content, 500)
	list.add_child(_label("本港船型｜Lv.%d %s · %s\n基础%.1f节 · 货舱%d格 · 船甲%d · 舰炮%d\n%s" % [int(offered_hull.level), str(offered_hull.name), str(offered_hull.role), float(offered_hull.base_knots), int(offered_hull.capacity), int(offered_hull.armor), int(offered_hull.cannon), str(offered_hull.trait)], 15, TEAL))
	var offered_is_current = str(state.ship.get("hull_id", "sea_swallow")) == offered_hull_id
	var offered_is_owned = state.owns_ship(offered_hull_id)
	var offer_action = "当前船只" if offered_is_current else ("换乘%s · 已拥有" % str(offered_hull.name) if offered_is_owned else "购买%s · %d银币" % [str(offered_hull.name), int(offered_hull.price)])
	var buy_ship = _button(offer_action, "gold")
	buy_ship.disabled = offered_is_current or (not offered_is_owned and int(state.player.silver) < int(offered_hull.price)) or state.cargo_used() > int(offered_hull.capacity) + int(state.ship.get("hold_level", 0)) * 6
	buy_ship.pressed.connect(_buy_ship_2d.bind(offered_hull_id))
	list.add_child(buy_ship)
	var profile = state.ship_speed_profile()
	list.add_child(_label("当前｜%s · %s · %.1f节 · %d海里/日｜货舱%d格｜船甲%d｜舰炮%d\n帆装Lv.%d · 舱板Lv.%d · 装甲Lv.%d · 舰炮Lv.%d" % [str(state.ship.name), state.ship_role(), float(profile.knots), int(profile.nm_per_day), state.cargo_capacity(), state.ship_armor(), state.ship_cannon_power(), int(state.ship.speed), int(state.ship.get("hold_level", 0)), int(state.ship.get("armor", 0)), int(state.ship.get("cannon_level", 0))], 14, GOLD))
	for upgrade_entry in [{"id": "hold", "text": "强化舱板 +6格"}, {"id": "speed", "text": "强化帆装 +1.5节"}, {"id": "armor", "text": "强化装甲 -6%风险"}, {"id": "cannon", "text": "强化舰炮 +4海战攻击"}]:
		var upgrade = _button(upgrade_entry.text, "primary")
		upgrade.disabled = (upgrade_entry.id == "hold" and int(state.ship.get("hold_level", 0)) >= 3) or (upgrade_entry.id == "speed" and int(state.ship.speed) >= 4) or (upgrade_entry.id == "armor" and int(state.ship.get("armor", 0)) >= 3) or (upgrade_entry.id == "cannon" and int(state.ship.get("cannon_level", 0)) >= 3)
		upgrade.pressed.connect(_trade_upgrade_2d.bind(upgrade_entry.id))
		list.add_child(upgrade)
	if state.owned_ship_ids().size() > 1:
		list.add_child(_label("我的船队｜已拥有%d艘，换乘不再付费" % state.owned_ship_ids().size(), 16, GOLD))
		for owned_hull_id in state.owned_ship_ids():
			if str(owned_hull_id) == str(state.ship.get("hull_id", "sea_swallow")):
				continue
			var owned_hull = Dictionary(GameData.SHIP_HULLS[str(owned_hull_id)])
			var switch_button = _button("换乘｜%s · %s · %.1f节 · %d格" % [str(owned_hull.name), str(owned_hull.role), float(owned_hull.base_knots) + float(GameData.SHIP_SPEED_LEVELS[int(state.ship.speed)].knots_bonus), int(owned_hull.capacity) + int(state.ship.get("hold_level", 0)) * 6], "ghost")
			switch_button.disabled = state.cargo_used() > int(owned_hull.capacity) + int(state.ship.get("hold_level", 0)) * 6
			switch_button.pressed.connect(_switch_ship_2d.bind(str(owned_hull_id)))
			list.add_child(switch_button)
	_finish_port_service_overlay_2d(content)

func _open_port_orders_2d(npc_id = ""):
	if not _port_service_ready_2d():
		return
	var port_id = str(state.player.location)
	var port = GameData.TRADE_PORTS[port_id]
	var content = VBoxContainer.new()
	content.add_theme_constant_override("separation", 10)
	content.add_child(_label("%s · 商会订单" % port.name, 25, GOLD))
	_port_service_intro_2d(content, "trade_order", npc_id, "这里只验收订单与发放贸易奖励；采购货物请回本地货栈。")
	_consume_port_notice_2d(content)
	var list = _port_service_scroll_2d(content, 460)
	var order = state.current_trade_order(port_id)
	if order.is_empty():
		list.add_child(_label("当前没有待交付订单。", 14, MUTED))
	else:
		var good = GameData.TRADE_GOODS[str(order.good)]
		var held = int(state.cargo.get(str(order.good), 0))
		list.add_child(_label("%s%s\n%s\n交付%s×%d｜货舱%d/%d｜奖金%d银｜声望+%d" % [str(order.title), " · 主线" if bool(order.get("story", false)) else "", str(order.description), str(good.name), int(order.amount), held, int(order.amount), int(order.bonus), int(order.reputation)], 14, INK))
		var claim = _button("向%s商会交付" % port.name, "gold")
		claim.disabled = not state.trade_order_can_claim(port_id)
		claim.pressed.connect(_claim_trade_order_2d)
		list.add_child(claim)
	var target = state.trade_contract_target()
	list.add_child(_label("商会循环委托·第%d轮｜贸易净利润 %d/%d" % [state.trade_contract_count + 1, state.trade_contract_progress(), target], 14, TEAL))
	var contract = _button("领取商会奖励", "gold")
	contract.disabled = not state.trade_contract_can_claim()
	contract.pressed.connect(_claim_trade_contract_2d)
	list.add_child(contract)
	_finish_port_service_overlay_2d(content)

func _open_port_kitchen_2d(npc_id = ""):
	if not _port_service_ready_2d():
		return
	var port_id = str(state.player.location)
	var port = GameData.TRADE_PORTS[port_id]
	var content = VBoxContainer.new()
	content.add_theme_constant_override("separation", 10)
	content.add_child(_label("%s · 港口厨房" % port.name, 25, GOLD))
	_port_service_intro_2d(content, "cook", npc_id, "只把货舱里的产地食材烹制为可在背包使用的远航补给。")
	_consume_port_notice_2d(content)
	var list = _port_service_scroll_2d(content, 500)
	var recipes = state.available_recipes(port_id)
	if recipes.is_empty():
		list.add_child(_label("本港暂时没有可烹制的远航餐。", 14, MUTED))
	for recipe in recipes:
		var ingredients = []
		var can_cook = int(state.player.silver) >= int(recipe.silver)
		for good_id in recipe.cargo:
			var need = int(recipe.cargo[good_id])
			var held = int(state.cargo.get(good_id, 0))
			var source = str(GameData.TRADE_GOODS[good_id].origin)
			ingredients.append("%s %d/%d（%s）" % [GameData.TRADE_GOODS[good_id].name, held, need, GameData.TRADE_PORTS[source].name])
			can_cook = can_cook and held >= need
		list.add_child(_label("%s\n%s\n材料：%s｜厨房费%d银" % [str(recipe.name), str(recipe.description), "、".join(ingredients), int(recipe.silver)], 14, INK))
		var cook = _button("烹制%s" % str(recipe.name), "gold")
		cook.disabled = not can_cook
		cook.pressed.connect(_cook_recipe_2d.bind(str(recipe.id)))
		list.add_child(cook)
	_finish_port_service_overlay_2d(content)

func _open_trade_all_in_one_legacy_2d():
	if not state.is_trade_unlocked():
		_show_message("港口尚未开放", "完成威尼斯四层试炼后，船老板会将贸易船海燕号交给你。")
		return
	if not GameData.TRADE_PORTS.has(state.player.location):
		_show_message("这里不是港口", "贸易必须在真实港口进行。请关闭面板，通过区域地图或任务导航步行前往威尼斯码头；远洋港口之间则需要乘船航行。")
		return
	var port_id = str(state.player.location)
	var port = GameData.TRADE_PORTS[port_id]
	var market_event = GameData.trade_event(state.trade_day)
	var content = VBoxContainer.new()
	content.add_theme_constant_override("separation", 10)
	content.add_child(_label("%s港口市场" % port.name, 25, GOLD))
	content.add_child(_trade_dashboard_2d(port_id))
	if inventory_notice != "":
		var trade_notice = _label(inventory_notice, 14, GOLD)
		trade_notice.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		trade_notice.add_theme_stylebox_override("normal", _style(Color(0.18, 0.13, 0.03, 0.94), 10, Color(GOLD, 0.55), 1, 8))
		content.add_child(trade_notice)
		inventory_notice = ""
	var scroll = ScrollContainer.new()
	scroll.custom_minimum_size.y = 560
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	content.add_child(scroll)
	var list = VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 8)
	scroll.add_child(list)
	var chart = _button("打开九港航海图 · 规划下一段航程", "gold")
	chart.pressed.connect(_open_sailing_map)
	list.add_child(chart)
	var merchant_id = str(port.get("merchant_npc", ""))
	var merchant = GameData.NPCS.get(merchant_id, {"name": "港口商人", "role": "货栈经营者"})
	var merchant_copy = _label("交易商人｜%s · %s\n本港特产｜%s\n%s" % [merchant.name, merchant.role, port.specialty, port.note], 14, TEAL)
	merchant_copy.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	merchant_copy.add_theme_stylebox_override("normal", _style(Color(0.03, 0.17, 0.15, 0.92), 10, Color(TEAL, 0.5), 1, 10))
	list.add_child(merchant_copy)
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
	var order = state.current_trade_order(port_id)
	if not order.is_empty():
		var order_good = GameData.TRADE_GOODS[str(order.good)]
		var held_for_order = int(state.cargo.get(str(order.good), 0))
		var order_card = VBoxContainer.new()
		order_card.add_theme_constant_override("separation", 6)
		order_card.add_child(_label("%s商会订单｜%s%s" % [port.name, str(order.title), " · 主线" if bool(order.get("story", false)) else ""], 16, GOLD))
		var shortage = max(0, int(order.amount) - held_for_order)
		var order_origin = str(order_good.get("origin", ""))
		var order_source = str(GameData.TRADE_PORTS.get(order_origin, {"name": "其他港口"}).name)
		var shortage_text = "货物齐备，可以交付。" if shortage == 0 else ("货物不足：还缺%s×%d；本港货栈有售。" % [str(order_good.name), shortage] if GameData.port_sells_good(port_id, str(order.good)) else "货物不足：还缺%s×%d；请前往%s采购后运回。" % [str(order_good.name), shortage, order_source])
		var order_copy = _label("%s\n交付%s×%d｜货舱%d/%d｜额外奖金%d｜声望+%d\n%s" % [str(order.description), str(order_good.name), int(order.amount), held_for_order, int(order.amount), int(order.bonus), int(order.reputation), shortage_text], 13, INK)
		order_copy.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		order_card.add_child(order_copy)
		var order_claim = _button("向%s商会交付" % port.name, "gold")
		order_claim.disabled = not state.trade_order_can_claim(port_id)
		order_claim.pressed.connect(_claim_trade_order_2d)
		order_card.add_child(order_claim)
		var order_panel = PanelContainer.new()
		order_panel.add_theme_stylebox_override("panel", _style(Color(0.18, 0.13, 0.03, 0.9), 11, Color(GOLD, 0.5), 1, 11))
		order_panel.add_child(order_card)
		list.add_child(order_panel)
	for recipe in state.available_recipes(port_id):
		var ingredients = []
		var can_cook = int(state.player.silver) >= int(recipe.silver)
		for good_id in recipe.cargo:
			var need = int(recipe.cargo[good_id])
			var held = int(state.cargo.get(good_id, 0))
			var source_port = str(GameData.TRADE_GOODS[good_id].origin)
			ingredients.append("%s %d/%d（%s）" % [GameData.TRADE_GOODS[good_id].name, held, need, GameData.TRADE_PORTS[source_port].name])
			can_cook = can_cook and held >= need
		var recipe_card = VBoxContainer.new()
		recipe_card.add_theme_constant_override("separation", 6)
		recipe_card.add_child(_label("港口厨房｜%s" % recipe.name, 16, GOLD))
		var recipe_copy = _label("%s\n材料：%s｜厨房费%d银币" % [recipe.description, "、".join(ingredients), int(recipe.silver)], 13, INK)
		recipe_copy.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		recipe_card.add_child(recipe_copy)
		var cook_button = _button("烹制远航餐食", "gold")
		cook_button.disabled = not can_cook
		cook_button.pressed.connect(_cook_recipe_2d.bind(str(recipe.id)))
		recipe_card.add_child(cook_button)
		var recipe_panel = PanelContainer.new()
		recipe_panel.add_theme_stylebox_override("panel", _style(Color(0.12, 0.14, 0.06, 0.92), 11, Color(GOLD, 0.5), 1, 11))
		recipe_panel.add_child(recipe_card)
		list.add_child(recipe_panel)
	var protection_text = "护航物资已装船｜下次航行风险-8，并免除一次风暴损失" if state.voyage_protection > 0 else "购买护航物资 45银｜下次航行风险-8，并免除一次风暴损失"
	var protection = _button(protection_text, "primary" if state.voyage_protection <= 0 else "ghost")
	protection.disabled = state.voyage_protection > 0 or int(state.player.silver) < 45
	protection.pressed.connect(_buy_voyage_protection_2d)
	list.add_child(protection)
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
	var local_stock = GameData.port_stock(port_id)
	list.add_child(_label("本港产地货栈 · 每种货物只在原产港出售", 16, GOLD))
	for good_id in local_stock:
		_add_trade_good_card_2d(list, str(good_id), true)
	var foreign_cargo = []
	for good_id in state.cargo:
		if int(state.cargo.get(good_id, 0)) > 0 and GameData.TRADE_GOODS.has(good_id) and str(good_id) not in local_stock:
			foreign_cargo.append(str(good_id))
	if not foreign_cargo.is_empty():
		list.add_child(_label("船上外来货 · 本港收购", 16, TEAL))
		for good_id in foreign_cargo:
			_add_trade_good_card_2d(list, str(good_id), false)
	list.add_child(_label("自由航线 · 已发现港口均可直航", 16, GOLD))
	for destination in GameData.TRADE_PORTS:
		if destination == port_id:
			continue
		if not state.is_port_unlocked(str(destination)):
			continue
		var route = GameData.trade_route(port_id, destination)
		if route.is_empty():
			continue
		var plan = state.voyage_plan(destination)
		var sail = _button("选择%s｜%s · %d海里 · %d日 · 威胁%d处" % [GameData.TRADE_PORTS[destination].name, str(plan.tier_name), int(plan.distance_nm), int(plan.days), int(plan.threat_count)], "gold")
		sail.disabled = false
		sail.pressed.connect(_trade_sail_2d.bind(destination))
		list.add_child(sail)
	list.add_child(_label("船只改造", 16, GOLD))
	var offered_hull_id = str(port.get("ship_offer", "sea_swallow"))
	var offered_hull = Dictionary(GameData.SHIP_HULLS[offered_hull_id])
	var ship_offer_copy = _label("本港船老板｜%s\n出售 Lv.%d %s｜基础%.1f节 · 货舱%d格 · 船甲%d\n%s" % [str(port.get("ship_seller", "船老板")), int(offered_hull.level), str(offered_hull.name), float(offered_hull.base_knots), int(offered_hull.capacity), int(offered_hull.armor), str(offered_hull.trait)], 14, TEAL)
	ship_offer_copy.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	list.add_child(ship_offer_copy)
	var buy_ship_button = _button("当前船只" if str(state.ship.get("hull_id", "sea_swallow")) == offered_hull_id else "购买%s · %d银币" % [str(offered_hull.name), int(offered_hull.price)], "gold")
	buy_ship_button.disabled = str(state.ship.get("hull_id", "sea_swallow")) == offered_hull_id or int(state.player.silver) < int(offered_hull.price) or state.cargo_used() > int(offered_hull.capacity) + int(state.ship.get("hold_level", 0)) * 6
	buy_ship_button.pressed.connect(_buy_ship_2d.bind(offered_hull_id))
	list.add_child(buy_ship_button)
	var profile = state.ship_speed_profile()
	list.add_child(_label("当前｜%s · %.1f节 · %d海里/日｜货舱%d格｜船甲%d\n船装可跨船型转装：帆装Lv.%d · 舱板Lv.%d · 装甲Lv.%d" % [str(state.ship.name), float(profile.knots), int(profile.nm_per_day), state.cargo_capacity(), state.ship_armor(), int(state.ship.speed), int(state.ship.get("hold_level", 0)), int(state.ship.get("armor", 0))], 13, GOLD))
	for upgrade_entry in [
		{"id": "hold", "text": "强化舱板 +6格"},
		{"id": "speed", "text": "强化帆装 +1.5节"},
		{"id": "armor", "text": "强化装甲 -6%风险"}
	]:
		var upgrade_button = _button(upgrade_entry.text, "ghost")
		upgrade_button.disabled = (upgrade_entry.id == "hold" and int(state.ship.get("hold_level", 0)) >= 3) or (upgrade_entry.id == "speed" and int(state.ship.speed) >= 4) or (upgrade_entry.id == "armor" and int(state.ship.get("armor", 0)) >= 3)
		upgrade_button.pressed.connect(_trade_upgrade_2d.bind(upgrade_entry.id))
		list.add_child(upgrade_button)
	list.add_child(_label("本轮商会净收支：%+d｜生涯已实现货差：%+d｜累计成交%d件" % [state.trade_profit, state.trade_lifetime_profit, state.trade_volume], 13, MUTED))
	var close = _button("返回港口地图", "primary")
	close.pressed.connect(_close_overlay)
	content.add_child(close)
	_open_overlay(content, true, Vector2(666, 980))

func _add_trade_good_card_2d(list, good_id, can_buy):
	var good = GameData.TRADE_GOODS[good_id]
	var stack = VBoxContainer.new()
	stack.add_theme_constant_override("separation", 7)
	var held = int(state.cargo.get(good_id, 0))
	var average = state.cargo_average_cost(good_id)
	var estimate = state.trade_sell_price(good_id) - average if held > 0 else 0
	var origin_id = str(good.get("origin", ""))
	var origin_name = str(GameData.TRADE_PORTS.get(origin_id, {"name": "未知港口"}).name)
	var stock_tag = "本港出产" if can_buy else "外来货"
	var buy_price = state.trade_buy_price(good_id)
	var sell_price = state.trade_sell_price(good_id)
	var market_trend = _trade_trend_2d(str(state.player.location), good_id)
	var card_header = HBoxContainer.new()
	card_header.add_theme_constant_override("separation", 10)
	card_header.add_child(_item_visual_2d("trade", good_id, "传说" if can_buy else "优秀", "", false, 78))
	var details = VBoxContainer.new()
	details.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	details.add_theme_constant_override("separation", 3)
	details.add_child(_label("%s · %s" % [good.name, stock_tag], 16, INK))
	details.add_child(_label("产地：%s｜每%s占%d格" % [origin_name, good.unit, int(good.space)], 12, MUTED))
	details.add_child(_label("行情%s｜较昨日%+d银" % [str(market_trend.name), int(market_trend.delta)], 12, Color(market_trend.color)))
	if can_buy:
		var recommendation = _best_trade_destination_2d(good_id)
		if not recommendation.is_empty():
			details.add_child(_label("推荐销往%s · 约%d日 · 单件预估%+d" % [GameData.TRADE_PORTS[str(recommendation.port)].name, int(recommendation.days), int(recommendation.profit)], 12, TEAL if int(recommendation.profit) > 0 else MUTED))
	else:
		details.add_child(_label("持仓均价%d｜现在卖出单件%+d" % [average, estimate], 12, GOLD if estimate > 0 else RED if estimate < 0 else MUTED))
	card_header.add_child(details)
	var price_badge = Label.new()
	price_badge.text = ("买入\n%d银" % buy_price) if can_buy else ("收购\n%d银" % sell_price)
	price_badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	price_badge.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	price_badge.custom_minimum_size = Vector2(88, 72)
	price_badge.add_theme_font_size_override("font_size", 14)
	price_badge.add_theme_color_override("font_color", GOLD)
	price_badge.add_theme_stylebox_override("normal", _style(Color(0.18, 0.13, 0.03, 0.96), 11, Color(GOLD, 0.58), 1, 7))
	card_header.add_child(price_badge)
	stack.add_child(card_header)
	var capacity_copy = "｜最多还能买%d%s" % [state.max_buyable_cargo(good_id), good.unit] if can_buy else ""
	stack.add_child(_label("货舱持有：%d%s｜占用%d格%s" % [held, good.unit, held * int(good.space), capacity_copy], 13, TEAL))
	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 7)
	stack.add_child(row)
	if can_buy:
		var buy = _button("买1", "primary")
		buy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		buy.disabled = state.max_buyable_cargo(good_id) <= 0
		buy.pressed.connect(_trade_buy_2d.bind(good_id))
		row.add_child(buy)
		var buy_max = _button("买满", "gold")
		buy_max.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		buy_max.disabled = state.max_buyable_cargo(good_id) <= 0
		buy_max.pressed.connect(_trade_buy_2d.bind(good_id, true))
		row.add_child(buy_max)
	var sell = _button("卖1", "ghost")
	sell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sell.disabled = held <= 0
	sell.pressed.connect(_trade_sell_2d.bind(good_id))
	row.add_child(sell)
	var sell_all = _button("全卖", "ghost")
	sell_all.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sell_all.disabled = held <= 0
	sell_all.pressed.connect(_trade_sell_2d.bind(good_id, true))
	row.add_child(sell_all)
	var card = PanelContainer.new()
	var card_border = GOLD if can_buy else (TEAL if estimate >= 0 else RED)
	card.add_theme_stylebox_override("panel", _style(Color(0.04, 0.13, 0.16, 0.94), 12, Color(card_border, 0.62), 2, 10))
	card.add_child(stack)
	list.add_child(card)

func _trade_dashboard_2d(port_id):
	var panel = PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _style(Color(0.025, 0.105, 0.12, 0.96), 13, Color(TEAL, 0.48), 1, 11))
	var stack = VBoxContainer.new()
	stack.add_theme_constant_override("separation", 7)
	panel.add_child(stack)
	var top = HBoxContainer.new()
	top.add_theme_constant_override("separation", 8)
	stack.add_child(top)
	var wallet = _label("◈ %d 银币\n第%d日行情" % [int(state.player.silver), int(state.trade_day)], 16, GOLD)
	wallet.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(wallet)
	var value = _label("货值 %d\n浮动盈亏 %+d" % [state.cargo_market_value(), state.cargo_unrealized_profit()], 15, TEAL if state.cargo_unrealized_profit() >= 0 else RED)
	value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	value.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(value)
	var cargo_bar = ProgressBar.new()
	cargo_bar.name = "CargoCapacityBar"
	cargo_bar.max_value = max(1, state.cargo_capacity())
	cargo_bar.value = state.cargo_used()
	cargo_bar.show_percentage = false
	cargo_bar.custom_minimum_size.y = 20
	cargo_bar.add_theme_stylebox_override("background", _style(Color(0.02, 0.06, 0.075, 0.95), 9, Color(TEAL, 0.30), 1, 2))
	cargo_bar.add_theme_stylebox_override("fill", _style(Color(TEAL, 0.78), 9))
	stack.add_child(cargo_bar)
	stack.add_child(_label("货舱装载 %d/%d格  ·  空余%d格｜本港声望%d · 总声望%d" % [state.cargo_used(), state.cargo_capacity(), max(0, state.cargo_capacity() - state.cargo_used()), state.port_reputation_value(port_id), state.total_trade_reputation()], 13, MUTED))
	var ship_profile = state.ship_speed_profile()
	stack.add_child(_label("船只｜%s · %.1f节 · 日航%d海里｜船甲%d" % [str(state.ship.name), float(ship_profile.knots), int(ship_profile.nm_per_day), state.ship_armor()], 13, TEAL))
	return panel

func _trade_trend_2d(port_id, good_id):
	var today = GameData.trade_market_price(str(port_id), str(good_id), int(state.trade_day))
	var yesterday = GameData.trade_market_price(str(port_id), str(good_id), max(1, int(state.trade_day) - 1))
	var delta = today - yesterday
	if delta > 0:
		return {"name": "上涨 ↑", "delta": delta, "color": GOLD}
	if delta < 0:
		return {"name": "回落 ↓", "delta": delta, "color": Color("6dd3b4")}
	return {"name": "平稳 →", "delta": 0, "color": MUTED}

func _best_trade_destination_2d(good_id):
	var best = {}
	var buy_price = state.trade_buy_price(good_id)
	for destination in GameData.TRADE_PORTS:
		var destination_id = str(destination)
		if destination_id == str(state.player.location) or not state.is_port_unlocked(destination_id):
			continue
		var route = GameData.trade_route(str(state.player.location), destination_id)
		if route.is_empty():
			continue
		var days = state.voyage_days_for_distance(int(route.get("distance_nm", 1)))
		var destination_sell_price = state.trade_sell_price_at(destination_id, good_id, int(state.trade_day) + days)
		var profit = destination_sell_price - buy_price
		if best.is_empty() or profit > int(best.profit):
			best = {"port": destination_id, "days": days, "profit": profit}
	return best

func _trade_buy_2d(good_id, buy_max = false):
	var result = state.buy_max_cargo(good_id) if buy_max else state.buy_cargo(good_id)
	inventory_notice = ("✓ " if bool(result.get("ok", false)) else "！") + str(result.get("message", "交易失败"))
	_refresh_hud()
	_close_overlay()
	if bool(result.get("quest_completed", false)):
		call_deferred("_show_quest_claim")
	else:
		call_deferred("_open_trade_2d")

func _cook_recipe_2d(recipe_id):
	var result = state.cook_provision(recipe_id)
	_refresh_hud()
	_close_overlay()
	if bool(result.get("quest_completed", false)):
		AudioDirector.play_sfx("reward")
		call_deferred("_show_quest_claim")
	elif bool(result.get("ok", false)):
		inventory_notice = "✓ " + str(result.message)
		call_deferred("_open_port_kitchen_2d")
	else:
		_show_message("无法烹制", str(result.get("message", "材料不足")))

func _trade_sell_2d(good_id, sell_all = false):
	var result = state.sell_all_cargo(good_id) if sell_all else state.sell_cargo(good_id)
	inventory_notice = ("✓ " if bool(result.get("ok", false)) else "！") + str(result.get("message", "交易失败"))
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
		call_deferred("_open_port_shipyard_2d")
	else:
		_show_message("改造失败", str(result.get("message", "无法改造船只")))

func _buy_ship_2d(hull_id):
	var result = state.buy_ship(str(hull_id))
	inventory_notice = ("✓ " if bool(result.get("ok", false)) else "！") + str(result.get("message", "无法购买船只"))
	_refresh_hud()
	_close_overlay()
	if bool(result.get("ok", false)):
		call_deferred("_open_port_shipyard_2d")
	else:
		_show_message("购船失败", str(result.get("message", "无法购买船只")))

func _switch_ship_2d(hull_id):
	var result = state.switch_ship(str(hull_id))
	inventory_notice = ("✓ " if bool(result.get("ok", false)) else "！") + str(result.get("message", "无法换乘船只"))
	_refresh_hud()
	_close_overlay()
	if bool(result.get("ok", false)):
		call_deferred("_open_port_shipyard_2d")
	else:
		_show_message("换乘失败", str(result.get("message", "无法换乘船只")))

func _claim_trade_contract_2d():
	var result = state.claim_trade_contract()
	if bool(result.get("ok", false)):
		AudioDirector.play_sfx("reward")
	_refresh_hud()
	_close_overlay()
	inventory_notice = ("✓ " if bool(result.get("ok", false)) else "！") + str(result.get("message", "领取失败"))
	call_deferred("_open_port_orders_2d")

func _claim_trade_order_2d():
	var result = state.claim_trade_order()
	if bool(result.get("ok", false)):
		AudioDirector.play_sfx("reward")
	_refresh_hud()
	_close_overlay()
	if bool(result.get("quest_completed", false)):
		call_deferred("_show_quest_claim")
	else:
		inventory_notice = ("✓ " if bool(result.get("ok", false)) else "！") + str(result.message)
		call_deferred("_open_port_orders_2d")

func _buy_voyage_protection_2d():
	var result = state.buy_voyage_protection()
	_refresh_hud()
	_close_overlay()
	if bool(result.get("quest_completed", false)):
		call_deferred("_show_quest_claim")
	else:
		inventory_notice = ("✓ " if bool(result.get("ok", false)) else "！") + str(result.message)
		call_deferred("_open_port_harbor_2d")

func _trade_sail_2d(destination):
	_close_overlay()
	call_deferred("_open_sailing_map", destination)

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
	box.size_flags_vertical = Control.SIZE_EXPAND_FILL
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
	overlay_scroll = ScrollContainer.new()
	overlay_scroll.name = "OverlayScroll"
	overlay_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	overlay_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	overlay_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	overlay_scroll.mouse_filter = Control.MOUSE_FILTER_PASS
	box.add_child(overlay_scroll)
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	overlay_scroll.add_child(content)
	_reset_overlay_drag()

func _input(event):
	if not is_instance_valid(overlay):
		_reset_overlay_drag()
		return
	var target = _overlay_scroll_target()
	if not is_instance_valid(target):
		return
	if event is InputEventMouseButton:
		if event.pressed and event.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN]:
			var wheel_direction = -1 if event.button_index == MOUSE_BUTTON_WHEEL_UP else 1
			target.scroll_vertical += wheel_direction * max(36, int(round(58.0 * event.factor)))
			get_viewport().set_input_as_handled()
		elif event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				overlay_drag_pointer = -1
				overlay_drag_distance = 0.0
				overlay_dragging = false
			else:
				if overlay_drag_pointer == -1 and overlay_dragging:
					get_viewport().set_input_as_handled()
				_reset_overlay_drag()
	elif event is InputEventMouseMotion and overlay_drag_pointer == -1 and (event.button_mask & MOUSE_BUTTON_MASK_LEFT) != 0:
		_scroll_overlay_drag(target, event.relative)
	elif event is InputEventScreenTouch:
		if event.pressed:
			overlay_drag_pointer = int(event.index)
			overlay_drag_distance = 0.0
			overlay_dragging = false
		elif overlay_drag_pointer == int(event.index):
			if overlay_dragging:
				get_viewport().set_input_as_handled()
			_reset_overlay_drag()
	elif event is InputEventScreenDrag and overlay_drag_pointer == int(event.index):
		_scroll_overlay_drag(target, event.relative)

func _scroll_overlay_drag(target, relative):
	overlay_drag_distance += abs(float(relative.y))
	if overlay_drag_distance >= OVERLAY_DRAG_THRESHOLD:
		overlay_dragging = true
		target.scroll_vertical -= int(round(float(relative.y)))
		get_viewport().set_input_as_handled()

func _overlay_scroll_target():
	if not is_instance_valid(overlay):
		return null
	for node in overlay.find_children("*", "ScrollContainer", true, false):
		if node == overlay_scroll or not node.visible:
			continue
		var bar = node.get_v_scroll_bar()
		if is_instance_valid(bar) and bar.max_value > bar.page + 1.0:
			return node
	return overlay_scroll if is_instance_valid(overlay_scroll) else null

func _reset_overlay_drag():
	overlay_drag_pointer = -99
	overlay_drag_distance = 0.0
	overlay_dragging = false

func _close_overlay():
	auto_battle_running = false
	if is_instance_valid(overlay):
		overlay.queue_free()
	overlay = null
	overlay_scroll = null
	_reset_overlay_drag()
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
	sailing_map = null
	sailing_destination = ""
	sailing_route_label = null
	sailing_confirm_button = null
	sailing_transfer_button = null

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
