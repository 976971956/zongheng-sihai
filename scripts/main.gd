extends Control

const INK = Color("d9edf2")
const MUTED = Color("7f9eaa")
const DIM = Color("53717c")
const TEAL = Color("38c5b5")
const GOLD = Color("f1c66d")
const RED = Color("ef6f73")
const BLUE = Color("5aa9d6")
const PANEL = Color(0.035, 0.09, 0.13, 0.94)
const PANEL_SOFT = Color(0.05, 0.13, 0.18, 0.92)
const LINE = Color(0.18, 0.39, 0.45, 0.55)
const DESKTOP_DESIGN_SIZE = Vector2i(1280, 720)
const MOBILE_DESIGN_SIZE = Vector2i(720, 1280)

var state = GameState.new()
var main_margin
var location_name_label
var location_tag_label
var chapter_label
var location_description_label
var flavor_label
var action_list
var player_name_label
var level_label
var power_label
var silver_label
var top_wallet_label
var hp_label
var hp_bar
var xp_label
var xp_bar
var attack_label
var defense_label
var speed_label
var quest_title_label
var quest_story_label
var quest_progress_label
var quest_bar
var quest_claim_button
var history_box
var modal_layer
var save_indicator
var nav_inventory_button
var team_label
var mobile_mode = false
var mobile_tab = "location"
var mobile_pages = {}
var mobile_nav_buttons = {}
var layout_rebuilding = false
var modal_allow_close = true
var journal_auto_battle_running = false

func _ready():
	mobile_mode = _should_use_mobile_layout()
	_apply_content_scale()
	var had_save = state.has_save()
	if had_save:
		state.load_game()
	_build_interface()
	refresh_ui()
	var capture_mode = "--capture-preview" in OS.get_cmdline_user_args() or "--capture-battle" in OS.get_cmdline_user_args() or "--capture-boss-guide" in OS.get_cmdline_user_args() or "--capture-mobile" in OS.get_cmdline_user_args() or "--capture-mobile-battle" in OS.get_cmdline_user_args()
	if not had_save and not capture_mode:
		call_deferred("_show_welcome")
	elif not state.active_battle.is_empty() and not capture_mode:
		call_deferred("_resume_saved_battle")
	elif state.quest_can_claim() and not capture_mode:
		call_deferred("_show_quest_completion_prompt")
	if "--capture-preview" in OS.get_cmdline_user_args():
		call_deferred("_capture_preview")
	if "--capture-battle" in OS.get_cmdline_user_args():
		call_deferred("_capture_battle_preview")
	if "--capture-boss-guide" in OS.get_cmdline_user_args():
		call_deferred("_capture_boss_guide_preview")
	if "--capture-mobile" in OS.get_cmdline_user_args():
		call_deferred("_capture_mobile_preview")
	if "--capture-mobile-battle" in OS.get_cmdline_user_args():
		call_deferred("_capture_mobile_battle_preview")
	get_tree().root.size_changed.connect(_on_window_size_changed)

func _should_use_mobile_layout():
	var window_size = DisplayServer.window_get_size()
	return window_size.y > window_size.x or window_size.x < 900

func _apply_content_scale():
	get_window().content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	get_window().content_scale_aspect = Window.CONTENT_SCALE_ASPECT_EXPAND
	get_window().content_scale_size = MOBILE_DESIGN_SIZE if mobile_mode else DESKTOP_DESIGN_SIZE

func _on_window_size_changed():
	if layout_rebuilding:
		return
	var next_mobile_mode = _should_use_mobile_layout()
	if next_mobile_mode == mobile_mode:
		return
	layout_rebuilding = true
	mobile_mode = next_mobile_mode
	_apply_content_scale()
	_close_modal()
	if is_instance_valid(main_margin):
		main_margin.free()
	_build_interface()
	refresh_ui()
	layout_rebuilding = false

func _capture_preview():
	# Developer-only visual QA path. It is inert during normal play.
	await get_tree().process_frame
	await get_tree().process_frame
	_close_modal()
	await get_tree().process_frame
	await get_tree().process_frame
	var preview = get_viewport().get_texture().get_image()
	preview.save_png("res://preview.png")
	get_tree().quit()

func _capture_battle_preview():
	# Isolated visual fixture: direct state assignment avoids touching the save.
	state.new_game()
	state.player.location = "venice_north_gate"
	state.active_battle = {
		"enemy_id": "drunk_sailor", "enemy_hp": 27, "enemy_max_hp": 42,
		"round": 3, "log": [
			"第1回合｜你向喝醉的水手发起攻击，体力-11。",
			"第1回合｜喝醉的水手向你发起攻击，体力-5。",
			"第2回合｜气贯全身，致命一击！喝醉的水手体力-15。"
		]
	}
	refresh_ui()
	_resume_saved_battle()
	await get_tree().process_frame
	await get_tree().process_frame
	var image = get_viewport().get_texture().get_image()
	image.save_png("res://battle_preview.png")
	get_tree().quit()

func _capture_boss_guide_preview():
	state.new_game()
	state.player.level = 4
	state.player.location = "training_dungeon_4"
	state.inventory["warrior_blade"] = 1
	state.inventory["warrior_coat"] = 1
	state.pet = GameData.PETS.moon_tiger.duplicate(true)
	state.party_members = ["见习水手·卢卡"]
	state.player.hp = state.get_stats().max_hp
	refresh_ui()
	_show_boss_preparation()
	await get_tree().process_frame
	await get_tree().process_frame
	var image = get_viewport().get_texture().get_image()
	image.save_png("res://boss_guide_preview.png")
	get_tree().quit()

func _capture_mobile_preview():
	state.new_game()
	refresh_ui()
	await get_tree().create_timer(0.6).timeout
	_close_modal()
	var image = get_viewport().get_texture().get_image()
	image.save_png("res://mobile_preview.png")
	get_tree().quit()

func _capture_mobile_battle_preview():
	state.new_game()
	state.player.location = "venice_north_gate"
	state.player.hp = 78
	state.statuses = {"中毒": 2}
	state.active_battle = {
		"enemy_id": "drunk_sailor", "enemy_hp": 27, "enemy_max_hp": 42,
		"round": 3, "log": []
	}
	refresh_ui()
	var view = state.get_battle_view()
	view.logs = [
		"第1回合｜你向喝醉的水手发起攻击，体力-11。",
		"第2回合｜你陷入中毒（2回合）。",
		"状态伤害｜毒素发作，你的体力-4。"
	]
	_show_battle_screen(view)
	await get_tree().create_timer(0.6).timeout
	var image = get_viewport().get_texture().get_image()
	image.save_png("res://mobile_battle_preview.png")
	get_tree().quit()

func _unhandled_key_input(event):
	if not event.pressed:
		return
	if not state.active_battle.is_empty() and event.keycode in [KEY_I, KEY_C, KEY_Q, KEY_ESCAPE]:
		_show_toast("战斗仍在进行，请使用攻击、药品或撤退。", false)
		return
	if event.keycode == KEY_I:
		_open_inventory()
	elif event.keycode == KEY_C:
		_open_character()
	elif event.keycode == KEY_Q:
		_open_quest_detail()
	elif event.keycode == KEY_ESCAPE and is_instance_valid(modal_layer):
		if modal_allow_close:
			_close_modal()
		else:
			_show_toast("请先完成当前领奖或战斗操作。", false)

func _build_interface():
	if mobile_mode:
		_build_mobile_interface()
	else:
		_build_desktop_interface()

func _build_desktop_interface():
	mobile_pages = {}
	mobile_nav_buttons = {}
	main_margin = MarginContainer.new()
	main_margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	main_margin.add_theme_constant_override("margin_left", 22)
	main_margin.add_theme_constant_override("margin_right", 22)
	main_margin.add_theme_constant_override("margin_top", 18)
	main_margin.add_theme_constant_override("margin_bottom", 18)
	add_child(main_margin)

	var page = VBoxContainer.new()
	page.add_theme_constant_override("separation", 14)
	main_margin.add_child(page)

	page.add_child(_build_topbar())

	var columns = HBoxContainer.new()
	columns.size_flags_vertical = Control.SIZE_EXPAND_FILL
	columns.add_theme_constant_override("separation", 14)
	page.add_child(columns)

	columns.add_child(_build_profile_panel())
	columns.add_child(_build_location_panel())
	columns.add_child(_build_quest_panel())

	page.add_child(_build_navigation())

func _build_mobile_interface():
	main_margin = MarginContainer.new()
	main_margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var safe = _mobile_safe_insets()
	main_margin.add_theme_constant_override("margin_left", max(12, int(safe.x)))
	main_margin.add_theme_constant_override("margin_top", max(12, int(safe.y)))
	main_margin.add_theme_constant_override("margin_right", max(12, int(safe.z)))
	main_margin.add_theme_constant_override("margin_bottom", max(12, int(safe.w)))
	add_child(main_margin)

	var page = VBoxContainer.new()
	page.add_theme_constant_override("separation", 10)
	main_margin.add_child(page)
	page.add_child(_build_mobile_topbar())

	var page_host = Control.new()
	page_host.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	page_host.size_flags_vertical = Control.SIZE_EXPAND_FILL
	page_host.clip_contents = true
	page.add_child(page_host)
	mobile_pages = {
		"profile": _build_profile_panel(),
		"location": _build_location_panel(),
		"quest": _build_quest_panel()
	}
	for page_id in mobile_pages:
		var panel = mobile_pages[page_id]
		panel.custom_minimum_size.x = 0
		panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		panel.visible = page_id == mobile_tab
		page_host.add_child(panel)
	page.add_child(_build_mobile_navigation())

func _mobile_safe_insets():
	# Desktop test windows can sit anywhere on a multi-monitor desktop, while
	# mobile safe-area coordinates describe the fullscreen device surface.
	if not OS.get_name() in ["Android", "iOS"]:
		return Vector4.ZERO
	var window_size = DisplayServer.window_get_size()
	var safe_area = DisplayServer.get_display_safe_area()
	if window_size.x <= 0 or window_size.y <= 0 or safe_area.size.x <= 0 or safe_area.size.y <= 0:
		return Vector4.ZERO
	var scale = float(MOBILE_DESIGN_SIZE.x) / float(window_size.x)
	var right = max(0, window_size.x - safe_area.end.x)
	var bottom = max(0, window_size.y - safe_area.end.y)
	return Vector4(safe_area.position.x * scale, safe_area.position.y * scale, right * scale, bottom * scale)

func _build_mobile_topbar():
	var panel = _panel_container(PANEL, 16, LINE, 1)
	panel.custom_minimum_size.y = 68
	var margin = _inside_margin(13, 9)
	panel.add_child(margin)
	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	margin.add_child(row)

	var sigil = Label.new()
	sigil.text = "四海"
	sigil.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sigil.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	sigil.custom_minimum_size = Vector2(44, 44)
	sigil.add_theme_font_size_override("font_size", 15)
	sigil.add_theme_color_override("font_color", Color("071820"))
	sigil.add_theme_stylebox_override("normal", _style(TEAL, 11))
	row.add_child(sigil)

	var title_stack = VBoxContainer.new()
	title_stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_stack.add_theme_constant_override("separation", 0)
	row.add_child(title_stack)
	title_stack.add_child(_label("纵横四海", 22, INK))
	chapter_label = _label("", 11, MUTED)
	chapter_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	title_stack.add_child(chapter_label)

	save_indicator = _label("已保存", 10, TEAL)
	row.add_child(save_indicator)
	top_wallet_label = _label("银币 0", 11, GOLD)
	top_wallet_label.custom_minimum_size.x = 76
	top_wallet_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	top_wallet_label.add_theme_stylebox_override("normal", _style(Color(0.18, 0.13, 0.03, 0.88), 9, Color(GOLD, 0.52), 1, 6))
	row.add_child(top_wallet_label)
	var world_button = _button("2D", "active")
	world_button.custom_minimum_size = Vector2(58, 48)
	world_button.tooltip_text = "返回2D世界"
	world_button.pressed.connect(_open_2d_world)
	row.add_child(world_button)
	var guide_button = _button("?", "ghost")
	guide_button.custom_minimum_size = Vector2(48, 48)
	guide_button.tooltip_text = "航海指南"
	guide_button.pressed.connect(_show_welcome)
	row.add_child(guide_button)
	return panel

func _build_mobile_navigation():
	var panel = _panel_container(PANEL, 16, LINE, 1)
	panel.custom_minimum_size.y = 76
	var margin = _inside_margin(8, 7)
	panel.add_child(margin)
	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	margin.add_child(row)
	mobile_nav_buttons = {}
	for entry in [
		{"id": "profile", "text": "◇\n人物"},
		{"id": "location", "text": "◎\n地点"},
		{"id": "quest", "text": "≡\n任务"}
	]:
		var button = _button(entry.text, "ghost")
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.custom_minimum_size.y = 58
		button.pressed.connect(_switch_mobile_tab.bind(entry.id))
		row.add_child(button)
		mobile_nav_buttons[entry.id] = button
	nav_inventory_button = _button("□\n背包", "ghost")
	nav_inventory_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	nav_inventory_button.custom_minimum_size.y = 58
	nav_inventory_button.pressed.connect(_open_inventory)
	row.add_child(nav_inventory_button)
	_update_mobile_navigation()
	return panel

