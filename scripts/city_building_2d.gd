extends Node2D

const MEDITERRANEAN_ATLAS = preload("res://assets/art/buildings/mediterranean_buildings_v1.webp")
const WORLD_ATLAS = preload("res://assets/art/buildings/world_buildings_v1.webp")
const EAST_NORTH_ATLAS = preload("res://assets/art/buildings/east_north_buildings_v1.webp")
const HARMONIZE_SHADER = preload("res://shaders/city_building_harmonize.gdshader")

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
const PORT_LIGHTING = {
	"venice_dock": {"saturation": 0.82, "brightness": 0.96, "tint": Color("fff4e6")},
	"ragusa_dock": {"saturation": 0.78, "brightness": 0.94, "tint": Color("fff7eb")},
	"alexandria_dock": {"saturation": 0.84, "brightness": 0.98, "tint": Color("fff0d5")},
	"malta_dock": {"saturation": 0.78, "brightness": 0.98, "tint": Color("ffedc9")},
	"cape_town_dock": {"saturation": 0.74, "brightness": 0.88, "tint": Color("f4ead6")},
	"quanzhou_dock": {"saturation": 0.78, "brightness": 0.90, "tint": Color("f8e5cb")},
	"athens_dock": {"saturation": 0.76, "brightness": 0.96, "tint": Color("fff8e9")},
	"yangzhou_dock": {"saturation": 0.66, "brightness": 0.68, "tint": Color("91b5ff")},
	"amsterdam_dock": {"saturation": 0.70, "brightness": 0.84, "tint": Color("dae8ff")}
}

var port_id = ""
var building_id = ""
var display_name = ""
var model_role = "hall"
var footprint = Rect2()
var npc_ids = []
var art_sprite: Sprite2D
var rendered_width = 155.0

func configure(city_port_id, building_data, world_scale = 1.0):
	port_id = str(city_port_id)
	building_id = str(building_data.get("id", "building"))
	display_name = str(building_data.get("name", "建筑"))
	footprint = Rect2(building_data.get("footprint", Rect2(0, 0, 160, 130)))
	npc_ids = Array(building_data.get("npc_ids", [])).duplicate()
	model_role = _resolve_model_role(building_data)
	z_index = 4
	queue_redraw()

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
	rendered_width = max(155.0, footprint.size.x * float(world_scale) * 1.12)
	var art_scale = rendered_width / cell_width
	art_sprite.scale = Vector2.ONE * art_scale
	art_sprite.position = Vector2(0, -cell_height * art_scale * 0.5)
	art_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	art_sprite.material = _city_material()
	add_child(art_sprite)
	queue_redraw()

func _draw():
	# Two translucent ellipses bridge the painted foundation and transparent sprite.
	# Keeping them on the parent draws them behind the building art.
	_draw_shadow_ellipse(Vector2(0, -7), Vector2(rendered_width * 0.46, max(18.0, rendered_width * 0.12)), Color(28.0 / 255.0, 23.0 / 255.0, 20.0 / 255.0, 0.11))
	_draw_shadow_ellipse(Vector2(0, -5), Vector2(rendered_width * 0.36, max(13.0, rendered_width * 0.075)), Color(18.0 / 255.0, 16.0 / 255.0, 15.0 / 255.0, 0.14))

func _draw_shadow_ellipse(center, radii, color):
	var points = PackedVector2Array()
	for index in range(32):
		var angle = TAU * float(index) / 32.0
		points.append(center + Vector2(cos(angle) * radii.x, sin(angle) * radii.y))
	draw_colored_polygon(points, color)

func _city_material():
	var lighting = Dictionary(PORT_LIGHTING.get(port_id, PORT_LIGHTING.venice_dock))
	var material = ShaderMaterial.new()
	material.shader = HARMONIZE_SHADER
	material.set_shader_parameter("saturation", float(lighting.saturation))
	material.set_shader_parameter("brightness", float(lighting.brightness))
	var tint: Color = lighting.get("tint", Color.WHITE)
	material.set_shader_parameter("city_tint", Vector3(tint.r, tint.g, tint.b))
	return material

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
