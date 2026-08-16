extends Node2D

const CHARACTER_ATLAS = preload("res://assets/art/characters/character_atlas_v1.png")
const NPC_ATLAS_A = preload("res://assets/art/characters/npc_profession_atlas_a_v2.png")
const NPC_ATLAS_B = preload("res://assets/art/characters/npc_profession_atlas_b_v2.png")
const NPC_ATLAS_C = preload("res://assets/art/characters/npc_profession_atlas_c_v2.png")
const NPC_ATLAS_D = preload("res://assets/art/characters/npc_profession_atlas_d_v2.png")
const NPC_ATLAS_E = preload("res://assets/art/characters/npc_profession_atlas_e_v2.png")
const PLAYER_SHIP_ATLAS = preload("res://assets/art/ships/player_ship_atlas_v1.png")
const ENEMY_ATLAS = preload("res://assets/art/characters/enemy_atlas_v2.png")
const LEGACY_BOSS_ATLAS_A = preload("res://assets/art/characters/legacy_boss_atlas_a_v1.png")
const LEGACY_BOSS_ATLAS_B = preload("res://assets/art/characters/legacy_boss_atlas_b_v1.png")
const PLAYER_WALK = preload("res://assets/art/characters/player_walk_v1.png")
const PLAYER_WALK_BACK = preload("res://assets/art/characters/player_walk_back_v1.png")
const ATLAS_CELL_SIZE = Vector2(362, 362)
const ENEMY_ATLAS_CELL_SIZE = Vector2(384, 256)
const LEGACY_BOSS_ATLAS_CELL_SIZE = Vector2(384, 384)
const ATLAS_CELLS = {
	"player": Vector2i(0, 0),
	"alisa": Vector2i(1, 0),
	"tavern_keeper": Vector2i(2, 0),
	"ship_owner": Vector2i(3, 0),
	"drunk_sailor": Vector2i(0, 1),
	"mine_thief": Vector2i(1, 1),
	"dungeon_guard": Vector2i(2, 1),
	"guard_captain": Vector2i(2, 1),
	"giant_bear": Vector2i(3, 1),
	"sewer_rat": Vector2i(0, 2),
	"wildwood_ghost": Vector2i(1, 2),
	"stone_puppet": Vector2i(2, 2),
	"vermilion_phantom": Vector2i(3, 2),
	"ragusa_broker": Vector2i(3, 0),
	"alexandria_merchant": Vector2i(2, 0)
}
const ENEMY_ATLAS_CELLS = {
	"tide_beast": Vector2i(0, 0),
	"corsair_deckhand": Vector2i(1, 0),
	"corsair_raider": Vector2i(2, 0),
	"corsair_guard": Vector2i(3, 0),
	"corsair_captain": Vector2i(0, 1),
	"coastal_pirate": Vector2i(1, 1),
	"reef_serpent": Vector2i(2, 1),
	"ocean_raider": Vector2i(3, 1),
	"abyss_kraken": Vector2i(0, 2),
	"black_flag_privateer": Vector2i(1, 2),
	"wreck_crab": Vector2i(2, 2),
	"drowned_sailor": Vector2i(3, 2),
	"fog_siren": Vector2i(0, 3),
	"abyss_siren": Vector2i(1, 3)
}
const LEGACY_BOSS_ATLAS_A_CELLS = {
	"basin_leviathan": Vector2i(0, 0),
	"nine_tail_fox": Vector2i(1, 0),
	"earth_demon_king": Vector2i(2, 0),
	"tira_guardian": Vector2i(0, 1),
	"celestial_demon_general": Vector2i(1, 1)
}
const LEGACY_BOSS_ATLAS_B_CELLS = {
	"jade_dream_queen": Vector2i(0, 0),
	"black_furnace_lord": Vector2i(1, 0),
	"returned_demon_king": Vector2i(2, 0),
	"clockwork_tailor": Vector2i(0, 1),
	"tide_void_emperor": Vector2i(1, 1)
}
const NPC_ATLAS_CELLS = {
	"alisa": {"atlas": "a", "cell": Vector2i(0, 0)},
	"tavern_keeper": {"atlas": "a", "cell": Vector2i(1, 0)},
	"guard_captain": {"atlas": "a", "cell": Vector2i(2, 0)},
	"jeweler": {"atlas": "a", "cell": Vector2i(3, 0)},
	"ship_owner": {"atlas": "a", "cell": Vector2i(0, 1)},
	"venice_quartermaster": {"atlas": "a", "cell": Vector2i(1, 1)},
	"venice_shipwright": {"atlas": "a", "cell": Vector2i(2, 1)},
	"ragusa_broker": {"atlas": "a", "cell": Vector2i(3, 1)},
	"ragusa_harbormaster": {"atlas": "b", "cell": Vector2i(0, 0)},
	"ragusa_shipwright": {"atlas": "b", "cell": Vector2i(1, 0)},
	"ragusa_innkeeper": {"atlas": "b", "cell": Vector2i(2, 0)},
	"alexandria_merchant": {"atlas": "b", "cell": Vector2i(3, 0)},
	"alex_harbormaster": {"atlas": "b", "cell": Vector2i(0, 1)},
	"alex_lighthouse_keeper": {"atlas": "b", "cell": Vector2i(1, 1)},
	"alex_shipwright": {"atlas": "b", "cell": Vector2i(2, 1)},
	"malta_keeper": {"atlas": "b", "cell": Vector2i(3, 1)},
	"malta_harbormaster": {"atlas": "c", "cell": Vector2i(0, 0)},
	"malta_shipwright": {"atlas": "c", "cell": Vector2i(1, 0)},
	"malta_cook": {"atlas": "c", "cell": Vector2i(2, 0)},
	"malta_diver": {"atlas": "c", "cell": Vector2i(3, 0)},
	"cape_keeper": {"atlas": "c", "cell": Vector2i(0, 1)},
	"cape_shipwright": {"atlas": "c", "cell": Vector2i(1, 1)},
	"cape_quartermaster": {"atlas": "c", "cell": Vector2i(2, 1)},
	"quanzhou_scholar": {"atlas": "c", "cell": Vector2i(3, 1)},
	"quanzhou_navigator": {"atlas": "d", "cell": Vector2i(0, 0)},
	"quanzhou_merchant": {"atlas": "d", "cell": Vector2i(1, 0)},
	"quanzhou_shipwright": {"atlas": "d", "cell": Vector2i(2, 0)},
	"athens_oracle": {"atlas": "d", "cell": Vector2i(3, 0)},
	"athens_harbormaster": {"atlas": "d", "cell": Vector2i(0, 1)},
	"athens_smith": {"atlas": "d", "cell": Vector2i(1, 1)},
	"athens_innkeeper": {"atlas": "d", "cell": Vector2i(2, 1)},
	"yangzhou_weaver": {"atlas": "d", "cell": Vector2i(3, 1)},
	"yangzhou_pilot": {"atlas": "e", "cell": Vector2i(0, 0)},
	"yangzhou_merchant": {"atlas": "e", "cell": Vector2i(1, 0)},
	"yangzhou_shipwright": {"atlas": "e", "cell": Vector2i(2, 0)},
	"amsterdam_cartographer": {"atlas": "e", "cell": Vector2i(0, 1)},
	"amsterdam_auctioneer": {"atlas": "e", "cell": Vector2i(1, 1)},
	"amsterdam_shipwright": {"atlas": "e", "cell": Vector2i(2, 1)}
}
const PLAYER_SHIP_CELLS = {
	"sea_swallow": Vector2i(0, 0), "adriatic_cog": Vector2i(1, 0), "alex_caravel": Vector2i(2, 0),
	"malta_galley": Vector2i(0, 1), "cape_carrack": Vector2i(1, 1), "quanzhou_junk": Vector2i(2, 1),
	"athens_trireme": Vector2i(0, 2), "yangzhou_treasure": Vector2i(1, 2), "amsterdam_clipper": Vector2i(2, 2)
}
const LEGACY_BOSS_IDS = [
	"basin_leviathan", "nine_tail_fox", "earth_demon_king", "tira_guardian",
	"celestial_demon_general", "jade_dream_queen", "black_furnace_lord",
	"returned_demon_king", "clockwork_tailor", "tide_void_emperor"
]
const SEA_PIRATE_IDS = ["coastal_pirate", "ocean_raider", "black_flag_privateer"]
const SEA_MONSTER_IDS = ["reef_serpent", "abyss_kraken"]