func _switch_mobile_tab(tab_id):
	if not mobile_mode or not mobile_pages.has(tab_id):
		return
	mobile_tab = tab_id
	for page_id in mobile_pages:
		mobile_pages[page_id].visible = page_id == mobile_tab
	_update_mobile_navigation()

func _update_mobile_navigation():
	for tab_id in mobile_nav_buttons:
		var button = mobile_nav_buttons[tab_id]
		var active = tab_id == mobile_tab
		button.add_theme_color_override("font_color", TEAL if active else INK)
		button.add_theme_stylebox_override("normal", _style(Color(0.06, 0.29, 0.28, 0.95) if active else Color(0.03, 0.10, 0.13, 0.6), 10, Color(TEAL, 0.75) if active else Color(0.14, 0.31, 0.35, 0.65), 1, 7))

func _build_topbar():
	var panel = _panel_container(PANEL, 18, LINE, 1)
	panel.custom_minimum_size.y = 76
	var margin = _inside_margin(18, 12)
	panel.add_child(margin)
	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 13)
	margin.add_child(row)

	var sigil = Label.new()
	sigil.text = "四海"
	sigil.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sigil.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	sigil.custom_minimum_size = Vector2(48, 48)
	sigil.add_theme_font_size_override("font_size", 16)
	sigil.add_theme_color_override("font_color", Color("071820"))
	sigil.add_theme_stylebox_override("normal", _style(TEAL, 12))
	row.add_child(sigil)

	var title_stack = VBoxContainer.new()
	title_stack.add_theme_constant_override("separation", 1)
	row.add_child(title_stack)
	var title = _label("纵横四海", 25, INK)
	title_stack.add_child(title)
	chapter_label = _label("", 12, MUTED)
	title_stack.add_child(chapter_label)

	var spacer = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(spacer)

	var live_chip = Label.new()
	live_chip.text = "  单机航程  "
	live_chip.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	live_chip.add_theme_font_size_override("font_size", 12)
	live_chip.add_theme_color_override("font_color", TEAL)
	live_chip.add_theme_stylebox_override("normal", _style(Color(0.08, 0.28, 0.27, 0.75), 10, Color(0.17, 0.58, 0.53, 0.6), 1))
	row.add_child(live_chip)

	save_indicator = _label("已自动保存", 12, MUTED)
	save_indicator.custom_minimum_size.x = 80
	row.add_child(save_indicator)
	return panel

func _build_profile_panel():
	var panel = _panel_container(PANEL, 18, LINE, 1)
	panel.custom_minimum_size.x = 246
	var margin = _inside_margin(17, 17)
	panel.add_child(margin)
	var box = VBoxContainer.new()
	box.add_theme_constant_override("separation", 11)
	margin.add_child(box)

	box.add_child(_section_heading("航者档案", "PLAYER"))

	var identity = HBoxContainer.new()
	identity.add_theme_constant_override("separation", 12)
	box.add_child(identity)
	var portrait = Label.new()
	portrait.text = "航"
	portrait.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	portrait.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	portrait.custom_minimum_size = Vector2(58, 58)
	portrait.add_theme_font_size_override("font_size", 23)
	portrait.add_theme_color_override("font_color", GOLD)
	portrait.add_theme_stylebox_override("normal", _style(Color("102934"), 14, Color(0.55, 0.43, 0.20, 0.9), 1))
	identity.add_child(portrait)
	var identity_text = VBoxContainer.new()
	identity_text.add_theme_constant_override("separation", 3)
	identity.add_child(identity_text)
	player_name_label = _label("失忆的航者", 17, INK)
	identity_text.add_child(player_name_label)
	level_label = _label("Lv.1 · 见习者", 12, TEAL)
	identity_text.add_child(level_label)
	power_label = _label("战力 0", 12, MUTED)
	identity_text.add_child(power_label)

	box.add_child(_thin_line())

	hp_label = _label("体力", 12, MUTED)
	box.add_child(hp_label)
	hp_bar = _progress_bar(RED)
	box.add_child(hp_bar)
	xp_label = _label("经验", 12, MUTED)
	box.add_child(xp_label)
	xp_bar = _progress_bar(TEAL)
	box.add_child(xp_bar)

	box.add_child(_thin_line())
	box.add_child(_small_caption("基础属性"))
	attack_label = _stat_row(box, "攻击", "0", GOLD)
	defense_label = _stat_row(box, "防御", "0", BLUE)
	speed_label = _stat_row(box, "敏捷", "0", TEAL)
	silver_label = _stat_row(box, "银币", "0", Color("e8d49b"))
	team_label = _label("独自冒险 · 无宠物", 11, DIM)
	team_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(team_label)
	if mobile_mode:
		var equipment_button = _button("查看角色装备与套装", "ghost")
		equipment_button.pressed.connect(_open_character)
		box.add_child(equipment_button)

	var spacer = Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(spacer)

	var tip = Label.new()
	tip.text = "提示｜每点一次攻击只推进一回合\n可自动攻击，也可在战斗中用药"
	tip.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tip.add_theme_font_size_override("font_size", 11)
	tip.add_theme_color_override("font_color", DIM)
	tip.add_theme_stylebox_override("normal", _style(Color(0.04, 0.12, 0.16, 0.85), 10, LINE, 1, 10))
	box.add_child(tip)
	return panel

func _build_location_panel():
	var panel = _panel_container(PANEL, 18, LINE, 1)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.custom_minimum_size.x = 560
	var margin = _inside_margin(20, 17)
	panel.add_child(margin)
	var box = VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	margin.add_child(box)

	var location_header = HBoxContainer.new()
	location_header.add_theme_constant_override("separation", 10)
	box.add_child(location_header)
	location_tag_label = Label.new()
	location_tag_label.text = "安全区"
	location_tag_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	location_tag_label.add_theme_font_size_override("font_size", 11)
	location_tag_label.add_theme_color_override("font_color", TEAL)
	location_tag_label.add_theme_stylebox_override("normal", _style(Color(0.06, 0.25, 0.25, 0.8), 8, Color(0.15, 0.48, 0.46, 0.7), 1, 7))
	location_header.add_child(location_tag_label)
	location_name_label = _label("", 24, INK)
	location_header.add_child(location_name_label)

	location_description_label = _label("", 14, Color("b7cfd5"))
	location_description_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	location_description_label.custom_minimum_size.y = 46
	box.add_child(location_description_label)

	var flavor_panel = _panel_container(Color(0.035, 0.15, 0.19, 0.8), 11, Color(0.12, 0.42, 0.46, 0.55), 1)
	var flavor_margin = _inside_margin(12, 9)
	flavor_panel.add_child(flavor_margin)
	flavor_label = _label("", 12, Color("8ecbd0"))
	flavor_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	flavor_margin.add_child(flavor_label)
	box.add_child(flavor_panel)

	var action_header = HBoxContainer.new()
	box.add_child(action_header)
	action_header.add_child(_label("当前可行动作", 14, INK))
	var flex = Control.new()
	flex.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	action_header.add_child(flex)
	var keyboard = _label("选择行动以推进旅程", 11, DIM)
	if mobile_mode:
		keyboard.text = "轻触行动"
	action_header.add_child(keyboard)

	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	box.add_child(scroll)
	action_list = VBoxContainer.new()
	action_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	action_list.add_theme_constant_override("separation", 9)
	scroll.add_child(action_list)
	return panel

func _build_quest_panel():
	var panel = _panel_container(PANEL, 18, LINE, 1)
	panel.custom_minimum_size.x = 292
	var margin = _inside_margin(17, 17)
	panel.add_child(margin)
	var box = VBoxContainer.new()
	box.add_theme_constant_override("separation", 11)
	margin.add_child(box)

	box.add_child(_section_heading("航海日志", "QUEST"))

	var quest_card = _panel_container(Color(0.055, 0.15, 0.19, 0.88), 13, Color(0.16, 0.48, 0.50, 0.65), 1)
	var quest_margin = _inside_margin(13, 12)
	quest_card.add_child(quest_margin)
	var quest_box = VBoxContainer.new()
	quest_box.add_theme_constant_override("separation", 8)
	quest_margin.add_child(quest_box)
	quest_title_label = _label("", 16, GOLD)
	quest_title_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	quest_box.add_child(quest_title_label)
	quest_story_label = _label("", 12, Color("a9c2c8"))
	quest_story_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	quest_story_label.custom_minimum_size.y = 52
	quest_box.add_child(quest_story_label)
	quest_progress_label = _label("", 11, MUTED)
	quest_box.add_child(quest_progress_label)
	quest_bar = _progress_bar(GOLD)
	quest_bar.custom_minimum_size.y = 6
	quest_box.add_child(quest_bar)
	quest_claim_button = _button("领取任务奖励", "gold")
	quest_claim_button.pressed.connect(_on_claim_quest)
	quest_box.add_child(quest_claim_button)
	box.add_child(quest_card)

	box.add_child(_small_caption("最近发生"))
	var history_scroll = ScrollContainer.new()
	history_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	history_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	box.add_child(history_scroll)
	history_box = VBoxContainer.new()
	history_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	history_box.add_theme_constant_override("separation", 8)
	history_scroll.add_child(history_box)

	var detail_button = _button("查看完整任务说明", "ghost")
	detail_button.pressed.connect(_open_quest_detail)
	box.add_child(detail_button)
	return panel

func _build_navigation():
	var panel = _panel_container(PANEL, 16, LINE, 1)
	panel.custom_minimum_size.y = 58
	var margin = _inside_margin(12, 9)
	panel.add_child(margin)
	var row = HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 10)
	margin.add_child(row)

	var location_button = _button("◎ 2D世界", "active")
	location_button.tooltip_text = "返回2D探索地图"
	location_button.pressed.connect(_open_2d_world)
	row.add_child(location_button)
	nav_inventory_button = _button("□  背包  [I]", "ghost")
	nav_inventory_button.pressed.connect(_open_inventory)
	row.add_child(nav_inventory_button)
	var character_button = _button("◇  角色  [C]", "ghost")
	character_button.pressed.connect(_open_character)
	row.add_child(character_button)
	var quest_button = _button("≡  任务  [Q]", "ghost")
	quest_button.pressed.connect(_open_quest_detail)
	row.add_child(quest_button)
	var guide_button = _button("?  航海指南", "ghost")
	guide_button.pressed.connect(_show_welcome)
	row.add_child(guide_button)
	return panel

func refresh_ui():
	var stats = state.get_stats()
	var location = GameData.LOCATIONS[state.player.location]
	AudioDirector.set_region(_audio_region_for_location(str(state.player.location)))
	chapter_label.text = location.chapter
	location_name_label.text = location.name
	location_tag_label.text = "  %s  " % location.tag
	location_description_label.text = location.description
	flavor_label.text = "航海札记｜%s" % location.flavor

	var level = int(state.player.level)
	var rank_name = "见习者"
	if level >= 3:
		rank_name = "逐潮者"
	if level >= 5:
		rank_name = "威尼斯之星"
	level_label.text = "Lv.%d · %s" % [level, rank_name]
	player_name_label.text = str(state.player.name)
	power_label.text = "战力 %d" % state.get_power()
	silver_label.text = str(int(state.player.silver))
	if is_instance_valid(top_wallet_label):
		top_wallet_label.text = "银币 %d" % int(state.player.silver)
	attack_label.text = str(int(stats.attack))
	defense_label.text = str(int(stats.defense))
	speed_label.text = str(int(stats.speed))
	hp_label.text = "体力  %d / %d" % [int(state.player.hp), int(stats.max_hp)]
	hp_bar.max_value = int(stats.max_hp)
	hp_bar.value = int(state.player.hp)
	if level >= GameData.MAX_LEVEL:
		xp_label.text = "经验  MAX"
		xp_bar.max_value = 1
		xp_bar.value = 1
	else:
		var needed = GameData.xp_needed(level)
		xp_label.text = "经验  %d / %d" % [int(state.player.xp), needed]
		xp_bar.max_value = needed
		xp_bar.value = int(state.player.xp)
	var team_text = "独自冒险"
	if not state.party_members.is_empty():
		team_text = "队伍2人 · 攻防+5%"
	var pet_text = "无宠物" if state.pet.is_empty() else "宠物：%s" % state.pet.name
	team_label.text = "%s · %s · 掉落+%d%%" % [team_text, pet_text, int(round(float(stats.drop_bonus) * 100.0))]

	_refresh_actions(location)
	_refresh_quest()
	_refresh_history()
	var item_total = 0
	for count in state.inventory.values():
		item_total += int(count)
	if mobile_mode:
		nav_inventory_button.text = "□\n背包 %d" % item_total
		save_indicator.text = "已保存"
		_update_mobile_navigation()
	else:
		nav_inventory_button.text = "□  背包 %d  [I]" % item_total
		save_indicator.text = "已自动保存"

