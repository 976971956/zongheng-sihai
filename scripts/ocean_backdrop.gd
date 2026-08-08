extends Control

func _ready():
	resized.connect(queue_redraw)
	queue_redraw()

func _draw():
	var area := Rect2(Vector2.ZERO, size)
	draw_rect(area, Color("07131f"))

	# Layered, low-contrast sea bands keep the screen atmospheric without
	# competing with the text-heavy interface.
	var band_colors = [Color("0a1d2c"), Color("0c2637"), Color("0d2e3e")]
	for index in range(3):
		var top := size.y * (0.58 + index * 0.11)
		var points := PackedVector2Array()
		points.append(Vector2(0, top))
		for step in range(9):
			var x := size.x * float(step) / 8.0
			var y := top + sin(float(step) * 1.35 + float(index)) * 18.0
			points.append(Vector2(x, y))
		points.append(Vector2(size.x, size.y))
		points.append(Vector2(0, size.y))
		draw_colored_polygon(points, band_colors[index])

	# Distant stars and navigation lines.
	var stars = [
		Vector2(0.08, 0.12), Vector2(0.17, 0.25), Vector2(0.30, 0.10),
		Vector2(0.45, 0.19), Vector2(0.62, 0.08), Vector2(0.76, 0.23),
		Vector2(0.91, 0.13), Vector2(0.86, 0.36), Vector2(0.53, 0.34)
	]
	for star in stars:
		var p := Vector2(star.x * size.x, star.y * size.y)
		draw_circle(p, 1.5, Color(0.55, 0.82, 0.91, 0.45))

	var compass_center := Vector2(size.x * 0.83, size.y * 0.34)
	draw_circle(compass_center, 94.0, Color(0.15, 0.50, 0.62, 0.08), false, 1.0)
	draw_circle(compass_center, 58.0, Color(0.15, 0.50, 0.62, 0.08), false, 1.0)
	draw_line(compass_center + Vector2(-118, 0), compass_center + Vector2(118, 0), Color(0.2, 0.6, 0.7, 0.07), 1.0)
	draw_line(compass_center + Vector2(0, -118), compass_center + Vector2(0, 118), Color(0.2, 0.6, 0.7, 0.07), 1.0)