var body_color = Color("2e9c99")
var accent_color = Color("f2c66d")
var actor_kind = "player"
var display_id = "player"
var selected = false
var bob_time = 0.0
var art_sprite
var motion_direction = Vector2.ZERO
var walk_time = 0.0
var last_facing = "down"
var ship_hull_id = "sea_swallow"

func _ready():
	_refresh_art_sprite()

func configure(kind, color, accent = Color("f2c66d"), identity = ""):
	actor_kind = kind
	display_id = str(identity) if str(identity) != "" else str(kind)
	body_color = color
	accent_color = accent
	if is_inside_tree():
		_refresh_art_sprite()
	queue_redraw()

func set_ship_hull(hull_id):
	ship_hull_id = str(hull_id) if PLAYER_SHIP_CELLS.has(str(hull_id)) else "sea_swallow"
	if display_id == "player_ship" and is_inside_tree():
		_refresh_art_sprite()
	queue_redraw()

func _process(delta):
	bob_time += delta
	if is_instance_valid(art_sprite):
		var moving = motion_direction.length() > 0.05
		if display_id == "player":
			if moving:
				walk_time += delta
			_update_player_walk_sprite(moving)
		elif display_id == "player_ship":
			art_sprite.position.y = sin(bob_time * 3.1) * 2.0
			art_sprite.rotation = 0.0
		else:
			art_sprite.position.y = sin(bob_time * (7.5 if moving else 2.7)) * (2.2 if moving else 1.35)
			art_sprite.rotation = sin(bob_time * 7.5) * 0.018 if moving else 0.0
	queue_redraw()

func set_motion(direction):
	motion_direction = Vector2(direction)
	if display_id == "player_ship" or display_id in SEA_PIRATE_IDS:
		if motion_direction.length() > 0.05:
			rotation = motion_direction.angle() + PI * 0.5
		return
	if display_id == "player":
		if motion_direction.length() > 0.05:
			if abs(motion_direction.x) > abs(motion_direction.y) * 0.72:
				last_facing = "right" if motion_direction.x >= 0.0 else "left"
			else:
				last_facing = "down" if motion_direction.y >= 0.0 else "up"
		return
	if is_instance_valid(art_sprite) and abs(motion_direction.x) > 0.05:
		art_sprite.flip_h = motion_direction.x < 0.0