func _open_2d_world():
	state.save_game()
	get_tree().change_scene_to_file("res://scenes/world_2d.tscn")

func _audio_region_for_location(location_id):
	if location_id.begins_with("training_dungeon_"):
		return "dungeon"
	if location_id.begins_with("black_sail_"):
		return "black_sail"
	if location_id.begins_with("white_whale_"):
		return "white_whale"
	if location_id.begins_with("legacy_"):
		return "legacy"
	if location_id in ["residential_quarter", "venice_mine", "venice_back_hill", "venice_wildwood", "venice_north_gate"]:
		return "field"
	return "city"

func _refresh_actions(location):
	_clear_children(action_list)
	if not state.active_voyage.is_empty():
		var voyage = state.active_voyage
		action_list.add_child(_small_caption("海燕号正在%s航行" % GameData.SEA_REGIONS[str(voyage.region)].name))
		action_list.add_child(_wide_action("返回2D海域继续驾驶", "%s → %s · 船位与海上事件均已保存" % [GameData.TRADE_PORTS[str(voyage.origin)].name, GameData.TRADE_PORTS[str(voyage.destination)].name], "sea"))
		return

	if not location.npcs.is_empty():
		action_list.add_child(_small_caption("附近人物"))
		for npc_id in location.npcs:
			action_list.add_child(_npc_action_card(npc_id))

	if not location.enemies.is_empty():
		action_list.add_child(_small_caption("附近的敌人"))
		for enemy_id in location.enemies:
			action_list.add_child(_enemy_action_card(enemy_id))

	if not location.services.is_empty():
		action_list.add_child(_small_caption("地点服务"))
		if "rest" in location.services:
			action_list.add_child(_wide_action("在旅店休息", "恢复全部体力与状态 · 免费", "rest"))
		if "shop" in location.services:
			action_list.add_child(_wide_action("海风市场补给铺", "购买奶瓶与旅行补给", "shop"))
		if "identify" in location.services:
			var unknown_count = int(state.inventory.get("unknown_equipment", 0))
			action_list.add_child(_wide_action("鉴定未知道具", "持有%d件 · 每件5银币" % unknown_count, "identify"))
		if "party" in location.services:
			action_list.add_child(_wide_action("酒馆组队", "2人队伍可获得5%攻防加成", "party"))
		if "city_map" in location.services:
			action_list.add_child(_wide_action("查看城内地图", "威尼斯地点与功能一览", "city_map"))
		if "harbor" in location.services:
			var harbor_hint = "完成四层试炼后开放远洋贸易"
			if state.is_trade_unlocked():
				harbor_hint = "%s · 货舱%d/%d · 第%d日" % [state.ship.name, state.cargo_used(), state.cargo_capacity(), state.trade_day]
			action_list.add_child(_wide_action("港口贸易与航行", harbor_hint, "harbor"))

	if not location.exits.is_empty():
		action_list.add_child(_small_caption("可前往"))
	for edge in location.exits:
		var label = "%s｜%s" % [edge.get("direction", "路"), edge.label]
		var hint = edge.hint
		var exit_lock = state.get_exit_lock(edge)
		var locked = exit_lock != ""
		if locked:
			hint = "未解锁｜%s" % exit_lock
		if int(edge.get("level", 1)) > int(state.player.level):
			hint += " · 需要 Lv.%d" % int(edge.level)
		action_list.add_child(_wide_action(label, hint, "move", edge.to, int(edge.get("level", 1)), locked))

func _npc_action_card(npc_id):
	var npc = GameData.NPCS[npc_id]
	var card = _panel_container(PANEL_SOFT, 12, Color(0.14, 0.34, 0.39, 0.65), 1)
	var margin = _inside_margin(13, 10)
	card.add_child(margin)
	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	margin.add_child(row)
	var badge = Label.new()
	badge.text = "人"
	badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	badge.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	badge.custom_minimum_size = Vector2(42, 42)
	badge.add_theme_font_size_override("font_size", 14)
	badge.add_theme_color_override("font_color", TEAL)
	badge.add_theme_stylebox_override("normal", _style(Color("102a35"), 10, LINE, 1))
	row.add_child(badge)
	var text_box = VBoxContainer.new()
	text_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_box.add_theme_constant_override("separation", 2)
	row.add_child(text_box)
	text_box.add_child(_label(npc.name, 14, INK))
	text_box.add_child(_label(npc.role, 10, MUTED))
	var service = str(npc.get("service", ""))
	if service in ["jewelry_shop", "tavern_shop"]:
		var shop_button = _button("珠宝" if service == "jewelry_shop" else "食物", "gold")
		shop_button.custom_minimum_size.x = 82
		shop_button.pressed.connect(_open_vendor_shop.bind(str(npc_id)))
		row.add_child(shop_button)
	var talk_button = _button("交谈", "primary")
	talk_button.custom_minimum_size.x = 82
	talk_button.pressed.connect(_on_talk.bind(npc_id))
	row.add_child(talk_button)
	return card

func _enemy_action_card(enemy_id):
	var enemy = GameData.ENEMIES[enemy_id]
	var card = _panel_container(PANEL_SOFT, 12, Color(0.14, 0.34, 0.39, 0.65), 1)
	var margin = _inside_margin(13, 10)
	card.add_child(margin)
	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	margin.add_child(row)

	var badge = Label.new()
	badge.text = str(enemy.level)
	badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	badge.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	badge.custom_minimum_size = Vector2(42, 42)
	badge.add_theme_font_size_override("font_size", 14)
	badge.add_theme_color_override("font_color", GOLD if enemy.rank != "普通" else INK)
	badge.add_theme_stylebox_override("normal", _style(Color("102a35"), 10, LINE, 1))
	row.add_child(badge)

	var text_box = VBoxContainer.new()
	text_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_box.add_theme_constant_override("separation", 2)
	row.add_child(text_box)
	var name_color = GOLD if enemy.rank in ["首领", "副本 Boss"] else INK
	text_box.add_child(_label(enemy.name, 14, name_color))
	text_box.add_child(_label("%s · 体力 %d · 攻击 %d · 防御 %d" % [enemy.rank, enemy.hp, enemy.attack, enemy.defense], 10, MUTED))

	var respawn_remaining = state.enemy_respawn_remaining(enemy_id)
	var fight_text = "检查刷新 · %d秒" % int(ceil(respawn_remaining)) if respawn_remaining > 0.0 else "挑战"
	var fight_button = _button(fight_text, "ghost" if respawn_remaining > 0.0 else ("danger" if enemy.rank in ["首领", "副本 Boss"] else "primary"))
	fight_button.custom_minimum_size.x = 82
	fight_button.pressed.connect(_on_fight.bind(enemy_id))
	row.add_child(fight_button)
	return card

func _wide_action(title, hint, kind, value = "", required_level = 1, locked = false):
	var button = Button.new()
	button.custom_minimum_size.y = 66 if mobile_mode else 53
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.text = "  %s\n  %s" % [title, hint]
	button.add_theme_font_size_override("font_size", 12)
	button.add_theme_color_override("font_color", INK)
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.add_theme_color_override("font_disabled_color", DIM)
	button.add_theme_stylebox_override("normal", _style(Color(0.045, 0.13, 0.17, 0.85), 10, Color(0.12, 0.31, 0.36, 0.65), 1, 8))
	button.add_theme_stylebox_override("hover", _style(Color(0.065, 0.22, 0.25, 0.95), 10, Color(0.18, 0.58, 0.56, 0.8), 1, 8))
	button.add_theme_stylebox_override("pressed", _style(Color(0.04, 0.27, 0.27, 1.0), 10, TEAL, 1, 8))
	button.add_theme_stylebox_override("disabled", _style(Color(0.035, 0.08, 0.10, 0.75), 10, Color(0.1, 0.18, 0.20, 0.5), 1, 8))
	if kind == "move":
		button.disabled = int(state.player.level) < required_level or locked
		button.pressed.connect(_on_move.bind(value))
	elif kind == "rest":
		button.pressed.connect(_on_rest)
	elif kind == "shop":
		button.pressed.connect(_open_shop)
	elif kind == "identify":
		button.disabled = int(state.inventory.get("unknown_equipment", 0)) <= 0
		button.pressed.connect(_identify_from_market)
	elif kind == "party":
		button.pressed.connect(_open_party)
	elif kind == "city_map":
		button.pressed.connect(_open_city_map)
	elif kind == "harbor":
		button.pressed.connect(_open_harbor)
	elif kind == "sea":
		button.pressed.connect(_open_2d_world)
	return button

func _refresh_quest():
	var quest = state.get_current_quest()
	if quest.is_empty():
		quest_title_label.text = "远洋贸易已开启"
		quest_story_label.text = "前往任一港口，比较每日价格，在威尼斯、拉古萨与亚历山大之间低买高卖。"
		quest_progress_label.text = "章节完成"
		quest_bar.max_value = 1
		quest_bar.value = 1
		quest_claim_button.text = "主线完成 · 自由贸易"
		quest_claim_button.disabled = true
		return
	quest_title_label.text = "主线｜%s" % quest.title
	quest_story_label.text = quest.story
	var objective = quest.objective
	quest_progress_label.text = "%s  %d / %d" % [_objective_text(objective), state.quest_progress, int(objective.need)]
	quest_bar.max_value = int(objective.need)
	quest_bar.value = state.quest_progress
	quest_claim_button.disabled = not state.quest_can_claim()
	quest_claim_button.text = "领取任务奖励" if state.quest_can_claim() else "任务进行中"

func _refresh_history():
	_clear_children(history_box)
	for index in range(state.message_history.size()):
		var row = HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		var dot = Label.new()
		dot.text = "•"
		dot.add_theme_color_override("font_color", TEAL if index == 0 else DIM)
		row.add_child(dot)
		var entry = _label(str(state.message_history[index]), 11, MUTED if index > 0 else Color("a9cbd0"))
		entry.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		entry.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(entry)
		history_box.add_child(row)

func _on_move(destination):
	var result = state.move_to(destination)
	_show_toast(result.message, result.ok)
	refresh_ui()
	if bool(result.get("quest_completed", false)):
		call_deferred("_show_quest_completion_prompt")

func _on_rest():
	var result = state.rest()
	if bool(result.ok):
		AudioDirector.play_sfx("heal")
	_show_toast(result.message, result.ok)
	refresh_ui()

func _on_talk(npc_id):
	var result = state.talk_to(npc_id)
	AudioDirector.play_sfx("interact")
	refresh_ui()
	if not result.ok:
		_show_toast(result.message, false)
		return
	var content = VBoxContainer.new()
	content.add_theme_constant_override("separation", 14)
	content.add_child(_label(result.npc_name, 20, GOLD))
	var dialogue = _label(result.message, 14, Color("b7cfd5"))
	dialogue.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dialogue.add_theme_stylebox_override("normal", _style(Color(0.04, 0.16, 0.19, 0.82), 12, LINE, 1, 15))
	content.add_child(dialogue)
	if bool(result.get("quest_completed", false)):
		content.add_child(_label("任务目标已完成，结束交谈后将自动打开领奖页面。", 12, TEAL))
	var close = _button("结束交谈", "primary")
	if bool(result.get("quest_completed", false)):
		close.pressed.connect(_close_then_show_quest_completion)
	else:
		close.pressed.connect(_close_modal)
	content.add_child(close)
	_open_modal("人物对话", content, Vector2(640, 390))

func _on_fight(enemy_id):
	if enemy_id == "vermilion_phantom" and _boss_loadout_missing():
		_show_boss_preparation()
		return
	_start_fight(enemy_id)

func _start_fight(enemy_id):
	var result = state.start_battle(enemy_id)
	refresh_ui()
	if not result.ok:
		_show_toast(result.message, false)
		return
	_show_battle_screen(result)

func _on_claim_quest():
	var result = state.claim_quest()
	if bool(result.ok):
		AudioDirector.play_sfx("reward")
	refresh_ui()
	_show_toast(result.message, result.ok)
	if result.ok:
		call_deferred("_handle_claim_result", result)

func _close_then_show_quest_completion():
	_close_modal()
	call_deferred("_show_quest_completion_prompt")

func _show_quest_completion_prompt():
	if not state.quest_can_claim():
		return
	var quest = state.get_current_quest()
	var content = VBoxContainer.new()
	content.add_theme_constant_override("separation", 13)
	content.add_child(_label("任务目标已达成", 21, GOLD))
	content.add_child(_label("「%s」" % quest.title, 17, INK))
	var done = _label("%s  %d / %d" % [_objective_text(quest.objective), state.quest_progress, int(quest.objective.need)], 13, TEAL)
	done.add_theme_stylebox_override("normal", _style(Color(0.04, 0.18, 0.18, 0.86), 11, Color(TEAL, 0.5), 1, 14))
	content.add_child(done)
	content.add_child(_label("奖励：%s" % _quest_reward_text(quest.reward), 13, GOLD))
	var claim = _button("领取全部奖励", "gold")
	claim.pressed.connect(_claim_from_completion_prompt)
	content.add_child(claim)
	_open_modal("任务完成", content, Vector2(620, 400))

