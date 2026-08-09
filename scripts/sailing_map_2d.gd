extends Control

signal port_selected(port_id)
signal voyage_finished

const OCEAN = Color("092735")
const DEEP_OCEAN = Color("061a26")
const LAND = Color("34584e")
const COAST = Color("6d9a7d")
const TEAL = Color("38c5b5")
const GOLD = Color("f1c66d")
const MUTED = Color("7899a1")
const INK = Color("e2f1f1")

const PORT_POSITIONS = {
	"amsterdam_dock": Vector2(95, 88),
	"venice_dock": Vector2(220, 155),
	"ragusa_dock": Vector2(300, 205),
	"athens_dock": Vector2(375, 255),
	"malta_dock": Vector2(275, 315),
	"alexandria_dock": Vector2(395, 350),
	"cape_town_dock": Vector2(155, 438),
	"yangzhou_dock": Vector2(505, 185),
	"quanzhou_dock": Vector2(525, 315)
}

var game_state
var current_port = ""
var selected_port = ""
var from_port = ""
var to_port = ""
var travel_progress = 0.0
var traveling = false
var port_buttons = {}

func _ready():
	custom_minimum_size = Vector2(610, 500)
	mouse_filter = Control.MOUSE_FILTER_STOP

func configure(source_state):
	game_state = source_state
	current_port = str(source_state.player.location)
	if not GameData.TRADE_PORTS.has(current_port):
		current_port = "venice_dock"
	_build_port_buttons()
	queue_redraw()

func _build_port_buttons():
	for child in get_children():
		child.queue_free()
	port_buttons = {}
	for port_id in GameData.TRADE_PORTS:
		var button = Button.new()
		button.text = str(GameData.TRADE_PORTS[port_id].name)
		button.custom_minimum_size = Vector2(94, 34)
		button.position = Vector2(PORT_POSITIONS[port_id].x - 47, PORT_POSITIONS[port_id].y + 12)
		button.add_theme_font_size_override("font_size", 13)
		button.focus_mode = Control.FOCUS_NONE
		button.disabled = not game_state.is_port_unlocked(port_id)
		button.tooltip_text = "随主线章节解锁" if button.disabled else str(GameData.TRADE_PORTS[port_id].note)
		button.pressed.connect(select_port.bind(str(port_id)))
		add_child(button)
		port_buttons[port_id] = button
	_refresh_buttons()

func select_port(port_id):
	var resolved_port = str(port_id)
	if traveling or not port_buttons.has(resolved_port) or port_buttons[resolved_port].disabled:
		return
	selected_port = resolved_port
	_refresh_buttons()
	queue_redraw()
	port_selected.emit(resolved_port)

func _refresh_buttons():
	for port_id in port_buttons:
		var button = port_buttons[port_id]
		if str(port_id) == current_port:
			button.text = "● %s" % GameData.TRADE_PORTS[port_id].name
		elif str(port_id) == selected_port:
			button.text = "◆ %s" % GameData.TRADE_PORTS[port_id].name
		else:
			button.text = str(GameData.TRADE_PORTS[port_id].name)
		button.disabled = traveling or not game_state.is_port_unlocked(port_id)

func play_voyage(origin, destination, duration = 2.2):
	from_port = str(origin)
	to_port = str(destination)
	travel_progress = 0.0
	traveling = true
	_refresh_buttons()
	queue_redraw()
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_method(_set_travel_progress, 0.0, 1.0, max(0.05, float(duration)))
	tween.finished.connect(_finish_voyage)

func _set_travel_progress(value):
	travel_progress = float(value)
	queue_redraw()

func _finish_voyage():
	travel_progress = 1.0
	traveling = false
	current_port = to_port
	selected_port = ""
	_refresh_buttons()
	queue_redraw()
	voyage_finished.emit()