func _refresh_art_sprite():
	if is_instance_valid(art_sprite):
		art_sprite.queue_free()
	art_sprite = null
	if display_id == "player":
		art_sprite = Sprite2D.new()
		art_sprite.texture = PLAYER_WALK
		art_sprite.hframes = 4
		art_sprite.vframes = 2
		art_sprite.frame_coords = Vector2i(0, 1)
		art_sprite.scale = Vector2.ONE * 0.35
		art_sprite.z_index = 1
		add_child(art_sprite)
		return
	if display_id == "player_ship":
		var ship_texture = AtlasTexture.new()
		var ship_cell_size = Vector2(PLAYER_SHIP_ATLAS.get_width(), PLAYER_SHIP_ATLAS.get_height()) / 3.0
		ship_texture.atlas = PLAYER_SHIP_ATLAS
		ship_texture.region = Rect2(Vector2(PLAYER_SHIP_CELLS.get(ship_hull_id, Vector2i.ZERO)) * ship_cell_size, ship_cell_size)
		art_sprite = Sprite2D.new()
		art_sprite.texture = ship_texture
		art_sprite.scale = Vector2.ONE * 0.50
		art_sprite.z_index = 1
		add_child(art_sprite)
		return
	if not _has_raster_art(display_id):
		return
	var atlas = CHARACTER_ATLAS
	var cell_size = ATLAS_CELL_SIZE
	var cell = ATLAS_CELLS.get(display_id, Vector2i.ZERO)
	if NPC_ATLAS_CELLS.has(display_id):
		var npc_art = Dictionary(NPC_ATLAS_CELLS[display_id])
		atlas = _npc_atlas(str(npc_art.atlas))
		var npc_grid = Vector2(3, 2) if str(npc_art.atlas) == "e" else Vector2(4, 2)
		cell_size = Vector2(atlas.get_width(), atlas.get_height()) / npc_grid
		cell = Vector2i(npc_art.cell)
	elif ENEMY_ATLAS_CELLS.has(display_id):
		atlas = ENEMY_ATLAS
		cell_size = ENEMY_ATLAS_CELL_SIZE
		cell = ENEMY_ATLAS_CELLS[display_id]
	elif LEGACY_BOSS_ATLAS_A_CELLS.has(display_id):
		atlas = LEGACY_BOSS_ATLAS_A
		cell_size = LEGACY_BOSS_ATLAS_CELL_SIZE
		cell = LEGACY_BOSS_ATLAS_A_CELLS[display_id]
	elif LEGACY_BOSS_ATLAS_B_CELLS.has(display_id):
		atlas = LEGACY_BOSS_ATLAS_B
		cell_size = LEGACY_BOSS_ATLAS_CELL_SIZE
		cell = LEGACY_BOSS_ATLAS_B_CELLS[display_id]
	var atlas_texture = AtlasTexture.new()
	atlas_texture.atlas = atlas
	atlas_texture.region = Rect2(Vector2(cell.x, cell.y) * cell_size, cell_size)
	art_sprite = Sprite2D.new()
	art_sprite.texture = atlas_texture
	art_sprite.scale = Vector2.ONE * _art_scale()
	art_sprite.z_index = 1
	add_child(art_sprite)

func _has_raster_art(identity):
	return ATLAS_CELLS.has(identity) or NPC_ATLAS_CELLS.has(identity) or ENEMY_ATLAS_CELLS.has(identity) or LEGACY_BOSS_ATLAS_A_CELLS.has(identity) or LEGACY_BOSS_ATLAS_B_CELLS.has(identity)

func _npc_atlas(atlas_id):
	match str(atlas_id):
		"b": return NPC_ATLAS_B
		"c": return NPC_ATLAS_C
		"d": return NPC_ATLAS_D
		"e": return NPC_ATLAS_E
		_: return NPC_ATLAS_A

func _update_player_walk_sprite(moving):
	if not is_instance_valid(art_sprite):
		return
	var frame_index = int(floor(walk_time * 9.0)) % 4 if moving else 0
	if last_facing == "up":
		if art_sprite.texture != PLAYER_WALK_BACK:
			art_sprite.texture = PLAYER_WALK_BACK
			art_sprite.hframes = 4
			art_sprite.vframes = 1
		art_sprite.frame = frame_index
		art_sprite.flip_h = false
		art_sprite.scale = Vector2.ONE * 0.22
	else:
		if art_sprite.texture != PLAYER_WALK:
			art_sprite.texture = PLAYER_WALK
			art_sprite.hframes = 4
			art_sprite.vframes = 2
		var row = 1 if last_facing == "down" else 0
		art_sprite.frame_coords = Vector2i(frame_index, row)
		art_sprite.flip_h = last_facing == "left"
		art_sprite.scale = Vector2.ONE * 0.35
	art_sprite.position.y = sin(walk_time * 9.0 * PI) * 0.9 if moving else 0.0
	art_sprite.rotation = 0.0

func _art_scale():
	if NPC_ATLAS_CELLS.has(display_id):
		return 0.45
	if ENEMY_ATLAS_CELLS.has(display_id):
		match display_id:
			"abyss_kraken": return 0.26
			"coastal_pirate", "ocean_raider", "black_flag_privateer": return 0.32
			"tide_beast", "reef_serpent", "wreck_crab": return 0.34
			_: return 0.37
	if LEGACY_BOSS_ATLAS_A_CELLS.has(display_id) or LEGACY_BOSS_ATLAS_B_CELLS.has(display_id):
		return 0.29
	match display_id:
		"tavern_keeper": return 0.25
		"giant_bear": return 0.32
		"sewer_rat": return 0.38
		"wildwood_ghost": return 0.31
		"stone_puppet": return 0.30
		"vermilion_phantom": return 0.29
		"dungeon": return 0.27
		_: return 0.27

