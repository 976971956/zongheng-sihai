extends Node2D

const MEDITERRANEAN_ATLAS = preload("res://assets/art/buildings/mediterranean_buildings_v1.webp")
const WORLD_ATLAS = preload("res://assets/art/buildings/world_buildings_v1.webp")
const EAST_NORTH_ATLAS = preload("res://assets/art/buildings/east_north_buildings_v1.webp")

const ATLAS_COLUMNS = 4
const ATLAS_ROWS = 3
const ROLE_COLUMNS = {
	"market": 0,
	"hall": 1,
	"harbor": 2,
	"shipyard": 3
}
const PORT_ART = {
	"venice_dock": {"atlas": MEDITERRANEAN_ATLAS, "row": 0},
	"ragusa_dock": {"atlas": MEDITERRANEAN_ATLAS, "row": 1},
	"malta_dock": {"atlas": MEDITERRANEAN_ATLAS, "row": 2},
	"alexandria_dock": {"atlas": WORLD_ATLAS, "row": 0},
	"athens_dock": {"atlas": WORLD_ATLAS, "row": 1},
	"cape_town_dock": {"atlas": WORLD_ATLAS, "row": 2},
	"quanzhou_dock": {"atlas": EAST_NORTH_ATLAS, "row": 0},
	"yangzhou_dock": {"atlas": EAST_NORTH_ATLAS, "row": 1},
	"amsterdam_dock": {"atlas": EAST_NORTH_ATLAS, "row": 2}
}

var port_id = ""
var building_id = ""
var display_name = ""
var model_role = "hall"
var footprint = Rect2()
var npc_ids = []
var art_sprite: Sprite2D

func configure(city_port_id, building_data, world_scale = 1.0):
	port_id = str(city_port_id)
	building_id = str(building_data.get("id", "building"))
	display_name = str(building_data.get("name", "建筑"))
	footprint = Rect2(building_data.get("footprint", Rect2(0, 0, 160, 130)))
	npc_ids = Array(building_data.get("npc_ids", [])).duplicate()
	model_role = _resolve_model_role(building_data)
	z_index = 4

	var art_data = Dictionary(PORT_ART.get(port_id, PORT_ART.venice_dock))
	var source_texture: Texture2D = art_data.atlas
	var atlas_size = source_texture.get_size()
	var cell_width = atlas_size.x / float(ATLAS_COLUMNS)
	var cell_height = atlas_size.y / float(ATLAS_ROWS)
	var atlas_texture = AtlasTexture.new()
	atlas_texture.atlas = source_texture
	atlas_texture.region = Rect2(
		float(ROLE_COLUMNS.get(model_role, ROLE_COLUMNS.hall)) * cell_width,
		float(art_data.row) * cell_height,
		cell_width,
		cell_height
	)

	art_sprite = Sprite2D.new()
	art_sprite.texture = atlas_texture
	var target_width = max(155.0, footprint.size.x * float(world_scale) * 1.12)
	var art_scale = target_width / cell_width
	art_sprite.scale = Vector2.ONE * art_scale
	art_sprite.position = Vector2(0, -cell_height * art_scale * 0.5)
	art_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	add_child(art_sprite)

func _resolve_model_role(building_data):
	var explicit_role = str(building_data.get("model", ""))
	if explicit_role in ROLE_COLUMNS:
		return explicit_role
	var signature = (str(building_data.get("id", "")) + " " + str(building_data.get("name", ""))).to_lower()
	for token in ["yard", "shipwright", "ship_shed", "船棚", "船坞", "锻造"]:
		if token in signature:
			return "shipyard"
	for token in ["market", "store", "warehouse", "bazaar", "auction", "货栈", "市", "市场", "仓", "织坊", "厨房"]:
		if token in signature:
			return "market"
	for token in ["harbor", "lighthouse", "pilot", "maritime", "quay", "港务", "灯房", "码头", "市舶司", "堡"]:
		if token in signature:
			return "harbor"
	return "hall"