func _claim_from_completion_prompt():
	_close_modal()
	var result = state.claim_quest()
	if bool(result.ok):
		AudioDirector.play_sfx("reward")
	refresh_ui()
	_show_toast(result.message, result.ok)
	if result.ok:
		call_deferred("_handle_claim_result", result)

func _handle_claim_result(result):
	var reward_item = str(result.get("reward_item", ""))
	if reward_item != "" and GameData.ITEMS.has(reward_item) and GameData.ITEMS[reward_item].type == "equipment":
		_show_reward_equip_prompt(reward_item, result)
		return
	_show_reward_summary(result)

func _show_reward_summary(result):
	var content = VBoxContainer.new()
	content.add_theme_constant_override("separation", 13)
	content.add_child(_label("奖励已领取", 21, GOLD))
	var reward = _label(str(result.get("reward_text", "奖励已放入背包")), 15, TEAL)
	reward.add_theme_stylebox_override("normal", _style(Color(0.04, 0.18, 0.18, 0.86), 11, Color(GOLD, 0.45), 1, 14))
	content.add_child(reward)
	var next = _button("查看下一个任务" if not bool(result.get("chapter_complete", false)) else "查看新玩法", "primary")
	next.pressed.connect(_finish_reward_flow.bind(result))
	content.add_child(next)
	_open_modal("任务奖励", content, Vector2(600, 350), false)

func _show_reward_equip_prompt(item_id, claim_result = {}):
	if int(state.inventory.get(item_id, 0)) <= 0:
		_show_reward_summary(claim_result)
		return
	var item = GameData.ITEMS[item_id]
	var content = VBoxContainer.new()
	content.add_theme_constant_override("separation", 13)
	content.add_child(_label("获得关键装备", 20, GOLD))
	var reward_card = _panel_container(Color(0.05, 0.18, 0.21, 0.88), 12, Color(GOLD, 0.55), 1)
	var reward_margin = _inside_margin(15, 13)
	reward_card.add_child(reward_margin)
	var reward_box = VBoxContainer.new()
	reward_box.add_theme_constant_override("separation", 5)
	reward_margin.add_child(reward_box)
	reward_box.add_child(_label("%s · %s" % [item.name, GameData.SLOT_NAMES[item.slot]], 17, _rarity_color(item.rarity)))
	reward_box.add_child(_label(_stats_text(item.stats), 12, Color("8ecbd0")))
	reward_box.add_child(_label(item.description, 11, MUTED))
	content.add_child(reward_card)
	var current_id = str(state.equipment.get(item.slot, ""))
	var current_name = "无"
	if current_id != "" and GameData.ITEMS.has(current_id):
		current_name = GameData.ITEMS[current_id].name
	content.add_child(_label("当前%s：%s。主线 Boss 会按已装备属性计算战力。" % [GameData.SLOT_NAMES[item.slot], current_name], 12, MUTED))
	var actions = HBoxContainer.new()
	actions.add_theme_constant_override("separation", 9)
	var equip_now = _button("立即装备", "gold")
	equip_now.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	equip_now.pressed.connect(_equip_reward_item.bind(item_id, claim_result))
	actions.add_child(equip_now)
	var later = _button("先放入背包", "ghost")
	later.pressed.connect(_finish_reward_flow.bind(claim_result))
	actions.add_child(later)
	content.add_child(actions)
	_open_modal("任务奖励", content, Vector2(620, 420), false)

func _equip_reward_item(item_id, claim_result = {}):
	var result = state.equip_item(item_id)
	_close_modal()
	refresh_ui()
	_show_toast(result.message, result.ok)
	call_deferred("_show_next_quest_prompt")

func _finish_reward_flow(_claim_result = {}):
	_close_modal()
	call_deferred("_show_next_quest_prompt")

func _show_next_quest_prompt():
	var quest = state.get_current_quest()
	var content = VBoxContainer.new()
	content.add_theme_constant_override("separation", 13)
	if quest.is_empty():
		content.add_child(_label("十三卷航海日志完成", 21, GOLD))
		var unlock = _label("持续玩法：九港跑商与循环悬赏", 16, TEAL)
		unlock.add_theme_stylebox_override("normal", _style(Color(0.04, 0.18, 0.18, 0.86), 11, Color(TEAL, 0.55), 1, 14))
		content.add_child(unlock)
		content.add_child(_label("九座港口各有独立商人与特色货单。前往产地低价采购，再根据航期、风险与行情运往需求城市出售。", 13, Color("b7cfd5")))
		var go_trade = _button("返回2D地图，步行前往码头", "gold")
		go_trade.pressed.connect(_go_to_unlocked_trade)
		content.add_child(go_trade)
		_open_modal("新玩法解锁", content, Vector2(650, 430))
		return
	content.add_child(_label("下一个主线任务", 15, TEAL))
	content.add_child(_label("「%s」" % quest.title, 21, GOLD))
	var story = _label(quest.story, 13, Color("b7cfd5"))
	story.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(story)
	content.add_child(_label(_objective_text(quest.objective), 14, INK))
	content.add_child(_label("奖励：%s" % _quest_reward_text(quest.reward), 12, GOLD))
	var start = _button("开始任务", "primary")
	start.pressed.connect(_close_modal)
	content.add_child(start)
	_open_modal("新任务", content, Vector2(640, 450))

func _go_to_unlocked_trade():
	_close_modal()
	call_deferred("_open_2d_world")

func _quest_reward_text(reward):
	var parts = ["%d经验" % int(reward.get("exp", 0)), "%d银币" % int(reward.get("silver", 0))]
	if reward.has("item") and GameData.ITEMS.has(reward.item):
		parts.append(GameData.ITEMS[reward.item].name)
	if reward.has("pet") and GameData.PETS.has(reward.pet):
		parts.append("宠物%s" % GameData.PETS[reward.pet].name)
	if bool(reward.get("companion", false)):
		parts.append("队友招募资格")
	return "、".join(parts)

func _boss_loadout_missing():
	return not "warrior_blade" in state.equipment.values() or not "warrior_coat" in state.equipment.values()

func _show_boss_preparation():
	var content = VBoxContainer.new()
	content.add_theme_constant_override("separation", 13)
	content.add_child(_label("朱雀试炼 · 战前整备", 20, GOLD))
	var warning = _label("朱雀的攻击和中毒会迅速压低体力。你还没有同时装备主线奖励的武士刃与武士战衣。", 13, Color("f2a3a6"))
	warning.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(warning)
	var checklist = []
	for item_id in ["warrior_blade", "warrior_coat"]:
		var equipped = item_id in state.equipment.values()
		var in_bag = int(state.inventory.get(item_id, 0)) > 0
		var status = "已装备" if equipped else ("在背包" if in_bag else "未持有")
		checklist.append("%s：%s" % [GameData.ITEMS[item_id].name, status])
	var check_label = _label("\n".join(checklist), 14, Color("9fd6d7"))
	check_label.add_theme_stylebox_override("normal", _style(Color(0.035, 0.13, 0.17, 0.92), 11, LINE, 1, 14))
	content.add_child(check_label)
	content.add_child(_label("当前战力 %d｜建议装备主线套装、补满体力，并携带万能药。" % state.get_power(), 12, MUTED))
	var actions = HBoxContainer.new()
	actions.add_theme_constant_override("separation", 9)
	var can_equip = true
	for item_id in ["warrior_blade", "warrior_coat"]:
		if not item_id in state.equipment.values() and int(state.inventory.get(item_id, 0)) <= 0:
			can_equip = false
	var equip_and_fight = _button("装备主线套装并挑战", "gold")
	equip_and_fight.disabled = not can_equip
	equip_and_fight.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	equip_and_fight.pressed.connect(_equip_boss_loadout_and_fight)
	actions.add_child(equip_and_fight)
	var force_fight = _button("仍然挑战", "danger")
	force_fight.pressed.connect(func():
		_close_modal()
		_start_fight("vermilion_phantom")
	)
	actions.add_child(force_fight)
	content.add_child(actions)
	_open_modal("Boss 提示", content, Vector2(680, 500))

func _equip_boss_loadout_and_fight():
	for item_id in ["warrior_blade", "warrior_coat"]:
		if not item_id in state.equipment.values() and int(state.inventory.get(item_id, 0)) > 0:
			state.equip_item(item_id)
	_close_modal()
	refresh_ui()
	_show_toast("已装备武士刃与武士战衣，开始朱雀试炼。", true)
	_start_fight("vermilion_phantom")

func _resume_saved_battle():
	if state.active_battle.is_empty():
		return
	var view = state.get_battle_view()
	var saved_logs = state.active_battle.get("log", [])
	if saved_logs.size() > 8:
		saved_logs = saved_logs.slice(saved_logs.size() - 8)
	view.logs = saved_logs
	_show_battle_screen(view)
	_show_toast("已恢复上次未结束的战斗。", true)

func _show_battle_screen(result = {}):
	var battle_over = bool(result.get("battle_over", false))
	var current = result
	if not battle_over and not state.active_battle.is_empty():
		var fresh = state.get_battle_view()
		fresh.logs = result.get("logs", [])
		current = fresh
	var won = bool(current.get("won", false))
	var fled = bool(current.get("fled", false))
	if battle_over:
		var resume_region = "city" if not won and not fled else _audio_region_for_location(str(state.player.location))
		AudioDirector.end_battle(won, fled, resume_region)
	else:
		AudioDirector.enter_battle()
	var color = TEAL if (not battle_over or won) else RED
	var content = VBoxContainer.new()
	content.add_theme_constant_override("separation", 11)

	var banner = _panel_container(Color(color, 0.11), 12, Color(color, 0.72), 1)
	var banner_margin = _inside_margin(14, 10)
	banner.add_child(banner_margin)
	var banner_row = HBoxContainer.new()
	banner_margin.add_child(banner_row)
	var title_text = "战斗状态 · 第%d回合" % int(current.get("round", 1))
	if battle_over:
		title_text = "战斗胜利" if won else ("成功撤退" if fled else "战斗失败")
	banner_row.add_child(_label(title_text, 19, color))
	var banner_flex = Control.new()
	banner_flex.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	banner_row.add_child(banner_flex)
	banner_row.add_child(_label("%s · Lv.%d · %s" % [current.get("enemy_name", ""), int(current.get("enemy_level", 1)), current.get("enemy_rank", "")], 12, MUTED))
	content.add_child(banner)

	if not battle_over:
		var bars = HBoxContainer.new()
		bars.add_theme_constant_override("separation", 14)
		content.add_child(bars)
		bars.add_child(_battle_health_block("航者 Lv.%d" % int(current.get("player_level", state.player.level)), int(current.player_hp), int(current.player_max_hp), TEAL))
		bars.add_child(_battle_health_block("%s Lv.%d" % [current.enemy_name, int(current.get("enemy_level", 1))], int(current.enemy_hp), int(current.enemy_max_hp), RED))
		var status_text = "状态：正常"
		if not current.statuses.is_empty():
			var status_parts = []
			for status_name in current.statuses:
				status_parts.append("%s(%d)" % [status_name, int(current.statuses[status_name])])
			status_text = "状态：%s" % " · ".join(status_parts)
		content.add_child(_label(status_text, 11, RED if not current.statuses.is_empty() else MUTED))
	elif won:
		var reward_text = "+%d 经验    +%d 银币" % [int(current.get("exp", 0)), int(current.get("silver", 0))]
		if current.get("drop", "") != "":
			reward_text += "    百宝箱：%s" % GameData.ITEMS[current.drop].name
		content.add_child(_label(reward_text, 13, GOLD))
		if bool(current.get("leveled", false)):
			content.add_child(_label("等级提升！达到 Lv.%d，体力完全恢复。" % int(current.new_level), 14, TEAL))

	content.add_child(_small_caption("战况"))
	var log_panel = _panel_container(Color("08161d"), 10, LINE, 1)
	log_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var log_margin = _inside_margin(13, 10)
	log_panel.add_child(log_margin)
	var log_scroll = ScrollContainer.new()
	log_scroll.custom_minimum_size.y = 205 if not battle_over else 265
	log_margin.add_child(log_scroll)
	var log_box = VBoxContainer.new()
	log_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	log_box.add_theme_constant_override("separation", 6)
	log_scroll.add_child(log_box)
	var logs = current.get("logs", [])
	if logs.is_empty():
		logs = ["双方正在对峙，选择一次攻击或开启自动攻击。"]
	for index in range(logs.size()):
		var line_text = str(logs[index])
		var log_color = MUTED
		if "胜利" in line_text or "拾取" in line_text:
			log_color = GOLD
		elif "致命" in line_text:
			log_color = Color("f49a78")
		elif "状态" in line_text or "毒素" in line_text:
			log_color = RED
		log_box.add_child(_label(line_text, 12, log_color))
	content.add_child(log_panel)

	if battle_over:
		var continue_button = _button("返回旅程", "primary")
		if won and bool(current.get("quest_completed", false)):
			continue_button.text = "查看任务奖励"
			continue_button.pressed.connect(_close_then_show_quest_completion)
		else:
			continue_button.pressed.connect(_close_modal)
		content.add_child(continue_button)
	else:
		var quick = HBoxContainer.new()
		quick.add_theme_constant_override("separation", 8)
		quick.add_child(_label("战斗药品栏", 11, DIM))
		var milk = _button("小奶瓶 ×%d" % int(state.inventory.get("small_milk", 0)), "ghost")
		milk.disabled = int(state.inventory.get("small_milk", 0)) <= 0
		milk.pressed.connect(_battle_use_item.bind("small_milk"))
		quick.add_child(milk)
		var universal = _button("万能药 ×%d" % int(state.inventory.get("universal_medicine", 0)), "ghost")
		universal.disabled = int(state.inventory.get("universal_medicine", 0)) <= 0
		universal.pressed.connect(_battle_use_item.bind("universal_medicine"))
		quick.add_child(universal)
		content.add_child(quick)
		var actions = HBoxContainer.new()
		actions.add_theme_constant_override("separation", 9)
		var attack = _button("攻击一次", "primary")
		attack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		attack.pressed.connect(_battle_attack_once)
		actions.add_child(attack)
		var auto = _button("开启自动攻击", "gold")
		auto.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		auto.text = "自动战斗中…" if journal_auto_battle_running else "开启自动攻击"
		auto.disabled = journal_auto_battle_running
		auto.pressed.connect(_battle_auto_attack)
		actions.add_child(auto)
		var flee = _button("撤退", "ghost")
		flee.pressed.connect(_battle_flee)
		actions.add_child(flee)
		content.add_child(actions)
	var battle_modal_size = Vector2(696, 1120) if mobile_mode else Vector2(780, 640)
	_open_modal("战斗页面", content, battle_modal_size, battle_over)