func _draw():
	if display_id == "player_ship":
		_draw_player_ship_marker()
		return
	if display_id in SEA_PIRATE_IDS and not _has_raster_art(display_id):
		_draw_ship()
		return
	var bob = sin(bob_time * 2.7) * 1.35
	var large = display_id in ["giant_bear", "stone_puppet", "tide_beast", "vermilion_phantom"] or display_id in LEGACY_BOSS_IDS or display_id in SEA_MONSTER_IDS
	_draw_oval(Vector2(0, 34 if large else 31), Vector2(31, 9) if large else Vector2(25, 7), Color(0.005, 0.02, 0.025, 0.38))
	if selected:
		var ring_radius = 39.0 if large else 34.0
		draw_arc(Vector2(0, 5), ring_radius, 0, TAU, 48, Color(0.03, 0.08, 0.09, 0.78), 6)
		draw_arc(Vector2(0, 5), ring_radius, -PI * 0.15, PI * 1.45, 42, Color("f6d778"), 3)
		var sparkle = Vector2.RIGHT.rotated(bob_time * 1.6) * ring_radius + Vector2(0, 5)
		draw_circle(sparkle, 4, Color("fff1ad"))
	draw_set_transform(Vector2(0, bob))
	if not _has_raster_art(display_id):
		if actor_kind in ["travel", "sea_port", "sea_return"]:
			_draw_travel_marker()
		elif actor_kind in ["discovery", "sea_treasure"]:
			_draw_discovery_marker()
		elif display_id in ["sewer_rat", "giant_bear", "wildwood_ghost", "stone_puppet", "tide_beast", "vermilion_phantom"] or display_id in LEGACY_BOSS_IDS or display_id in SEA_MONSTER_IDS:
			_draw_monster()
		else:
			_draw_person()
	draw_set_transform(Vector2.ZERO)

func _draw_ship():
	var bob = sin(bob_time * 3.1) * 2.0
	var pirate_ship = display_id in SEA_PIRATE_IDS
	var hull_color = Color("3b3035") if pirate_ship else Color("8d5837")
	var sail_color = Color("161821") if pirate_ship else Color("f0dfb5")
	var small_sail_color = Color("7c2635") if pirate_ship else Color("39bfb1")
	draw_set_transform(Vector2(0, bob))
	draw_ellipse_shadow(Vector2(0, 22), Vector2(43, 14), Color(0.005, 0.02, 0.025, 0.34))
	draw_colored_polygon(PackedVector2Array([Vector2(-31, 8), Vector2(31, 8), Vector2(20, 39), Vector2(-20, 39)]), hull_color)
	draw_polyline(PackedVector2Array([Vector2(-31, 8), Vector2(31, 8), Vector2(20, 39), Vector2(-20, 39), Vector2(-31, 8)]), Color("e2b966"), 4.0)
	draw_line(Vector2(0, 16), Vector2(0, -48), Color("4b3427"), 6.0)
	draw_colored_polygon(PackedVector2Array([Vector2(4, -43), Vector2(38, -2), Vector2(4, 4)]), sail_color)
	draw_colored_polygon(PackedVector2Array([Vector2(-4, -35), Vector2(-29, -5), Vector2(-4, 0)]), small_sail_color)
	draw_line(Vector2(0, -46), Vector2(0, 11), Color("f1c66d"), 2.0)
	draw_circle(Vector2(0, 13), 6.0, Color("ef6f73") if pirate_ship else Color("f1c66d"))
	if selected:
		draw_arc(Vector2(0, 5), 54.0, 0.0, TAU, 40, Color("f6d778"), 4.0)
	draw_set_transform(Vector2.ZERO)

func _draw_player_ship_marker():
	var bob = sin(bob_time * 3.1) * 2.0
	draw_set_transform(Vector2(0, bob))
	draw_ellipse_shadow(Vector2(0, 23), Vector2(43, 14), Color(0.005, 0.02, 0.025, 0.34))
	if selected:
		draw_arc(Vector2(0, 5), 54.0, 0.0, TAU, 40, Color("f6d778"), 4.0)
	draw_set_transform(Vector2.ZERO)

func draw_ellipse_shadow(center, radii, color):
	draw_set_transform(center, 0.0, Vector2(1.0, float(radii.y) / float(radii.x)))
	draw_circle(Vector2.ZERO, float(radii.x), color)
	draw_set_transform(Vector2.ZERO)

func _draw_travel_marker():
	var glow = Color(accent_color, 0.20 + (sin(bob_time * 2.2) + 1.0) * 0.06)
	draw_circle(Vector2.ZERO, 31, glow)
	draw_arc(Vector2.ZERO, 27, 0, TAU, 32, Color(accent_color, 0.82), 3)
	draw_arc(Vector2.ZERO, 18, -PI * 0.25, PI * 1.25, 22, Color(body_color, 0.95), 5)
	_polygon([Vector2(0, -22), Vector2(10, -4), Vector2(0, 2), Vector2(-10, -4)], accent_color, Color("23353b"), 2)
	draw_circle(Vector2.ZERO, 5, Color("e6ffff"))

func _draw_discovery_marker():
	var pulse = 0.72 + (sin(bob_time * 3.2) + 1.0) * 0.12
	draw_circle(Vector2(0, 2), 30, Color(accent_color, 0.12 * pulse))
	_round_rect(Rect2(-25, -15, 50, 34), Color("6e4a28"), Color("2c2118"), 7)
	_round_rect(Rect2(-20, -11, 40, 11), Color("9a6935"), Color("3a2819"), 5)
	draw_line(Vector2(-24, 1), Vector2(24, 1), Color("d4a953"), 3, true)
	_round_rect(Rect2(-6, -2, 12, 15), Color("e0b85d"), Color("4c3820"), 3)
	draw_circle(Vector2(0, -30), 5, Color("fff1ad", pulse))