func _draw():
	draw_style_box(_panel_style(), Rect2(Vector2.ZERO, size))
	_draw_landmasses()
	_draw_currents()
	for route_key in GameData.TRADE_ROUTES:
		var route_ports = str(route_key).split("|")
		if route_ports.size() != 2:
			continue
		var a = str(route_ports[0])
		var b = str(route_ports[1])
		var highlighted = (a == current_port and b == selected_port) or (b == current_port and a == selected_port)
		var route_color = Color(GOLD, 0.9) if highlighted else Color(TEAL, 0.25)
		draw_dashed_line(PORT_POSITIONS[a], PORT_POSITIONS[b], route_color, 2.5 if highlighted else 1.5, 8.0)
	for port_id in PORT_POSITIONS:
		var unlocked = game_state != null and game_state.is_port_unlocked(port_id)
		var node_color = MUTED
		if unlocked:
			node_color = GOLD if port_id == current_port else TEAL
		if port_id == selected_port:
			node_color = INK
		draw_circle(PORT_POSITIONS[port_id], 8.0, Color(DEEP_OCEAN, 0.95))
		draw_arc(PORT_POSITIONS[port_id], 9.0, 0.0, TAU, 24, node_color, 3.0)
		if not unlocked:
			draw_line(PORT_POSITIONS[port_id] - Vector2(4, 4), PORT_POSITIONS[port_id] + Vector2(4, 4), MUTED, 2.0)
	if traveling and PORT_POSITIONS.has(from_port) and PORT_POSITIONS.has(to_port):
		_draw_ship(_voyage_point(travel_progress))

func _draw_landmasses():
	draw_colored_polygon(PackedVector2Array([Vector2(15, 25), Vector2(175, 24), Vector2(210, 105), Vector2(168, 185), Vector2(70, 205), Vector2(15, 160)]), LAND)
	draw_polyline(PackedVector2Array([Vector2(15, 25), Vector2(175, 24), Vector2(210, 105), Vector2(168, 185), Vector2(70, 205)]), COAST, 2.0)
	draw_colored_polygon(PackedVector2Array([Vector2(210, 85), Vector2(405, 82), Vector2(470, 180), Vector2(420, 290), Vector2(285, 345), Vector2(215, 255)]), Color(LAND, 0.88))
	draw_polyline(PackedVector2Array([Vector2(210, 85), Vector2(405, 82), Vector2(470, 180), Vector2(420, 290), Vector2(285, 345)]), COAST, 2.0)
	draw_colored_polygon(PackedVector2Array([Vector2(60, 300), Vector2(250, 315), Vector2(285, 485), Vector2(65, 485)]), Color(LAND, 0.78))
	draw_polyline(PackedVector2Array([Vector2(60, 300), Vector2(250, 315), Vector2(285, 485)]), COAST, 2.0)
	draw_colored_polygon(PackedVector2Array([Vector2(470, 70), Vector2(595, 45), Vector2(595, 390), Vector2(480, 370)]), Color(LAND, 0.82))
	draw_polyline(PackedVector2Array([Vector2(470, 70), Vector2(480, 370), Vector2(595, 390)]), COAST, 2.0)

func _draw_currents():
	for y in [60.0, 235.0, 405.0]:
		for x in range(25, 585, 70):
			draw_arc(Vector2(x, y), 13.0, 0.15, 2.7, 12, Color(TEAL, 0.14), 1.3)

func _voyage_point(progress):
	var start = PORT_POSITIONS[from_port]
	var finish = PORT_POSITIONS[to_port]
	var middle = (start + finish) * 0.5
	var direction = finish - start
	var normal = Vector2(-direction.y, direction.x).normalized()
	middle += normal * min(48.0, direction.length() * 0.16)
	var inverse = 1.0 - float(progress)
	return inverse * inverse * start + 2.0 * inverse * float(progress) * middle + float(progress) * float(progress) * finish

func _draw_ship(position):
	draw_colored_polygon(PackedVector2Array([position + Vector2(-13, 5), position + Vector2(13, 5), position + Vector2(8, 11), position + Vector2(-8, 11)]), GOLD)
	draw_line(position + Vector2(0, 5), position + Vector2(0, -15), INK, 2.0)
	draw_colored_polygon(PackedVector2Array([position + Vector2(1, -14), position + Vector2(12, 1), position + Vector2(1, 1)]), Color(TEAL, 0.95))
	draw_circle(position + Vector2.ZERO, 20.0, Color(GOLD, 0.08))

func _panel_style():
	var style = StyleBoxFlat.new()
	style.bg_color = OCEAN
	style.border_color = Color(TEAL, 0.55)
	style.set_border_width_all(2)
	style.set_corner_radius_all(18)
	return style
