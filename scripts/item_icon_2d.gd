extends Control

const RARITY_COLORS = {
	"普通": Color("9ab3b8"), "补给": Color("69c8a8"), "酒馆食物": Color("d5a867"),
	"稀有补给": Color("62b8ef"), "远航餐食": Color("64d9c6"), "优秀": Color("54c8a8"),
	"珍稀": Color("65aee8"), "史诗": Color("bb7bea"), "传说": Color("efb95f"),
	"神话": Color("ef785f"), "唯一": Color("f6df8b"), "未知": Color("88949d")
}

var visual_kind = "item"
var visual_id = ""
var slot = ""
var rarity = "普通"
var equipped = false

func _ready():
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	if custom_minimum_size == Vector2.ZERO:
		custom_minimum_size = Vector2(76, 76)
	queue_redraw()

func configure(kind, id, item_rarity = "普通", item_slot = "", is_equipped = false):
	visual_kind = str(kind)
	visual_id = str(id)
	rarity = str(item_rarity)
	slot = str(item_slot)
	equipped = bool(is_equipped)
	name = "ItemVisual_%s" % visual_id
	set_meta("visual_kind", visual_kind)
	set_meta("visual_id", visual_id)
	set_meta("equipped", equipped)
	queue_redraw()

func rarity_color():
	return Color(RARITY_COLORS.get(rarity, Color("9ab3b8")))

func _draw():
	var accent = rarity_color()
	var box = StyleBoxFlat.new()
	box.bg_color = Color(0.025, 0.085, 0.105, 0.98)
	box.border_color = accent
	box.set_border_width_all(3 if equipped else 2)
	box.set_corner_radius_all(15)
	draw_style_box(box, Rect2(Vector2.ZERO, size))
	draw_circle(size * Vector2(0.30, 0.28), min(size.x, size.y) * 0.27, Color(accent, 0.10))
	draw_circle(size * Vector2(0.73, 0.73), min(size.x, size.y) * 0.19, Color(accent, 0.08))
	if visual_kind == "trade":
		_draw_trade_icon(accent)
	elif visual_kind == "equipment" or slot != "":
		_draw_equipment_icon(accent)
	elif visual_kind == "consumable":
		_draw_consumable_icon(accent)
	elif visual_kind == "card":
		_draw_card_icon(accent)
	elif visual_kind == "mystery":
		_draw_crate_icon(accent)
	else:
		_draw_charm(accent)
	if equipped:
		draw_circle(Vector2(size.x - 13, 13), 8, Color("48cdb8"))
		draw_line(Vector2(size.x - 17, 13), Vector2(size.x - 14, 16), Color("092f33"), 2.5, true)
		draw_line(Vector2(size.x - 14, 16), Vector2(size.x - 9, 10), Color("092f33"), 2.5, true)

func _draw_equipment_icon(accent):
	match slot:
		"weapon":
			draw_line(Vector2(21, 57), Vector2(55, 23), accent, 7, true)
			draw_colored_polygon(PackedVector2Array([Vector2(51, 18), Vector2(61, 15), Vector2(58, 25)]), accent.lightened(0.2))
			draw_line(Vector2(19, 48), Vector2(29, 58), Color("e9d8a5"), 5, true)
		"head":
			draw_arc(Vector2(38, 43), 22, PI, TAU, 28, accent, 6, true)
			draw_line(Vector2(14, 44), Vector2(62, 44), accent.lightened(0.18), 5, true)
			draw_colored_polygon(PackedVector2Array([Vector2(23, 41), Vector2(28, 22), Vector2(35, 39)]), Color(accent, 0.75))
		"body":
			draw_colored_polygon(PackedVector2Array([Vector2(23, 19), Vector2(36, 25), Vector2(40, 25), Vector2(53, 19), Vector2(61, 33), Vector2(53, 39), Vector2(49, 60), Vector2(27, 60), Vector2(23, 39), Vector2(15, 33)]), Color(accent, 0.78))
			draw_line(Vector2(38, 27), Vector2(38, 56), accent.lightened(0.25), 3, true)
		"waist":
			draw_rect(Rect2(14, 31, 48, 15), Color(accent, 0.8), true)
			draw_rect(Rect2(31, 28, 15, 21), accent.lightened(0.22), false, 4)
		"boots":
			draw_colored_polygon(PackedVector2Array([Vector2(19, 21), Vector2(35, 21), Vector2(35, 48), Vector2(48, 54), Vector2(48, 61), Vector2(17, 61)]), Color(accent, 0.82))
			draw_colored_polygon(PackedVector2Array([Vector2(43, 18), Vector2(57, 18), Vector2(57, 39), Vector2(64, 44), Vector2(64, 50), Vector2(41, 50)]), Color(accent.darkened(0.12), 0.88))
		_:
			_draw_charm(accent)

func _draw_charm(accent):
	draw_line(Vector2(24, 18), Vector2(34, 30), accent, 3, true)
	draw_line(Vector2(52, 18), Vector2(42, 30), accent, 3, true)
	draw_circle(Vector2(38, 43), 16, Color(accent, 0.68))
	draw_arc(Vector2(38, 43), 11, 0, TAU, 24, accent.lightened(0.3), 3, true)