func _draw_person():
	var coat = body_color
	var trim = accent_color
	var skin = Color("d6a076")
	var hair = Color("49352c")
	var trouser = Color("263746")
	var hostile = display_id in ["drunk_sailor", "mine_thief", "dungeon_guard"]

	match display_id:
		"alisa":
			coat = Color("4e83a8")
			trim = Color("e7cf93")
			hair = Color("6b3f2d")
		"tavern_keeper":
			coat = Color("6f4935")
			trim = Color("d2b17b")
			skin = Color("c88f68")
		"ship_owner":
			coat = Color("315b72")
			trim = Color("e1b957")
			hair = Color("7a6a59")
		"drunk_sailor":
			coat = Color("923f43")
			trim = Color("332f39")
			skin = Color("c48362")
		"mine_thief":
			coat = Color("68453c")
			trim = Color("2d3438")
			skin = Color("ad7357")
		"dungeon_guard":
			coat = Color("586a78")
			trim = Color("c5a85c")
			skin = Color("bd8462")
		"field":
			coat = Color("4d7254")
			trim = Color("d2bd6b")
		"city":
			coat = Color("3e6878")
			trim = Color("e0bd69")
		"dungeon":
			coat = Color("73554b")
			trim = Color("e28a55")

	# Tools and weapons sit behind the silhouette.
	if display_id == "player":
		draw_line(Vector2(15, 17), Vector2(31, -29), Color("e9f1ef"), 5, true)
		draw_line(Vector2(28, -26), Vector2(34, -34), trim, 4, true)
		draw_line(Vector2(10, 12), Vector2(25, 18), Color("6c442d"), 4, true)
	elif display_id == "drunk_sailor":
		draw_line(Vector2(-16, 8), Vector2(-34, 28), Color("6d4934"), 7, true)
		draw_circle(Vector2(-36, 30), 7, Color("a9804d"))
	elif display_id == "mine_thief":
		draw_line(Vector2(14, 8), Vector2(32, -25), Color("70513a"), 5, true)
		draw_line(Vector2(22, -27), Vector2(42, -20), Color("a7aca8"), 6, true)
	elif display_id == "dungeon_guard":
		draw_line(Vector2(20, 29), Vector2(20, -48), Color("8c6a43"), 5, true)
		_polygon([Vector2(20, -52), Vector2(14, -41), Vector2(26, -41)], Color("d9e0dd"), Color("26333b"), 2)
	elif display_id in ["field", "city", "dungeon"]:
		draw_line(Vector2(15, 15), Vector2(30, -22), Color("77563a"), 5, true)
		draw_circle(Vector2(31, -25), 7, Color("f0bf52"))

	# Legs, coat and sleeves have a dark ink outline for phone readability.
	_round_rect(Rect2(-14, 17, 11, 25), trouser, Color("15232c"), 3)
	_round_rect(Rect2(3, 17, 11, 25), trouser, Color("15232c"), 3)
	_round_rect(Rect2(-16, 34, 13, 9), Color("332e2d"), Color("15191b"), 2)
	_round_rect(Rect2(3, 34, 13, 9), Color("332e2d"), Color("15191b"), 2)
	if display_id == "alisa":
		_polygon([Vector2(-15, -3), Vector2(15, -3), Vector2(23, 31), Vector2(-23, 31)], coat, Color("23343d"), 2)
		draw_line(Vector2(-18, 22), Vector2(18, 22), trim, 3, true)
	else:
		_polygon([Vector2(-12, -11), Vector2(12, -11), Vector2(19, -5), Vector2(16, 25), Vector2(8, 30), Vector2(-8, 30), Vector2(-16, 25), Vector2(-19, -5)], coat, Color("1c2b32"), 2)
	_round_rect(Rect2(-25, -3, 9, 27), coat.darkened(0.12), Color("1c2b32"), 2)
	_round_rect(Rect2(16, -3, 9, 27), coat.darkened(0.12), Color("1c2b32"), 2)
	draw_line(Vector2(-13, 3), Vector2(13, 3), trim, 3, true)
	if display_id == "tavern_keeper":
		_polygon([Vector2(-11, 2), Vector2(11, 2), Vector2(14, 27), Vector2(-14, 27)], Color("c7ab7c"), Color("543f31"), 2)
	elif display_id == "ship_owner":
		draw_line(Vector2(0, -4), Vector2(0, 26), trim, 3, true)
		for y in [4, 13, 22]:
			draw_circle(Vector2(-5, y), 2, trim)
			draw_circle(Vector2(5, y), 2, trim)
	elif display_id == "dungeon_guard":
		_polygon([Vector2(-17, -5), Vector2(0, 6), Vector2(17, -5), Vector2(17, 17), Vector2(0, 25), Vector2(-17, 17)], Color("667b88"), Color("26333b"), 2)
		draw_circle(Vector2(-20, 9), 12, Color("596b76"))
		draw_arc(Vector2(-20, 9), 12, 0, TAU, 24, trim, 2)

	# Head, hair and headwear.
	draw_circle(Vector2(0, -22), 15, skin)
	draw_arc(Vector2(0, -22), 15, 0, TAU, 32, Color("3b2926"), 2)
	if display_id == "alisa":
		draw_arc(Vector2(0, -23), 16, PI * 0.78, TAU * 0.95, 28, hair, 8)
		draw_circle(Vector2(-14, -13), 5, hair)
		draw_circle(Vector2(14, -13), 5, hair)
		draw_line(Vector2(-9, -36), Vector2(9, -36), trim, 3, true)
	elif display_id == "ship_owner":
		_polygon([Vector2(-22, -36), Vector2(0, -43), Vector2(22, -36), Vector2(12, -29), Vector2(-12, -29)], Color("243a4a"), Color("17252e"), 2)
		draw_line(Vector2(-13, -34), Vector2(13, -34), trim, 2, true)
	elif display_id == "drunk_sailor":
		draw_arc(Vector2(0, -24), 15, PI, TAU, 24, hair, 7)
		draw_line(Vector2(-16, -31), Vector2(17, -31), Color("c6494d"), 6, true)
		draw_line(Vector2(14, -31), Vector2(24, -25), Color("c6494d"), 4, true)
	elif display_id == "mine_thief":
		_polygon([Vector2(-17, -31), Vector2(0, -43), Vector2(17, -31), Vector2(14, -19), Vector2(-14, -19)], trim, Color("182329"), 2)
		draw_line(Vector2(-12, -23), Vector2(12, -23), Color("171b1e"), 5, true)
	elif display_id == "dungeon_guard":
		draw_arc(Vector2(0, -24), 17, PI, TAU, 22, Color("7b8790"), 10)
		_polygon([Vector2(-19, -25), Vector2(19, -25), Vector2(13, -17), Vector2(-13, -17)], Color("87969d"), Color("26333b"), 2)
		draw_line(Vector2(0, -40), Vector2(0, -48), trim, 4, true)
	else:
		draw_arc(Vector2(0, -24), 15, PI, TAU, 22, hair, 8)
		if display_id in ["player", "field", "city", "dungeon"]:
			_polygon([Vector2(-19, -34), Vector2(15, -38), Vector2(19, -30), Vector2(-17, -27)], trim, Color("41352c"), 2)

	if not display_id in ["mine_thief", "dungeon_guard"]:
		draw_circle(Vector2(-5, -22), 2, Color("1d2930"))
		draw_circle(Vector2(5, -22), 2, Color("1d2930"))
	else:
		draw_line(Vector2(-8, -22), Vector2(-2, -23), Color("111719"), 2, true)
		draw_line(Vector2(8, -22), Vector2(2, -23), Color("111719"), 2, true)
	if hostile:
		draw_line(Vector2(-5, -14), Vector2(5, -14), Color("743d36"), 2, true)