func _battle_health_block(title, value, maximum, color):
	var box = VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_theme_constant_override("separation", 5)
	box.add_child(_label("%s  %d/%d" % [title, value, maximum], 11, MUTED))
	var bar = _progress_bar(color)
	bar.max_value = maximum
	bar.value = value
	box.add_child(bar)
	return box

func _battle_attack_once():
	var player_hp_before = int(state.player.hp)
	AudioDirector.play_sfx("attack")
	var result = state.attack_once()
	if int(result.get("player_hp", player_hp_before)) < player_hp_before:
		AudioDirector.play_sfx("hit")
	_close_modal()
	refresh_ui()
	_show_battle_screen(result)

func _battle_auto_attack():
	if journal_auto_battle_running:
		return
	journal_auto_battle_running = true
	var safety_rounds = 0
	while not state.active_battle.is_empty() and safety_rounds < 40:
		var supply_result = state.auto_use_battle_supplies()
		if bool(supply_result.get("used", false)):
			AudioDirector.play_sfx("heal")
		var player_hp_before = int(state.player.hp)
		AudioDirector.play_sfx("attack")
		var result = state.attack_once()
		if int(result.get("player_hp", player_hp_before)) < player_hp_before:
			AudioDirector.play_sfx("hit")
		if not bool(result.get("ok", false)):
			break
		_close_modal()
		refresh_ui()
		_show_battle_screen(result)
		safety_rounds += 1
		if bool(result.get("battle_over", false)):
			break
		await get_tree().create_timer(0.48).timeout
	journal_auto_battle_running = false
	if not state.active_battle.is_empty():
		_close_modal()
		refresh_ui()
		_show_battle_screen(state.get_battle_view())

func _battle_use_item(item_id):
	var result = state.use_item(item_id)
	if bool(result.ok):
		AudioDirector.play_sfx("heal")
	_close_modal()
	refresh_ui()
	_show_toast(result.message, result.ok)
	if not state.active_battle.is_empty():
		_show_battle_screen(state.get_battle_view())

func _battle_flee():
	var result = state.flee_battle()
	_close_modal()
	refresh_ui()
	_show_battle_screen(result)

func _open_inventory():
	var content = VBoxContainer.new()
	content.add_theme_constant_override("separation", 10)
	var stats_line = _label("装备、使用、鉴定与收藏分门别类；所有变化都会自动保存。", 12, MUTED)
	content.add_child(stats_line)
	content.add_child(_label("持有银币：%d" % int(state.player.silver), 12, GOLD))
	var recommend = _button("一键穿戴推荐装备", "gold")
	recommend.pressed.connect(_equip_recommended_from_inventory)
	content.add_child(recommend)
	var card_name = "未启用"
	if state.active_card != "" and GameData.ITEMS.has(state.active_card):
		card_name = str(GameData.ITEMS[state.active_card].name)
	content.add_child(_label("当前怪物卡：%s｜同时只能启用1张" % card_name, 11, TEAL))

	var scroll = ScrollContainer.new()
	scroll.custom_minimum_size.y = 400
	content.add_child(scroll)
	var list = VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 8)
	scroll.add_child(list)

	if state.inventory.is_empty():
		list.add_child(_empty_state("背包里空空如也。前往野外战斗，或去海风市场购买补给。"))
	else:
		var ids = state.inventory.keys()
		ids.sort()
		for item_id in ids:
			list.add_child(_inventory_row(item_id, int(state.inventory[item_id])))
	_open_modal("航者背包", content, Vector2(760, 580))

func _inventory_row(item_id, count):
	var item = GameData.ITEMS[item_id]
	var card = _panel_container(PANEL_SOFT, 11, Color(0.13, 0.32, 0.37, 0.6), 1)
	var margin = _inside_margin(12, 10)
	card.add_child(margin)
	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	margin.add_child(row)

	var rarity_color = _rarity_color(item.rarity)
	var icon = Label.new()
	icon.text = "×%d" % count
	icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	icon.custom_minimum_size = Vector2(48, 44)
	icon.add_theme_font_size_override("font_size", 12)
	icon.add_theme_color_override("font_color", rarity_color)
	icon.add_theme_stylebox_override("normal", _style(Color(rarity_color, 0.08), 9, Color(rarity_color, 0.45), 1))
	row.add_child(icon)

	var text_stack = VBoxContainer.new()
	text_stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_stack.add_theme_constant_override("separation", 2)
	row.add_child(text_stack)
	text_stack.add_child(_label("%s  ·  %s" % [item.name, item.rarity], 14, rarity_color))
	text_stack.add_child(_label(item.description, 11, MUTED))
	if item.type == "equipment":
		text_stack.add_child(_label(_stats_text(item.get("stats", {})), 10, Color("86b8c0")))
		var delta = state.equipment_score_delta(item_id)
		text_stack.add_child(_label("较当前战力 %+d" % delta if delta != 0 else "与当前装备战力相当", 10, GOLD if delta > 0 else MUTED))

	var action_text = "收藏"
	if item.type == "equipment":
		action_text = "装备"
	elif item.type == "consumable":
		action_text = "使用"
	elif item.type == "mystery":
		action_text = "鉴定"
	elif item.type == "card":
		action_text = "已启用" if str(state.active_card) == str(item_id) else "启用"
	var action = _button(action_text, "primary" if item.type != "card" else "ghost")
	action.custom_minimum_size.x = 80
	if item.type == "equipment":
		action.pressed.connect(_equip_from_inventory.bind(item_id))
	elif item.type == "consumable":
		action.pressed.connect(_use_from_inventory.bind(item_id))
	elif item.type == "mystery":
		action.pressed.connect(_identify_from_inventory)
	elif item.type == "card":
		action.disabled = str(state.active_card) == str(item_id)
		action.pressed.connect(_equip_card_from_inventory.bind(item_id))
	else:
		action.disabled = true
	row.add_child(action)
	return card

func _equip_from_inventory(item_id):
	var result = state.equip_item(item_id)
	_close_modal()
	refresh_ui()
	_show_toast(result.message, result.ok)
	call_deferred("_open_inventory")

func _equip_recommended_from_inventory():
	var result = state.equip_recommended()
	_close_modal()
	refresh_ui()
	_show_toast(result.message, result.ok)
	call_deferred("_open_inventory")

func _use_from_inventory(item_id):
	var result = state.use_item(item_id)
	_close_modal()
	refresh_ui()
	_show_toast(result.message, result.ok)
	call_deferred("_open_inventory")

func _equip_card_from_inventory(item_id):
	var result = state.equip_card(item_id)
	_close_modal()
	refresh_ui()
	_show_toast(result.message, result.ok)
	call_deferred("_open_inventory")

func _identify_from_inventory():
	if state.player.location != "venice_market":
		_close_modal()
		_show_toast("未知道具需要带到威尼斯海风市场鉴定。", false)
		return
	var result = state.identify_unknown()
	_close_modal()
	refresh_ui()
	_show_toast(result.message, result.ok)
	call_deferred("_open_inventory")

func _identify_from_market():
	var result = state.identify_unknown()
	refresh_ui()
	_show_toast(result.message, result.ok)

func _open_shop():
	var content = VBoxContainer.new()
	content.add_theme_constant_override("separation", 10)
	content.add_child(_label("海风市场 · 旅行补给", 18, GOLD))
	content.add_child(_label("『战斗药品栏可以随时使用奶瓶和解状态药。』", 12, MUTED))
	for item_id in ["sea_salt_bread", "small_milk", "universal_medicine", "stamina_tonic"]:
		var item = GameData.ITEMS[item_id]
		var row = _panel_container(PANEL_SOFT, 11, LINE, 1)
		var row_margin = _inside_margin(13, 11)
		row.add_child(row_margin)
		var hbox = HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 12)
		row_margin.add_child(hbox)
		var text_stack = VBoxContainer.new()
		text_stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hbox.add_child(text_stack)
		text_stack.add_child(_label(item.name, 14, INK))
		text_stack.add_child(_label(item.description, 11, MUTED))
		var price = _label("%d 银币" % item.price, 13, GOLD)
		hbox.add_child(price)
		var buy = _button("购买", "primary")
		buy.pressed.connect(_buy_from_shop.bind(item_id))
		hbox.add_child(buy)
		content.add_child(row)
	content.add_child(_label("持有银币：%d" % int(state.player.silver), 12, Color("e8d49b")))
	_open_modal("海风市场", content, Vector2(690, 590))

func _open_vendor_shop(npc_id):
	var vendor_id = str(npc_id)
	if not GameData.VENDOR_SHOPS.has(vendor_id):
		_show_toast("这位人物暂时没有可出售的商品。", false)
		return
	var shop = GameData.VENDOR_SHOPS[vendor_id]
	var content = VBoxContainer.new()
	content.add_theme_constant_override("separation", 10)
	content.add_child(_label(str(shop.name), 20, GOLD))
	var intro = _label("%s\n持有银币：%d" % [str(shop.description), int(state.player.silver)], 13, TEAL)
	intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(intro)
	for item_id in GameData.vendor_stock(vendor_id):
		var item = GameData.ITEMS[str(item_id)]
		var row = _panel_container(PANEL_SOFT, 11, LINE, 1)
		var row_margin = _inside_margin(13, 11)
		row.add_child(row_margin)
		var hbox = HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 12)
		row_margin.add_child(hbox)
		var text_stack = VBoxContainer.new()
		text_stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hbox.add_child(text_stack)
		text_stack.add_child(_label("%s · %s" % [str(item.name), str(item.rarity)], 14, INK))
		var description = _label("%s\n持有%d件" % [str(item.description), int(state.inventory.get(str(item_id), 0))], 11, MUTED)
		description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		text_stack.add_child(description)
		var buy = _button("%d银 · 购买" % int(item.price), "gold")
		buy.disabled = int(state.player.silver) < int(item.price)
		buy.pressed.connect(_buy_from_vendor.bind(vendor_id, str(item_id)))
		hbox.add_child(buy)
		content.add_child(row)
	_open_modal(str(shop.name), content, Vector2(700, 620))

func _buy_from_vendor(npc_id, item_id):
	var result = state.buy_vendor_item(npc_id, item_id)
	_close_modal()
	refresh_ui()
	_show_toast(result.message, result.ok)
	call_deferred("_open_vendor_shop", npc_id)

func _buy_from_shop(item_id):
	var result = state.buy_item(item_id)
	_close_modal()
	refresh_ui()
	_show_toast(result.message, result.ok)
	call_deferred("_open_shop")