func _draw_consumable_icon(accent):
	if visual_id in ["sea_salt_bread", "herb_fish_stew", "maltese_stew"]:
		draw_arc(Vector2(38, 44), 22, 0.1, PI - 0.1, 28, accent, 6, true)
		draw_line(Vector2(18, 45), Vector2(58, 45), accent.lightened(0.18), 4, true)
		for x in [28, 38, 48]:
			draw_arc(Vector2(x, 28), 6, PI * 1.15, PI * 1.85, 10, Color("d9f2e9"), 2, true)
	else:
		draw_rect(Rect2(30, 16, 16, 10), accent.lightened(0.25), true)
		draw_colored_polygon(PackedVector2Array([Vector2(26, 26), Vector2(50, 26), Vector2(57, 58), Vector2(19, 58)]), Color(accent, 0.72))
		draw_line(Vector2(24, 43), Vector2(52, 43), Color("d7fff8"), 3, true)
		draw_line(Vector2(38, 34), Vector2(38, 52), Color("d7fff8"), 4, true)

func _draw_card_icon(accent):
	draw_colored_polygon(PackedVector2Array([Vector2(24, 16), Vector2(56, 21), Vector2(51, 61), Vector2(19, 56)]), Color(accent, 0.34))
	draw_polyline(PackedVector2Array([Vector2(24, 16), Vector2(56, 21), Vector2(51, 61), Vector2(19, 56), Vector2(24, 16)]), accent, 4, true)
	draw_circle(Vector2(38, 39), 9, accent.lightened(0.2))
	draw_arc(Vector2(38, 39), 15, 0, TAU, 24, Color(accent, 0.55), 2, true)

func _draw_crate_icon(accent):
	draw_rect(Rect2(16, 25, 46, 37), Color(accent, 0.35), true)
	draw_rect(Rect2(16, 25, 46, 37), accent, false, 4)
	draw_line(Vector2(18, 27), Vector2(60, 60), accent.lightened(0.2), 3, true)
	draw_line(Vector2(60, 27), Vector2(18, 60), accent.lightened(0.2), 3, true)
	draw_circle(Vector2(38, 42), 7, Color("f1c66d"))

func _draw_trade_icon(accent):
	match visual_id:
		"venetian_glass":
			draw_colored_polygon(PackedVector2Array([Vector2(32, 15), Vector2(45, 15), Vector2(49, 31), Vector2(58, 58), Vector2(18, 58), Vector2(27, 31)]), Color("71d8dc", 0.55))
			draw_polyline(PackedVector2Array([Vector2(32, 15), Vector2(45, 15), Vector2(49, 31), Vector2(58, 58), Vector2(18, 58), Vector2(27, 31), Vector2(32, 15)]), accent, 3, true)
		"wool_cloth", "yangzhou_silk":
			for index in range(3):
				draw_rect(Rect2(18 + index * 7, 20 + index * 8, 40, 27), Color(accent, 0.34 + index * 0.15), true)
				draw_line(Vector2(20 + index * 7, 25 + index * 8), Vector2(55 + index * 7, 25 + index * 8), accent, 2, true)
		"olive_oil", "athens_wine":
			draw_rect(Rect2(22, 18, 33, 45), Color(accent, 0.52), true)
			draw_arc(Vector2(38.5, 19), 16.5, PI, TAU, 20, accent, 4, true)
			draw_arc(Vector2(38.5, 62), 16.5, 0, PI, 20, accent.darkened(0.15), 4, true)
			draw_line(Vector2(22, 39), Vector2(55, 39), accent.lightened(0.2), 4, true)
		"spices", "cape_gold_dust":
			draw_colored_polygon(PackedVector2Array([Vector2(23, 20), Vector2(53, 20), Vector2(61, 60), Vector2(15, 60)]), Color(accent, 0.54))
			draw_line(Vector2(23, 20), Vector2(53, 20), accent.lightened(0.22), 5, true)
			draw_circle(Vector2(38, 43), 9, accent.lightened(0.2))
		"citrus":
			draw_circle(Vector2(37, 43), 20, Color("f0a64b"))
			draw_arc(Vector2(37, 43), 14, 0, TAU, 24, Color("ffd27b"), 3, true)
			draw_line(Vector2(40, 23), Vector2(51, 16), Color("6ab57b"), 5, true)
		"quanzhou_porcelain":
			draw_colored_polygon(PackedVector2Array([Vector2(27, 17), Vector2(49, 17), Vector2(46, 28), Vector2(58, 59), Vector2(18, 59), Vector2(30, 28)]), Color("b7e7e4", 0.88))
			draw_arc(Vector2(38, 42), 15, 0, TAU, 24, Color("397da4"), 3, true)
		"amsterdam_instruments":
			draw_circle(Vector2(38, 40), 23, Color(accent, 0.28))
			draw_arc(Vector2(38, 40), 22, 0, TAU, 30, accent, 4, true)
			draw_line(Vector2(38, 40), Vector2(49, 25), Color("ef6f73"), 4, true)
			draw_circle(Vector2(38, 40), 5, accent.lightened(0.3))
		_:
			_draw_crate_icon(accent)
