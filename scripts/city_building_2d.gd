extends Node2D

const CITY_ACCENTS = {
	"venice_dock": Color("efc86b"),
	"ragusa_dock": Color("e6bd73"),
	"alexandria_dock": Color("68d7dc"),
	"malta_dock": Color("edc05c"),
	"cape_town_dock": Color("d7c28b"),
	"quanzhou_dock": Color("e9ad62"),
	"athens_dock": Color("9edced"),
	"yangzhou_dock": Color("8dc8ff"),
	"amsterdam_dock": Color("e4b868")
}

var port_id = ""
var building_id = ""
var display_name = ""
var model_role = "hall"
var footprint = Rect2()
var npc_ids = []
var frame_size = Vector2.ZERO
var integrated_background = true
var highlighted = false
var pulse_time = 0.0
var name_label: Label

func configure(city_port_id, building_data, world_scale = 1.0):
	port_id = str(city_port_id)
	building_id = str(building_data.get("id", "building"))
	display_name = str(building_data.get("name", "建筑"))
	footprint = Rect2(building_data.get("footprint", Rect2(0, 0, 160, 130)))
	npc_ids = Array(building_data.get("npc_ids", [])).duplicate()
	model_role = str(building_data.get("model", "hall"))
	frame_size = footprint.size * float(world_scale)
	z_index = 4
	_create_name_label()
	queue_redraw()

func _process(delta):
	if not highlighted:
		return
	pulse_time += delta
	queue_redraw()

func set_highlighted(value):
	var next_value = bool(value)
	if highlighted == next_value:
		return
	highlighted = next_value
	if is_instance_valid(name_label):
		name_label.modulate = Color.WHITE if highlighted else Color(1, 1, 1, 0.78)
	queue_redraw()

func _create_name_label():
	name_label = Label.new()
	name_label.text = "◆ %s" % display_name
	var label_width = clamp(frame_size.x * 0.82, 150.0, 260.0)
	name_label.position = Vector2(-label_width * 0.5, -frame_size.y - 31.0)
	name_label.size = Vector2(label_width, 28.0)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 14)
	name_label.add_theme_color_override("font_color", Color("fff0bd"))
	name_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	name_label.add_theme_constant_override("shadow_offset_x", 1)
	name_label.add_theme_constant_override("shadow_offset_y", 2)
	var panel = StyleBoxFlat.new()
	panel.bg_color = Color(0.035, 0.055, 0.06, 0.76)
	panel.border_color = Color(_accent_color(), 0.62)
	panel.set_border_width_all(1)
	panel.set_corner_radius_all(8)
	name_label.add_theme_stylebox_override("normal", panel)
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	name_label.modulate = Color(1, 1, 1, 0.78)
	add_child(name_label)

func _draw():
	if frame_size.x <= 0.0 or frame_size.y <= 0.0:
		return
	var frame_rect = Rect2(-frame_size.x * 0.5, -frame_size.y, frame_size.x, frame_size.y)
	var pulse = 0.88 + sin(pulse_time * 4.5) * 0.12 if highlighted else 0.42
	var accent = _accent_color()
	draw_rect(frame_rect, Color(accent, 0.055 if highlighted else 0.018), true)
	draw_rect(frame_rect, Color(accent, pulse), false, 3.0 if highlighted else 1.5, true)
	var corner_length = clamp(min(frame_size.x, frame_size.y) * 0.18, 18.0, 38.0)
	var corner_color = Color(accent, min(1.0, pulse + 0.16))
	var line_width = 5.0 if highlighted else 3.0
	_draw_corner(frame_rect.position, 1.0, 1.0, corner_length, corner_color, line_width)
	_draw_corner(Vector2(frame_rect.end.x, frame_rect.position.y), -1.0, 1.0, corner_length, corner_color, line_width)
	_draw_corner(Vector2(frame_rect.position.x, frame_rect.end.y), 1.0, -1.0, corner_length, corner_color, line_width)
	_draw_corner(frame_rect.end, -1.0, -1.0, corner_length, corner_color, line_width)
	var entrance = Vector2(0, 0)
	var diamond = PackedVector2Array([entrance + Vector2(0, -8), entrance + Vector2(8, 0), entrance + Vector2(0, 8), entrance + Vector2(-8, 0)])
	draw_colored_polygon(diamond, Color(accent, 0.9 if highlighted else 0.58))

func _draw_corner(origin, horizontal_direction, vertical_direction, length, color, width):
	draw_line(origin, origin + Vector2(horizontal_direction * length, 0), color, width, true)
	draw_line(origin, origin + Vector2(0, vertical_direction * length), color, width, true)

func _accent_color():
	var accent: Color = CITY_ACCENTS.get(port_id, CITY_ACCENTS.venice_dock)
	return accent