func _open_character():
	var content = VBoxContainer.new()
	content.add_theme_constant_override("separation", 10)
	var stats = state.get_stats()
	var summary = _panel_container(Color(0.05, 0.18, 0.21, 0.8), 12, Color(TEAL, 0.42), 1)
	var sm = _inside_margin(14, 12)
	summary.add_child(sm)
	var summary_row = HBoxContainer.new()
	sm.add_child(summary_row)
	summary_row.add_child(_label("战力 %d" % state.get_power(), 20, TEAL))
	var fill = Control.new()
	fill.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	summary_row.add_child(fill)
	summary_row.add_child(_label("体力 %d  ·  攻击 %d  ·  防御 %d  ·  敏捷 %d" % [stats.max_hp, stats.attack, stats.defense, stats.speed], 12, MUTED))
	content.add_child(summary)
	content.add_child(_label("持有银币：%d｜强化装备会消耗银币" % int(state.player.silver), 12, GOLD))
	var recommend = _button("一键穿戴推荐装备", "gold")
	recommend.pressed.connect(func():
		var result = state.equip_recommended()
		_close_modal()
		refresh_ui()
		_show_toast(result.message, result.ok)
		call_deferred("_open_character")
	)
	content.add_child(recommend)
	content.add_child(_small_caption("当前装备"))

	for slot in ["weapon", "head", "body", "waist", "boots", "charm"]:
		var item_id = state.equipment.get(slot, "")
		var card = _panel_container(PANEL_SOFT, 10, LINE, 1)
		var cm = _inside_margin(12, 9)
		card.add_child(cm)
		var row = HBoxContainer.new()
		cm.add_child(row)
		var slot_label = _label(GameData.SLOT_NAMES[slot], 11, DIM)
		slot_label.custom_minimum_size.x = 62
		row.add_child(slot_label)
		if item_id == "":
			row.add_child(_label("尚未装备", 13, MUTED))
		else:
			var item = GameData.ITEMS[item_id]
			var name = _label(item.name, 13, _rarity_color(item.rarity))
			name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			row.add_child(name)
			row.add_child(_label(_stats_text(item.stats), 11, Color("86b8c0")))
		content.add_child(card)

	var set_count = 0
	for item_id in state.equipment.values():
		if item_id != "" and GameData.ITEMS[item_id].get("set", "") == "warrior":
			set_count += 1
	var set_text = "武士套 %d/5｜每件掉落+4%%｜2件额外+8%%｜4件额外+12%%" % set_count
	var set_label = _label(set_text, 12, GOLD if set_count >= 2 else MUTED)
	set_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	set_label.add_theme_stylebox_override("normal", _style(Color(0.18, 0.13, 0.04, 0.45), 10, Color(0.45, 0.34, 0.12, 0.6), 1, 10))
	content.add_child(set_label)
	var social_parts = []
	social_parts.append("队伍：独自冒险" if state.party_members.is_empty() else "队伍：%s（攻防+5%%）" % state.party_members[0])
	social_parts.append("宠物：无" if state.pet.is_empty() else "宠物：%s（战斗自动协战）" % state.pet.name)
	social_parts.append("当前物品掉落加成：%d%%" % int(round(float(stats.drop_bonus) * 100.0)))
	content.add_child(_label("  ·  ".join(social_parts), 11, Color("8ecbd0")))
	_open_modal("角色与装备", content, Vector2(740, 630))

func _open_quest_detail():
	var content = VBoxContainer.new()
	content.add_theme_constant_override("separation", 12)
	var progress = state.story_progress()
	content.add_child(_label("%s %d/%d｜%s %d/%d" % [str(progress.volume), int(progress.volume_completed), int(progress.volume_total), str(progress.chapter), int(progress.chapter_completed), int(progress.chapter_total)], 13, TEAL))
	var recap_titles = state.completed_story_titles(3)
	if not recap_titles.is_empty():
		var recap = _label("剧情回顾｜%s\n%s" % [" → ".join(recap_titles), str(progress.summary)], 12, MUTED)
		recap.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		content.add_child(recap)
	var quest = state.get_current_quest()
	if quest.is_empty():
		content.add_child(_empty_state("第十三卷·封印迷阵已完成。九港航路与十座终局潮阵已重归平静。"))
	else:
		content.add_child(_label(quest.title, 20, GOLD))
		content.add_child(_label(quest.story, 13, Color("b7cfd5")))
		var objective = quest.objective
		content.add_child(_label("当前%s  %d / %d" % [_objective_text(objective), state.quest_progress, int(objective.need)], 13, TEAL))
		var reward = quest.reward
		var reward_parts = ["%d 经验" % int(reward.get("exp", 0)), "%d 银币" % int(reward.get("silver", 0))]
		if reward.has("item") and GameData.ITEMS.has(reward.item):
			reward_parts.append(str(GameData.ITEMS[reward.item].name))
		if reward.has("pet") and GameData.PETS.has(reward.pet):
			reward_parts.append("宠物%s" % GameData.PETS[reward.pet].name)
		if reward.has("title"):
			reward_parts.append("称号「%s」" % str(reward.title))
		content.add_child(_label("任务奖励｜%s" % " · ".join(reward_parts), 12, MUTED))
		var route = _quest_route_hint(state.quest_index)
		var route_label = _label("推荐路线\n%s" % route, 12, Color("8ecbd0"))
		route_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		route_label.add_theme_stylebox_override("normal", _style(Color(0.04, 0.16, 0.19, 0.8), 10, LINE, 1, 12))
		content.add_child(route_label)
		if state.quest_can_claim():
			var claim = _button("领取任务奖励", "gold")
			claim.pressed.connect(func():
				_close_modal()
				_on_claim_quest()
			)
			content.add_child(claim)
	if state.quest_index >= 3:
		var bounty = state.get_bounty()
		content.add_child(_label("城市悬赏｜%s  %d/%d" % [bounty.title, state.bounty_progress, int(bounty.need)], 15, GOLD))
		content.add_child(_label(str(bounty.description), 11, MUTED))
		if state.bounty_can_claim():
			var bounty_claim = _button("领取悬赏奖励", "gold")
			bounty_claim.pressed.connect(_claim_bounty_from_journal)
			content.add_child(bounty_claim)
	_open_modal("任务日志", content, Vector2(660, 520))

func _claim_bounty_from_journal():
	var result = state.claim_bounty()
	if bool(result.ok):
		AudioDirector.play_sfx("reward")
	_close_modal()
	refresh_ui()
	_show_toast(result.message, result.ok)
	call_deferred("_open_quest_detail")

func _quest_route_hint(index):
	if index < 0 or index >= GameData.QUESTS.size():
		return "打开2D世界的任务导航寻找当前目标。"
	var quest_id = str(GameData.QUESTS[index].id)
	var routes = {
		"scale_memory": "海边小屋 → 与艾丽莎交谈",
		"to_tavern": "海边小屋 → 威尼斯酒馆",
		"tavern_clue": "威尼斯酒馆 → 与酒馆老板交谈",
		"north_gate": "城市广场 → 北城门",
		"stolen_ore": "北城门 → 住宅区 → 废矿山",
		"back_hill_bear": "住宅区 → 后山",
		"four_floor_trial": "北城门 → 经验副本，逐层击败守卫",
		"first_cargo": "威尼斯码头 → 购买2箱威尼斯玻璃",
		"sail_ragusa": "威尼斯码头 → 启航前往拉古萨",
		"sell_glass": "拉古萨码头 → 卖出2箱威尼斯玻璃",
		"forge_for_sea": "背包 → 将已装备的手持武器强化1次",
		"armor_the_swallow": "港口贸易 → 船只改造 → 加固船体",
		"black_sail_clue": "世界地图 → 黑帆据点外围",
		"clear_deckhands": "黑帆据点一层 → 击败黑帆水手长",
		"powder_store": "黑帆据点二层 → 击败黑帆袭击者",
		"cave_battery": "黑帆据点三层 → 夺取洞窟炮台",
		"captain_ledger": "黑帆据点四层 → 击败船长雷蒙",
		"return_chart": "回威尼斯酒馆 → 交付黑帆海图",
		"alisa_truth": "回海边小屋 → 与艾丽莎交谈",
		"lighthouse_letter": "步行返回老海鸥酒馆 → 阅读萨米尔来信",
		"sail_lighthouse": "步行到威尼斯码头 → 可先买3箱玻璃 → 启航亚历山大",
		"samir_testimony": "亚历山大灯塔港 → 与香料商萨米尔交谈",
		"lighthouse_repairs": "亚历山大码头 → 找商会执事莱拉 → 交付3箱威尼斯玻璃",
		"ragusa_nightwatch": "亚历山大买4桶橄榄油 → 航行拉古萨 → 交付订单",
		"three_port_trust": "完成任意港口订单或盈利出售货物 → 三港总声望达到6",
		"guarded_passage": "任意港口 → 购买护航物资",
		"tide_medicine": "亚历山大买4袋东方香料 → 航行威尼斯 → 交付订单",
		"white_whale_news": "海边小屋 → 与艾丽莎交谈",
		"sail_malta": "威尼斯码头 → 启航前往马耳他",
		"meet_isabella": "马耳他港 → 与守钟人伊莎贝拉交谈",
		"island_feast": "马耳他港购买配料 → 港口厨房烹制海风炖汤",
		"wreck_entry": "马耳他港 → 步行进入白鲸号残骸",
		"clear_reef": "白鲸残骸一层 → 击败覆甲礁蟹",
		"drowned_deck": "白鲸残骸二层 → 击败溺潮水手",
		"fog_hold": "白鲸残骸三层 → 击败雾歌海妖",
		"white_whale_heart": "白鲸残骸四层 → 击败深渊海妖",
		"heir_testimony": "返回马耳他港 → 与伊莎贝拉交谈",
		"keeper_return": "威尼斯码头 → 步行老海鸥酒馆 → 解读星图"
	}
	return str(routes.get(quest_id, "打开2D世界的任务导航寻找当前目标。"))

func _objective_text(objective):
	var target_name = GameData.objective_name(objective)
	match objective.type:
		"talk": return "目标：与%s交谈" % target_name
		"visit": return "目标：到达%s" % target_name
		"kill": return "目标：击败%s" % target_name
		_: return "目标：%s" % target_name

func _open_party():
	var content = VBoxContainer.new()
	content.add_theme_constant_override("separation", 13)
	content.add_child(_label("酒馆队伍", 20, GOLD))
	var rules = _label("原版组队规则：2 / 3 / 4 / 5 人分别提高 5% / 10% / 15% / 20% 攻击与防御，队友还可共享杀怪任务计数。当前单机篇章先模拟一名队友。", 12, MUTED)
	rules.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(rules)
	var status_text = "当前：独自冒险"
	if not state.party_members.is_empty():
		status_text = "当前：你 + %s｜2人队伍｜攻防 +5%%" % state.party_members[0]
	var status_card = _label(status_text, 14, TEAL if not state.party_members.is_empty() else Color("b7cfd5"))
	status_card.add_theme_stylebox_override("normal", _style(Color(0.04, 0.16, 0.19, 0.82), 11, LINE, 1, 13))
	content.add_child(status_card)
	var action
	if state.party_members.is_empty():
		action = _button("邀请见习水手·卢卡", "primary")
		action.disabled = not state.companion_unlocked
		action.pressed.connect(_party_recruit)
		content.add_child(action)
		if not state.companion_unlocked:
			content.add_child(_label("完成主线「失窃的矿石」后解锁队友。", 11, DIM))
	else:
		action = _button("离开当前队伍", "ghost")
		action.pressed.connect(_party_leave)
		content.add_child(action)
	_open_modal("组队", content, Vector2(650, 420))

func _party_recruit():
	var result = state.recruit_companion()
	_close_modal()
	refresh_ui()
	_show_toast(result.message, result.ok)
	call_deferred("_open_party")

func _party_leave():
	var result = state.leave_party()
	_close_modal()
	refresh_ui()
	_show_toast(result.message, result.ok)
	call_deferred("_open_party")

func _open_city_map():
	var content = VBoxContainer.new()
	content.add_theme_constant_override("separation", 12)
	content.add_child(_label("威尼斯城内地图", 20, GOLD))
	content.add_child(_label("地点依靠方向链接相连，这种逐页移动方式保留了 WAP 文字游戏的核心操作感。", 12, MUTED))
	var map_text = "　　　　　　　　　北城门\n　　　　　　　　　练级 / 经验副本\n　　　　　　　　　　　↑\n老海鸥酒馆　←　城市广场　→　海风市场\n休息 / 组队　　　　│　　　　　补给 / 鉴定\n　　　　　　　　　　　↓\n　　　　　　　　　威尼斯码头\n　　　　　　　　　船只 / 航行"
	var map_label = _label(map_text, 14, Color("9fd6d7"))
	map_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	map_label.add_theme_stylebox_override("normal", _style(Color(0.035, 0.13, 0.17, 0.92), 13, Color(TEAL, 0.4), 1, 18))
	content.add_child(map_label)
	var close = _button("按方向链接继续探索", "primary")
	close.pressed.connect(_close_modal)
	content.add_child(close)
	_open_modal("城市地图", content, Vector2(700, 520))