func _draw_monster():
	if display_id in SEA_MONSTER_IDS:
		_draw_sea_monster()
		return
	if display_id in LEGACY_BOSS_IDS:
		_draw_legacy_boss()
		return
	match display_id:
		"sewer_rat": _draw_rat()
		"giant_bear": _draw_bear()
		"wildwood_ghost": _draw_ghost()
		"stone_puppet": _draw_golem()
		"tide_beast": _draw_tide_beast()
		"vermilion_phantom": _draw_phoenix()

func _draw_sea_monster():
	var outline = Color("102533")
	var foam = Color(0.55, 0.95, 0.92, 0.45)
	draw_arc(Vector2(0, 24), 48, PI, TAU, 24, foam, 7)
	if display_id == "reef_serpent":
		var body = Color("358b83")
		draw_arc(Vector2(-8, 5), 31, -1.7, 1.55, 26, outline, 16)
		draw_arc(Vector2(-8, 5), 31, -1.7, 1.55, 26, body, 10)
		draw_circle(Vector2(18, -25), 17, body.lightened(0.08))
		draw_arc(Vector2(18, -25), 17, 0, TAU, 24, outline, 3)
		draw_circle(Vector2(24, -29), 3, accent_color)
		for fin in [-1, 1]:
			var side = float(fin)
			draw_colored_polygon(PackedVector2Array([Vector2(side * 11, -10), Vector2(side * 31, -18), Vector2(side * 18, 4)]), body.darkened(0.18))
	else:
		var flesh = Color("68508a")
		draw_circle(Vector2(0, -13), 31, flesh)
		draw_arc(Vector2(0, -13), 31, 0, TAU, 28, outline, 4)
		draw_circle(Vector2(-10, -18), 5, Color("f3cf76"))
		draw_circle(Vector2(10, -18), 5, Color("f3cf76"))
		for tentacle in range(6):
			var x = -30.0 + tentacle * 12.0
			var bend = -12.0 if tentacle % 2 == 0 else 12.0
			draw_polyline(PackedVector2Array([Vector2(x, 6), Vector2(x + bend, 25), Vector2(x - bend * 0.4, 42)]), flesh, 8, true)

