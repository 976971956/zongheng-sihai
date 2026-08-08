extends Control

signal direction_changed(value)

var direction = Vector2.ZERO
var active_touch = -1
var dragging_mouse = false
var center = Vector2(90, 90)
var outer_radius = 72.0
var knob_radius = 30.0

func _ready():
	mouse_filter = Control.MOUSE_FILTER_STOP
	custom_minimum_size = Vector2(180, 180)
	queue_redraw()

func _gui_input(event):
	if event is InputEventScreenTouch:
		if event.pressed and (active_touch == -1 or active_touch == event.index):
			active_touch = event.index
			_update_direction(event.position)
			accept_event()
		elif not event.pressed and event.index == active_touch:
			active_touch = -1
			_set_direction(Vector2.ZERO)
			accept_event()
	elif event is InputEventScreenDrag and event.index == active_touch:
		_update_direction(event.position)
		accept_event()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		dragging_mouse = event.pressed
		if dragging_mouse:
			_update_direction(event.position)
		else:
			_set_direction(Vector2.ZERO)
		accept_event()
	elif event is InputEventMouseMotion and dragging_mouse:
		_update_direction(event.position)
		accept_event()

func _update_direction(pointer_position):
	var offset = pointer_position - center
	if offset.length() > outer_radius:
		offset = offset.normalized() * outer_radius
	_set_direction(offset / outer_radius)

func _set_direction(value):
	direction = value.limit_length(1.0)
	direction_changed.emit(direction)
	queue_redraw()

func _draw():
	draw_circle(center, outer_radius + 8, Color(0.01, 0.04, 0.055, 0.72))
	draw_circle(center, outer_radius, Color(0.05, 0.18, 0.20, 0.78))
	draw_arc(center, outer_radius, 0, TAU, 48, Color(0.22, 0.72, 0.68, 0.72), 3)
	for angle in [0.0, PI * 0.5, PI, PI * 1.5]:
		var from = center + Vector2.RIGHT.rotated(angle) * 48
		var to = center + Vector2.RIGHT.rotated(angle) * 62
		draw_line(from, to, Color(0.65, 0.88, 0.86, 0.55), 4)
	var knob_center = center + direction * outer_radius
	draw_circle(knob_center, knob_radius + 5, Color(0.01, 0.04, 0.05, 0.65))
	draw_circle(knob_center, knob_radius, Color(0.12, 0.50, 0.47, 0.96))
	draw_circle(knob_center - Vector2(7, 7), 8, Color(0.38, 0.79, 0.73, 0.52))