func _open_harbor():
	var content = VBoxContainer.new()
	content.add_theme_constant_override("separation", 10)
	if not state.active_voyage.is_empty():
		var voyage = state.active_voyage
		content.add_child(_label("海燕号正在航行", 20, GOLD))
		var sailing_copy = _label("当前位于%s：%s → %s。航行中不能在启航港买卖货物，请返回2D海域继续驾驶。" % [GameData.SEA_REGIONS[str(voyage.region)].name, GameData.TRADE_PORTS[str(voyage.origin)].name, GameData.TRADE_PORTS[str(voyage.destination)].name], 13, Color("b7cfd5"))
		sailing_copy.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		content.add_child(sailing_copy)
		var resume = _button("返回海域继续航行", "primary")
		resume.pressed.connect(_open_2d_world)
		content.add_child(resume)
		_open_modal("航行进行中", content, Vector2(650, 380))
		return
	if not state.is_trade_unlocked():
		content.add_child(_label("港口贸易尚未解锁", 20, GOLD))
		var locked = _label("完成主线「四层试炼」并领取奖励后，船老板会赠送贸易船「海燕号」。之后会随剧情逐步发现九座各具特产的港口。", 13, Color("b7cfd5"))
		locked.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		locked.add_theme_stylebox_override("normal", _style(Color(0.18, 0.13, 0.04, 0.45), 11, Color(GOLD, 0.45), 1, 14))
		content.add_child(locked)
		var close_locked = _button("返回码头", "primary")
		close_locked.pressed.connect(_close_modal)
		content.add_child(close_locked)
		_open_modal("港口贸易", content, Vector2(650, 380))
		return

	var port_id = str(state.player.location)
	if not GameData.TRADE_PORTS.has(port_id):
		content.add_child(_label("这里不是港口", 20, GOLD))
		var travel_guide = _label("贸易必须在真实港口进行，不能从日志界面直接跳到码头。返回2D地图后，请通过区域地图或任务导航步行前往威尼斯码头。", 13, Color("b7cfd5"))
		travel_guide.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		travel_guide.add_theme_stylebox_override("normal", _style(Color(0.18, 0.13, 0.04, 0.45), 11, Color(GOLD, 0.45), 1, 14))
		content.add_child(travel_guide)
		var return_to_world = _button("返回2D地图，步行前往码头", "primary")
		return_to_world.pressed.connect(_open_2d_world)
		content.add_child(return_to_world)
		_open_modal("港口贸易", content, Vector2(650, 390))
		return
	var port = GameData.TRADE_PORTS[port_id]
	content.add_child(_label("%s港口市场" % port.name, 20, GOLD))
	var status = _label("持有银币：%d｜第%d日 · %s · 货舱%d/%d · 货值%d · 浮动%+d · 本港声望%d / 总声望%d" % [int(state.player.silver), state.trade_day, state.ship.name, state.cargo_used(), state.cargo_capacity(), state.cargo_market_value(), state.cargo_unrealized_profit(), state.port_reputation_value(port_id), state.total_trade_reputation()], 12, TEAL)
	status.add_theme_stylebox_override("normal", _style(Color(0.04, 0.18, 0.18, 0.86), 10, Color(TEAL, 0.45), 1, 11))
	content.add_child(status)
	content.add_child(_label("行情：%s｜买入价每日波动；本港卖出价为行情的90%%。" % port.note, 11, MUTED))

	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	content.add_child(scroll)
	var market = VBoxContainer.new()
	market.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	market.add_theme_constant_override("separation", 9)
	scroll.add_child(market)
	var merchant_id = str(port.get("merchant_npc", ""))
	var merchant = GameData.NPCS.get(merchant_id, {"name": "港口商人", "role": "货栈经营者"})
	var merchant_copy = _label("交易商人｜%s · %s\n本港特产｜%s\n%s" % [merchant.name, merchant.role, port.specialty, port.note], 12, TEAL)
	merchant_copy.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	merchant_copy.add_theme_stylebox_override("normal", _style(Color(0.03, 0.17, 0.15, 0.92), 10, Color(TEAL, 0.5), 1, 11))
	market.add_child(merchant_copy)
	var opportunity = state.best_trade_opportunity()
	if not opportunity.is_empty():
		market.add_child(_label("商会推荐｜%s → %s｜%d日后满舱估算净利 %+d" % [GameData.TRADE_GOODS[str(opportunity.good_id)].name, GameData.TRADE_PORTS[str(opportunity.destination)].name, int(opportunity.days), int(opportunity.total_profit)], 11, TEAL))
	var order = state.current_trade_order(port_id)
	if not order.is_empty():
		var order_row = HBoxContainer.new()
		order_row.add_theme_constant_override("separation", 8)
		var held_for_order = int(state.cargo.get(str(order.good), 0))
		var order_good = GameData.TRADE_GOODS[str(order.good)]
		var order_source = GameData.TRADE_PORTS[str(order_good.origin)].name
		var order_info = _label("%s商会订单｜%s%s\n%s×%d · 货舱%d/%d · 采购地%s · 奖金%d · 声望+%d" % [port.name, str(order.title), " · 主线" if bool(order.get("story", false)) else "", order_good.name, int(order.amount), held_for_order, int(order.amount), order_source, int(order.bonus), int(order.reputation)], 11, GOLD)
		order_info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		order_row.add_child(order_info)
		var order_claim = _button("向商会交付", "gold")
		order_claim.disabled = not state.trade_order_can_claim(port_id)
		order_claim.pressed.connect(_claim_trade_order_from_journal)
		order_row.add_child(order_claim)
		market.add_child(order_row)
	for recipe in state.available_recipes(port_id):
		var ingredients = []
		var can_cook = int(state.player.silver) >= int(recipe.silver)
		for good_id in recipe.cargo:
			var need = int(recipe.cargo[good_id])
			var held = int(state.cargo.get(good_id, 0))
			var source_port = str(GameData.TRADE_GOODS[good_id].origin)
			ingredients.append("%s %d/%d（%s）" % [GameData.TRADE_GOODS[good_id].name, held, need, GameData.TRADE_PORTS[source_port].name])
			can_cook = can_cook and held >= need
		var recipe_row = HBoxContainer.new()
		recipe_row.add_theme_constant_override("separation", 8)
		var recipe_info = _label("港口厨房｜%s\n%s｜费用%d银币" % [recipe.name, "、".join(ingredients), int(recipe.silver)], 11, GOLD)
		recipe_info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		recipe_row.add_child(recipe_info)
		var cook = _button("烹制", "gold")
		cook.disabled = not can_cook
		cook.pressed.connect(_cook_recipe.bind(str(recipe.id)))
		recipe_row.add_child(cook)
		market.add_child(recipe_row)
	var protection = _button("护航物资已装船" if state.voyage_protection > 0 else "购买护航物资 45银 · 下次穿越风暴免损", "ghost")
	protection.disabled = state.voyage_protection > 0 or int(state.player.silver) < 45
	protection.pressed.connect(_buy_voyage_protection_from_journal)
	market.add_child(protection)
	var contract = HBoxContainer.new()
	contract.add_theme_constant_override("separation", 8)
	var contract_target = state.trade_contract_target()
	var contract_info = _label("商会委托·第%d轮｜净利 %d/%d" % [state.trade_contract_count + 1, state.trade_contract_progress(), contract_target], 11, GOLD)
	contract_info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	contract.add_child(contract_info)
	var contract_claim = _button("领取", "gold")
	contract_claim.disabled = not state.trade_contract_can_claim()
	contract_claim.pressed.connect(_claim_trade_contract_from_journal)
	contract.add_child(contract_claim)
	market.add_child(contract)
	var local_stock = GameData.port_stock(port_id)
	market.add_child(_small_caption("本港产地货栈 · 每种货物只在原产港出售"))
	for good_id in local_stock:
		_add_journal_trade_good_card(market, str(good_id), true)
	var foreign_cargo = []
	for good_id in state.cargo:
		if int(state.cargo.get(good_id, 0)) > 0 and GameData.TRADE_GOODS.has(good_id) and str(good_id) not in local_stock:
			foreign_cargo.append(str(good_id))
	if not foreign_cargo.is_empty():
		market.add_child(_small_caption("船上外来货 · 本港收购"))
		for good_id in foreign_cargo:
			_add_journal_trade_good_card(market, str(good_id), false)

	market.add_child(_small_caption("自由航线 · 已发现港口均可直航，距离与海域决定威胁"))
	for destination in GameData.TRADE_PORTS:
		if destination == port_id:
			continue
		if not state.is_port_unlocked(str(destination)):
			continue
		var route = GameData.trade_route(port_id, destination)
		if route.is_empty():
			continue
		var plan = state.voyage_plan(destination)
		var route_row = HBoxContainer.new()
		route_row.add_theme_constant_override("separation", 8)
		var sail = _button("出航%s · %d海里/%d日 · %d节 · 体力%d · 风险%d%%" % [GameData.TRADE_PORTS[destination].name, int(plan.distance_nm), int(plan.days), int(plan.speed_knots), int(plan.stamina_cost), int(plan.risk)], "primary")
		sail.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		sail.disabled = int(state.player.hp) <= int(plan.stamina_cost)
		sail.tooltip_text = "潜水寻宝%d%%｜侦测到%d处威胁" % [int(plan.dive_chance), int(plan.threat_count)]
		sail.pressed.connect(_trade_depart.bind(destination))
		route_row.add_child(sail)
		var transfer = _button("传送 · %d银" % int(route.fee), "ghost")
		transfer.disabled = int(state.player.silver) < int(route.fee)
		transfer.pressed.connect(_trade_transfer.bind(destination))
		route_row.add_child(transfer)
		market.add_child(route_row)

	market.add_child(_small_caption("船只改造"))
	var upgrades = HBoxContainer.new()
	upgrades.add_theme_constant_override("separation", 8)
	var hold = _button("扩建货舱 +6", "ghost")
	_hold_upgrade_state(hold)
	hold.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hold.pressed.connect(_trade_upgrade.bind("hold"))
	upgrades.add_child(hold)
	var speed_profile = state.ship_speed_profile()
	var speed = _button("船帆Lv.%d · %d节｜升级节速" % [int(state.ship.speed), int(speed_profile.knots)], "ghost")
	speed.disabled = int(state.ship.speed) >= 4
	speed.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	speed.pressed.connect(_trade_upgrade.bind("speed"))
	upgrades.add_child(speed)
	var armor = _button("加固船体 -6%风险", "ghost")
	armor.disabled = int(state.ship.get("armor", 0)) >= 3
	armor.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	armor.pressed.connect(_trade_upgrade.bind("armor"))
	upgrades.add_child(armor)
	market.add_child(upgrades)
	market.add_child(_label("本轮商会净收支：%+d银币｜生涯已实现货差：%+d｜累计成交%d件" % [state.trade_profit, state.trade_lifetime_profit, state.trade_volume], 11, MUTED))
	_open_modal("货物贸易", content, Vector2(720, 1120) if mobile_mode else Vector2(760, 650))

func _add_journal_trade_good_card(market, good_id, can_buy):
	var good = GameData.TRADE_GOODS[good_id]
	var card = _panel_container(PANEL_SOFT, 10, LINE, 1)
	var card_margin = _inside_margin(11, 9)
	card.add_child(card_margin)
	var stack = VBoxContainer.new()
	stack.add_theme_constant_override("separation", 7)
	card_margin.add_child(stack)
	var held = int(state.cargo.get(good_id, 0))
	var average = state.cargo_average_cost(good_id)
	var estimate = state.trade_sell_price(good_id) - average if held > 0 else 0
	var origin_id = str(good.get("origin", ""))
	var origin_name = str(GameData.TRADE_PORTS.get(origin_id, {"name": "未知港口"}).name)
	var stock_tag = "本港出产" if can_buy else "外来货"
	stack.add_child(_label("%s · %s · 产地%s · %d格/%s" % [good.name, stock_tag, origin_name, int(good.space), good.unit], 13, INK))
	var price_text = "买%d / 卖%d" % [state.trade_buy_price(good_id), state.trade_sell_price(good_id)] if can_buy else "本港收购%d" % state.trade_sell_price(good_id)
	stack.add_child(_label("%s · 持有%d%s · 均价%d · 单件预估%+d" % [price_text, held, good.unit, average, estimate], 11, GOLD))
	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	stack.add_child(row)
	if can_buy:
		var buy = _button("买1", "primary")
		buy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		buy.disabled = state.max_buyable_cargo(good_id) <= 0
		buy.pressed.connect(_trade_buy.bind(good_id))
		row.add_child(buy)
		var buy_max = _button("买满", "gold")
		buy_max.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		buy_max.disabled = state.max_buyable_cargo(good_id) <= 0
		buy_max.pressed.connect(_trade_buy.bind(good_id, true))
		row.add_child(buy_max)
	var sell = _button("卖1", "ghost")
	sell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sell.disabled = held <= 0
	sell.pressed.connect(_trade_sell.bind(good_id))
	row.add_child(sell)
	var sell_all = _button("全卖", "ghost")
	sell_all.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sell_all.disabled = held <= 0
	sell_all.pressed.connect(_trade_sell.bind(good_id, true))
	row.add_child(sell_all)
	market.add_child(card)