func _draw_legacy_boss():
	var outline = Color("101b27")
	var core = body_color.lightened(0.08)
	var glow = Color(accent_color, 0.30 + (sin(bob_time * 2.4) + 1.0) * 0.08)
	draw_circle(Vector2(0, -6), 48, Color(accent_color, 0.08))
	draw_arc(Vector2(0, -6), 43, bob_time * 0.35, bob_time * 0.35 + PI * 1.65, 42, glow, 4)
	# Every late-game boss shares a readable raid silhouette, then receives a
	# distinct legendary crest so it remains recognizable on a phone screen.
	_polygon([Vector2(-26, -12), Vector2(-34, 25), Vector2(-17, 39), Vector2(0, 31), Vector2(17, 39), Vector2(34, 25), Vector2(26, -12)], core, outline, 3)
	draw_circle(Vector2(0, -26), 20, core.lightened(0.10))
	draw_arc(Vector2(0, -26), 20, 0, TAU, 30, outline, 3)
	draw_circle(Vector2(-7, -28), 3, accent_color)
	draw_circle(Vector2(7, -28), 3, accent_color)
	match display_id:
		"basin_leviathan":
			_polygon([Vector2(-18, -40), Vector2(-39, -53), Vector2(-27, -24)], Color("c7922e"), outline, 2)
			_polygon([Vector2(18, -40), Vector2(39, -53), Vector2(27, -24)], Color("c7922e"), outline, 2)
			for x in [-38, 38]: draw_circle(Vector2(x, 12), 10, Color("f2c34f"))
		"nine_tail_fox":
			_polygon([Vector2(-16, -42), Vector2(-27, -63), Vector2(-4, -45)], Color("d96d58"), outline, 2)
			_polygon([Vector2(16, -42), Vector2(27, -63), Vector2(4, -45)], Color("d96d58"), outline, 2)
			for side in [-1, 1]:
				for tail in range(3): draw_arc(Vector2(side * 20, 18), 28 + tail * 7, -2.0 if side < 0 else -1.15, 0.45 if side < 0 else 2.0, 18, Color("db866d"), 6)
		"earth_demon_king":
			_polygon([Vector2(-22, -43), Vector2(-14, -64), Vector2(0, -48), Vector2(14, -64), Vector2(22, -43)], Color("a48142"), outline, 3)
			for y in [-2, 13, 28]: draw_line(Vector2(-25, y), Vector2(25, y + 3), Color("56d3c7"), 3)
		"tira_guardian":
			for side in [-1, 1]:
				draw_line(Vector2(side * 30, 27), Vector2(side * 48, -48), Color("d7e4e6"), 7)
				draw_line(Vector2(side * 22, 4), Vector2(side * 45, 10), accent_color, 4)
		"celestial_demon_general", "returned_demon_king":
			_polygon([Vector2(-26, -4), Vector2(-63, -38), Vector2(-52, 17), Vector2(-30, 28)], core.darkened(0.25), outline, 3)
			_polygon([Vector2(26, -4), Vector2(63, -38), Vector2(52, 17), Vector2(30, 28)], core.darkened(0.25), outline, 3)
			_polygon([Vector2(-15, -43), Vector2(-9, -62), Vector2(0, -47), Vector2(9, -62), Vector2(15, -43)], accent_color, outline, 2)
		"jade_dream_queen":
			_polygon([Vector2(-22, -42), Vector2(-13, -62), Vector2(0, -49), Vector2(13, -62), Vector2(22, -42)], Color("86d7c4"), outline, 2)
			for side in [-1, 1]: draw_arc(Vector2(side * 25, 7), 30, -1.7, 1.7, 22, Color("b7f0dc"), 5)
		"black_furnace_lord":
			draw_circle(Vector2(0, 9), 13, Color("f06a35"))
			draw_circle(Vector2(0, 9), 6 + sin(bob_time * 3.0) * 2, Color("ffd06a"))
			for side in [-1, 1]: draw_line(Vector2(side * 26, 1), Vector2(side * 48, -26), Color("c94d32"), 8)
		"clockwork_tailor":
			for side in [-1, 1]:
				draw_line(Vector2(side * 25, 1), Vector2(side * 49, -20), Color("b5aa86"), 5)
				draw_line(Vector2(side * 25, 12), Vector2(side * 49, 35), Color("b5aa86"), 5)
			draw_circle(Vector2(0, 8), 11, Color("e0b557"))
			draw_line(Vector2(-9, 0), Vector2(9, 16), outline, 3)
			draw_line(Vector2(9, 0), Vector2(-9, 16), outline, 3)
		"tide_void_emperor":
			draw_circle(Vector2(0, 7), 17, Color("06101e"))
			draw_arc(Vector2(0, 7), 17, 0, TAU, 28, Color("58e2d1"), 4)
			for arm in range(6):
				var angle = float(arm) * TAU / 6.0 + bob_time * 0.1
				draw_line(Vector2.from_angle(angle) * 28 + Vector2(0, 7), Vector2.from_angle(angle + 0.25) * 55 + Vector2(0, 7), Color("486ba4"), 7)

func _draw_rat():
	var fur = Color("66706c")
	var outline = Color("27302e")
	draw_polyline(PackedVector2Array([Vector2(-18, 10), Vector2(-34, 7), Vector2(-43, -2), Vector2(-48, -12)]), Color("bd8b79"), 4, true)
	_draw_oval(Vector2(-4, 5), Vector2(25, 17), fur, outline)
	draw_circle(Vector2(18, -4), 14, fur.lightened(0.08))
	draw_arc(Vector2(18, -4), 14, 0, TAU, 28, outline, 2)
	draw_circle(Vector2(10, -16), 7, Color("8b7771"))
	draw_circle(Vector2(24, -17), 7, Color("8b7771"))
	draw_circle(Vector2(27, -5), 3, Color("191d1d"))
	draw_circle(Vector2(17, -7), 2, Color("e6c45e"))
	for x in [-16, 4, 19]:
		_round_rect(Rect2(x, 17, 10, 7), Color("4b504e"), outline, 2)

func _draw_bear():
	var fur = Color("67483b")
	var outline = Color("2d221e")
	_round_rect(Rect2(-31, -5, 15, 39), fur.darkened(0.12), outline, 4)
	_round_rect(Rect2(16, -5, 15, 39), fur.darkened(0.12), outline, 4)
	_draw_oval(Vector2(0, 7), Vector2(29, 31), fur, outline)
	draw_circle(Vector2(0, -23), 21, fur.lightened(0.05))
	draw_arc(Vector2(0, -23), 21, 0, TAU, 32, outline, 3)
	draw_circle(Vector2(-16, -39), 8, fur)
	draw_circle(Vector2(16, -39), 8, fur)
	_draw_oval(Vector2(0, -17), Vector2(12, 9), Color("b18161"), outline)
	draw_circle(Vector2(0, -21), 4, Color("201b19"))
	draw_circle(Vector2(-8, -29), 2, Color("f3c862"))
	draw_circle(Vector2(8, -29), 2, Color("f3c862"))