func _hold_upgrade_state(button):
	button.disabled = state.cargo_capacity() >= 30

func _trade_buy(good_id, buy_max = false):
	var result = state.buy_max_cargo(good_id) if buy_max else state.buy_cargo(good_id)
	_close_modal()
	refresh_ui()
	_show_toast(result.message, result.ok)
	call_deferred("_open_harbor")

func _trade_sell(good_id, sell_all = false):
	var result = state.sell_all_cargo(good_id) if sell_all else state.sell_cargo(good_id)
	_close_modal()
	refresh_ui()
	_show_toast(result.message, result.ok)
	call_deferred("_open_harbor")

func _cook_recipe(recipe_id):
	var result = state.cook_provision(recipe_id)
	_close_modal()
	refresh_ui()
	_show_toast(str(result.get("message", "无法烹制")), bool(result.get("ok", false)))
	if bool(result.get("quest_completed", false)):
		call_deferred("_show_quest_completion_prompt")
	else:
		call_deferred("_open_harbor")

func _trade_sail(destination):
	var result = state.transfer_to(destination)
	if bool(result.ok):
		AudioDirector.play_sfx("sail")
	_close_modal()
	refresh_ui()
	_show_toast(result.message, result.ok)
	call_deferred("_open_harbor")

func _trade_depart(destination):
	var result = state.begin_voyage(destination)
	if not bool(result.get("ok", false)):
		_close_modal()
		refresh_ui()
		_show_toast(str(result.get("message", "无法出航。")), false)
		call_deferred("_open_harbor")
		return
	AudioDirector.play_sfx("sail")
	_close_modal()
	state.save_game()
	get_tree().change_scene_to_file("res://scenes/world_2d.tscn")

func _trade_transfer(destination):
	var result = state.transfer_to(destination)
	if bool(result.get("ok", false)):
		AudioDirector.play_sfx("sail")
	_close_modal()
	refresh_ui()
	_show_toast(str(result.get("message", "无法传送。")), bool(result.get("ok", false)))
	if bool(result.get("quest_completed", false)):
		call_deferred("_show_quest_completion_prompt")
	else:
		call_deferred("_open_harbor")

func _trade_upgrade(kind):
	var result = state.upgrade_ship(kind)
	_close_modal()
	refresh_ui()
	_show_toast(result.message, result.ok)
	call_deferred("_open_harbor")

func _claim_trade_contract_from_journal():
	var result = state.claim_trade_contract()
	if bool(result.get("ok", false)):
		AudioDirector.play_sfx("reward")
	_close_modal()
	refresh_ui()
	_show_toast(result.message, result.ok)
	call_deferred("_open_harbor")

func _claim_trade_order_from_journal():
	var result = state.claim_trade_order()
	if bool(result.get("ok", false)):
		AudioDirector.play_sfx("reward")
	_close_modal()
	refresh_ui()
	_show_toast(result.message, result.ok)
	if bool(result.get("quest_completed", false)):
		call_deferred("_show_quest_completion_prompt")
	else:
		call_deferred("_open_harbor")

func _buy_voyage_protection_from_journal():
	var result = state.buy_voyage_protection()
	_close_modal()
	refresh_ui()
	_show_toast(result.message, result.ok)
	if bool(result.get("quest_completed", false)):
		call_deferred("_show_quest_completion_prompt")
	else:
		call_deferred("_open_harbor")

func _show_welcome():
	var content = VBoxContainer.new()
	content.add_theme_constant_override("separation", 13)
	var intro = _label("你在翻船后的海边醒来，已经不记得自己的名字。", 20, GOLD)
	content.add_child(intro)
	var copy = _label("艾丽莎的父亲救了你，手中那片发光的鳞或许藏着身世线索。去威尼斯酒馆吧——在那里，四片大陆、海妖、女巫与远洋贸易的传说正等待一个失忆的冒险者。", 13, Color("b7cfd5"))
	copy.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(copy)

	var flow = _panel_container(Color(0.04, 0.16, 0.19, 0.82), 12, LINE, 1)
	var fm = _inside_margin(14, 12)
	flow.add_child(fm)
	var flow_text = _label("人物交谈  →  按方向移动  →  每次攻击推进一回合\n        →  拾取百宝箱  →  鉴定装备  →  组队与宠物成长", 14, TEAL)
	flow_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	fm.add_child(flow_text)
	content.add_child(flow)

	content.add_child(_label("快速提示", 13, INK))
	content.add_child(_label("• 攻击一次只刷新一个回合，也可开启自动攻击\n• 战斗药品栏可恢复体力、解除中毒与虚弱等状态\n• 未知道具要带回海风市场鉴定，武士套提高掉落率\n• 任务完成会主动弹出领奖，领取后继续引导下一任务", 12, MUTED))

	var start = _button("开始航程", "primary")
	start.pressed.connect(_close_modal)
	content.add_child(start)
	_open_modal("序章 · 失去的名字", content, Vector2(700, 530))

func _open_modal(title, content, minimum_size = Vector2(720, 540), allow_close = true):
	_close_modal()
	modal_allow_close = allow_close
	modal_layer = ColorRect.new()
	modal_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	modal_layer.color = Color(0.01, 0.035, 0.05, 0.83)
	modal_layer.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(modal_layer)

	var center = CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	modal_layer.add_child(center)
	var panel = _panel_container(Color("0a1c25"), 18, Color(0.20, 0.56, 0.59, 0.75), 1)
	var modal_size = minimum_size
	if mobile_mode:
		var viewport_size = get_viewport_rect().size
		modal_size.x = min(modal_size.x, max(320.0, viewport_size.x - 24.0))
		modal_size.y = min(modal_size.y, max(420.0, viewport_size.y - 24.0))
	panel.custom_minimum_size = modal_size
	center.add_child(panel)
	var margin = _inside_margin(14 if mobile_mode else 22, 14 if mobile_mode else 18)
	panel.add_child(margin)
	var box = VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	margin.add_child(box)

	var header = HBoxContainer.new()
	box.add_child(header)
	header.add_child(_label(title, 16, INK))
	var spacer = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(spacer)
	var close_button = _button("关闭  Esc" if allow_close else "请完成当前操作", "ghost")
	close_button.disabled = not allow_close
	if allow_close:
		close_button.pressed.connect(_close_modal)
	header.add_child(close_button)
	box.add_child(_thin_line())
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(content)

	panel.modulate.a = 0.0
	panel.scale = Vector2(0.97, 0.97)
	panel.pivot_offset = modal_size * 0.5
	var tween = create_tween().set_parallel(true)
	tween.tween_property(panel, "modulate:a", 1.0, 0.16)
	tween.tween_property(panel, "scale", Vector2.ONE, 0.20).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func _close_modal():
	if is_instance_valid(modal_layer):
		modal_layer.queue_free()
	modal_layer = null
	modal_allow_close = true

func _show_toast(text, positive = true):
	var toast = _panel_container(Color("10272d") if positive else Color("35191e"), 12, Color(TEAL, 0.7) if positive else Color(RED, 0.7), 1)
	toast.z_index = 40
	toast.mouse_filter = Control.MOUSE_FILTER_IGNORE
	toast.set_anchors_preset(Control.PRESET_CENTER_TOP)
	var toast_width = 420 if mobile_mode else 340
	toast.position = Vector2(-toast_width * 0.5, 86 if mobile_mode else 98)
	toast.custom_minimum_size = Vector2(toast_width, 56 if mobile_mode else 48)
	var margin = _inside_margin(14, 11)
	toast.add_child(margin)
	var label = _label(text, 12, INK if positive else Color("ffc4c7"))
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	margin.add_child(label)
	add_child(toast)
	toast.modulate.a = 0.0
	toast.position.y -= 8
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(toast, "modulate:a", 1.0, 0.15)
	tween.tween_property(toast, "position:y", toast.position.y + 8, 0.18).set_trans(Tween.TRANS_QUAD)
	tween.set_parallel(false)
	tween.tween_interval(2.0)
	tween.tween_property(toast, "modulate:a", 0.0, 0.28)
	tween.tween_callback(toast.queue_free)

func _panel_container(color, radius, border_color = Color.TRANSPARENT, border_width = 0):
	var panel = PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _style(color, radius, border_color, border_width))
	return panel

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
	return style

func _inside_margin(horizontal, vertical):
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", horizontal)
	margin.add_theme_constant_override("margin_right", horizontal)
	margin.add_theme_constant_override("margin_top", vertical)
	margin.add_theme_constant_override("margin_bottom", vertical)
	return margin

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
	button.custom_minimum_size.y = 52 if mobile_mode else 36
	button.add_theme_font_size_override("font_size", 14 if mobile_mode else 12)
	var normal_color = Color(0.05, 0.18, 0.21, 0.92)
	var hover_color = Color(0.07, 0.28, 0.29, 1.0)
	var font_color = INK
	var border = Color(0.15, 0.43, 0.45, 0.7)
	if kind == "primary" or kind == "active":
		normal_color = Color(0.06, 0.35, 0.33, 0.95)
		hover_color = Color(0.08, 0.48, 0.43, 1.0)
		border = Color(TEAL, 0.8)
	elif kind == "gold":
		normal_color = Color(0.38, 0.28, 0.09, 0.95)
		hover_color = Color(0.52, 0.38, 0.10, 1.0)
		font_color = Color("ffe6a6")
		border = Color(GOLD, 0.75)
	elif kind == "danger":
		normal_color = Color(0.38, 0.14, 0.17, 0.95)
		hover_color = Color(0.53, 0.18, 0.20, 1.0)
		font_color = Color("ffd0d2")
		border = Color(RED, 0.75)
	elif kind == "ghost":
		normal_color = Color(0.03, 0.10, 0.13, 0.6)
		hover_color = Color(0.06, 0.20, 0.23, 0.95)
		border = Color(0.14, 0.31, 0.35, 0.65)
	button.add_theme_color_override("font_color", font_color)
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.add_theme_color_override("font_pressed_color", Color.WHITE)
	button.add_theme_color_override("font_disabled_color", DIM)
	button.add_theme_stylebox_override("normal", _style(normal_color, 9, border, 1, 8))
	button.add_theme_stylebox_override("hover", _style(hover_color, 9, border.lightened(0.18), 1, 8))
	button.add_theme_stylebox_override("pressed", _style(hover_color.darkened(0.1), 9, border, 1, 8))
	button.add_theme_stylebox_override("disabled", _style(Color(0.03, 0.07, 0.09, 0.75), 9, Color(0.1, 0.16, 0.18, 0.5), 1, 8))
	return button

func _progress_bar(color):
	var bar = ProgressBar.new()
	bar.custom_minimum_size.y = 8
	bar.show_percentage = false
	bar.add_theme_stylebox_override("background", _style(Color(0.02, 0.06, 0.08, 0.9), 5))
	bar.add_theme_stylebox_override("fill", _style(color, 5))
	return bar

func _section_heading(title, overline):
	var row = HBoxContainer.new()
	row.add_child(_label(title, 15, INK))
	var spacer = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(spacer)
	row.add_child(_label(overline, 9, DIM))
	return row

func _small_caption(text):
	var label = _label(text.to_upper(), 10, DIM)
	label.add_theme_constant_override("outline_size", 0)
	return label

func _thin_line():
	var line = ColorRect.new()
	line.color = LINE
	line.custom_minimum_size.y = 1
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return line

func _stat_row(parent, name, value, value_color):
	var row = HBoxContainer.new()
	parent.add_child(row)
	row.add_child(_label(name, 12, MUTED))
	var spacer = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(spacer)
	var value_label = _label(value, 13, value_color)
	row.add_child(value_label)
	return value_label

func _empty_state(text):
	var label = _label(text, 13, MUTED)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.custom_minimum_size.y = 120
	label.add_theme_stylebox_override("normal", _style(Color(0.035, 0.10, 0.13, 0.75), 12, LINE, 1, 16))
	return label

func _rarity_color(rarity):
	match rarity:
		"优秀": return Color("72c9d4")
		"珍稀": return Color("b79aff")
		"史诗": return Color("f1c66d")
		"补给": return Color("85c98d")
		"稀有补给": return Color("64d6aa")
		"未知": return Color("d7b878")
		_: return Color("c0d0d4")

func _stats_text(stats):
	var parts = []
	if int(stats.get("attack", 0)) != 0:
		parts.append("攻击+%d" % int(stats.attack))
	if int(stats.get("defense", 0)) != 0:
		parts.append("防御+%d" % int(stats.defense))
	if int(stats.get("max_hp", 0)) != 0:
		parts.append("体力+%d" % int(stats.max_hp))
	if int(stats.get("speed", 0)) != 0:
		parts.append("敏捷+%d" % int(stats.speed))
	return " · ".join(parts)

func _clear_children(node):
	for child in node.get_children():
		child.queue_free()