func _draw_ghost():
	var glow = Color("86d6d4")
	_polygon([Vector2(0, -44), Vector2(22, -30), Vector2(24, 10), Vector2(16, 37), Vector2(6, 27), Vector2(-2, 41), Vector2(-11, 27), Vector2(-22, 36), Vector2(-25, 7), Vector2(-21, -29)], Color(glow, 0.24), Color(glow, 0.35), 5)
	_polygon([Vector2(0, -39), Vector2(17, -27), Vector2(18, 11), Vector2(11, 31), Vector2(3, 22), Vector2(-4, 35), Vector2(-12, 22), Vector2(-18, 30), Vector2(-19, 5), Vector2(-16, -27)], Color("87b9be"), Color("31565e"), 2)
	draw_circle(Vector2(-6, -19), 3, Color("d7fff5"))
	draw_circle(Vector2(7, -19), 3, Color("d7fff5"))
	draw_line(Vector2(-5, -8), Vector2(6, -8), Color("41626b"), 2, true)
	draw_line(Vector2(-15, -2), Vector2(-34, 12), Color("729fa5"), 8, true)
	draw_line(Vector2(15, -2), Vector2(34, 12), Color("729fa5"), 8, true)

func _draw_golem():
	var stone = Color("747871")
	var outline = Color("303735")
	_round_rect(Rect2(-38, -9, 18, 36), stone.darkened(0.1), outline, 5)
	_round_rect(Rect2(20, -9, 18, 36), stone.darkened(0.1), outline, 5)
	_round_rect(Rect2(-25, -20, 50, 48), stone, outline, 6)
	_polygon([Vector2(-18, -42), Vector2(14, -45), Vector2(24, -31), Vector2(17, -17), Vector2(-16, -17), Vector2(-24, -30)], stone.lightened(0.08), outline, 3)
	_round_rect(Rect2(-22, 23, 18, 17), stone.darkened(0.12), outline, 4)
	_round_rect(Rect2(4, 23, 18, 17), stone.darkened(0.12), outline, 4)
	var rune = Color("55e1d4")
	draw_line(Vector2(0, -13), Vector2(0, 17), rune, 3, true)
	draw_line(Vector2(-10, 2), Vector2(10, 2), rune, 3, true)
	draw_circle(Vector2(-8, -31), 3, rune)
	draw_circle(Vector2(8, -31), 3, rune)

func _draw_tide_beast():
	var scale_color = Color("347d83")
	var outline = Color("173c42")
	_polygon([Vector2(-24, -10), Vector2(-42, -30), Vector2(-37, 1)], Color("65bdba"), outline, 2)
	_polygon([Vector2(24, -10), Vector2(42, -30), Vector2(37, 1)], Color("65bdba"), outline, 2)
	_draw_oval(Vector2(0, 4), Vector2(30, 28), scale_color, outline)
	draw_circle(Vector2(0, -23), 20, scale_color.lightened(0.08))
	draw_arc(Vector2(0, -23), 20, 0, TAU, 32, outline, 3)
	draw_circle(Vector2(-9, -28), 5, Color("d7e56d"))
	draw_circle(Vector2(9, -28), 5, Color("d7e56d"))
	draw_circle(Vector2(-9, -28), 2, Color("142328"))
	draw_circle(Vector2(9, -28), 2, Color("142328"))
	draw_line(Vector2(-10, -13), Vector2(10, -13), Color("173c42"), 3, true)
	for side in [-1, 1]:
		_polygon([Vector2(16 * side, 17), Vector2(38 * side, 31), Vector2(15 * side, 35)], scale_color.darkened(0.08), outline, 2)

func _draw_phoenix():
	var red = Color("bd3d3d")
	var orange = Color("f19b45")
	var gold = Color("ffd06a")
	_polygon([Vector2(-8, -10), Vector2(-52, -36), Vector2(-42, -4), Vector2(-55, 19), Vector2(-18, 11)], red, Color("54242a"), 2)
	_polygon([Vector2(8, -10), Vector2(52, -36), Vector2(42, -4), Vector2(55, 19), Vector2(18, 11)], red, Color("54242a"), 2)
	_polygon([Vector2(-13, -4), Vector2(-43, -24), Vector2(-31, 2), Vector2(-42, 12)], orange, Color("8b342d"), 2)
	_polygon([Vector2(13, -4), Vector2(43, -24), Vector2(31, 2), Vector2(42, 12)], orange, Color("8b342d"), 2)
	_draw_oval(Vector2(0, 4), Vector2(18, 28), red, Color("54242a"))
	draw_circle(Vector2(0, -25), 14, orange)
	draw_arc(Vector2(0, -25), 14, 0, TAU, 28, Color("54242a"), 2)
	_polygon([Vector2(10, -26), Vector2(26, -20), Vector2(10, -15)], gold, Color("8b5427"), 2)
	_polygon([Vector2(-7, 27), Vector2(-18, 52), Vector2(0, 39), Vector2(17, 54), Vector2(8, 25)], orange, Color("8b342d"), 2)
	draw_circle(Vector2(4, -29), 2, Color("382228"))

func _round_rect(rect, fill, outline, radius = 4):
	var style = StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = outline
	style.set_border_width_all(2)
	style.set_corner_radius_all(radius)
	draw_style_box(style, rect)

func _polygon(points, fill, outline = Color.TRANSPARENT, width = 0):
	var packed = PackedVector2Array(points)
	draw_colored_polygon(packed, fill)
	if width > 0 and outline.a > 0:
		var loop = packed.duplicate()
		loop.append(packed[0])
		draw_polyline(loop, outline, width, true)

func _draw_oval(center, radius, fill, outline = Color.TRANSPARENT):
	var points = PackedVector2Array()
	for index in range(32):
		var angle = TAU * float(index) / 32.0
		points.append(center + Vector2(cos(angle) * radius.x, sin(angle) * radius.y))
	draw_colored_polygon(points, fill)
	if outline.a > 0:
		var loop = points.duplicate()
		loop.append(points[0])
		draw_polyline(loop, outline, 2, true)
