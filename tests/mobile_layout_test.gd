extends SceneTree

class TestState extends GameState:
	func has_save():
		return false

	func save_game():
		pass

var failures = []

func _init():
	call_deferred("_run")

func _run():
	var scene = load("res://scenes/main.tscn").instantiate()
	scene.state = TestState.new()
	root.add_child(scene)
	await process_frame
	await process_frame
	scene._close_modal()

	_check(scene.mobile_mode, "720×1280窗口必须启用手机布局")
	_check(scene.mobile_pages.size() == 3, "手机布局必须创建人物、地点和任务三个页面")
	_check(scene.mobile_nav_buttons.size() == 3, "手机底栏必须创建三个页面切换按钮")
	_check(is_instance_valid(scene.nav_inventory_button), "手机底栏必须保留背包入口")
	_check(scene.main_margin.size.x <= scene.get_viewport_rect().size.x, "手机主容器不能超出视口宽度：容器%s/视口%s" % [scene.main_margin.size, scene.get_viewport_rect().size])
	_check(scene.main_margin.size.y <= scene.get_viewport_rect().size.y, "手机主容器不能超出视口高度：容器%s/视口%s" % [scene.main_margin.size, scene.get_viewport_rect().size])

	scene._switch_mobile_tab("profile")
	_check(scene.mobile_pages.profile.visible, "人物页必须能够切换显示")
	scene._switch_mobile_tab("quest")
	_check(scene.mobile_pages.quest.visible, "任务页必须能够切换显示")
	scene._switch_mobile_tab("location")
	_check(scene.mobile_pages.location.visible, "地点页必须能够切换显示")

	var touch_button = scene._button("触控测试", "primary")
	_check(touch_button.custom_minimum_size.y >= 52.0, "手机触控按钮高度不得小于52")
	touch_button.free()

	scene.state.player.location = "venice_north_gate"
	scene.state.start_battle("drunk_sailor")
	scene.refresh_ui()
	scene._show_battle_screen(scene.state.get_battle_view())
	await process_frame
	_check(is_instance_valid(scene.modal_layer), "手机战斗页必须正常创建")
	_check(scene.modal_layer.size.x <= scene.get_viewport_rect().size.x, "手机战斗遮罩不能超出视口宽度：遮罩%s/视口%s" % [scene.modal_layer.size, scene.get_viewport_rect().size])
	scene.state.active_battle = {}
	scene._close_modal()
	scene.state.quest_index = 0
	scene.state.quest_progress = 1
	scene._show_quest_completion_prompt()
	await process_frame
	_check(is_instance_valid(scene.modal_layer), "任务达成后必须能在手机端主动创建领奖弹窗")
	_check(_has_button_text(scene.modal_layer, "领取全部奖励"), "手机领奖弹窗必须提供明确的领取按钮")
	scene._close_modal()

	scene.state.quest_index = GameData.QUESTS.size()
	scene.state.quest_progress = 0
	scene.state.player.location = "venice_dock"
	scene.refresh_ui()
	scene._open_harbor()
	await process_frame
	_check(is_instance_valid(scene.modal_layer), "手机端必须能打开货物贸易页面")
	_check(_has_button_text(scene.modal_layer, "买1"), "货物贸易页面必须显示买入操作")
	_check(_has_button_text(scene.modal_layer, "拉古萨"), "货物贸易页面必须显示跨港航线")
	scene._close_modal()

	var world_scene = load("res://scenes/world_2d.tscn").instantiate()
	world_scene.state = TestState.new()
	world_scene.state.quest_index = GameData.QUESTS.size()
	world_scene.state.player.location = "venice_dock"
	root.add_child(world_scene)
	await process_frame
	await process_frame
	world_scene._open_sailing_map()
	await process_frame
	_check(is_instance_valid(world_scene.overlay) and is_instance_valid(world_scene.sailing_map), "手机2D模式必须能打开九港可视化航海图")
	_check(world_scene.sailing_map.custom_minimum_size.x <= 620.0 and world_scene.sailing_map.custom_minimum_size.y <= 520.0, "九港航海图必须保持在竖屏触控区域内")
	_check(world_scene.sailing_map.port_buttons.size() == 9, "手机航海图必须显示九座可点击港口")

	if failures.is_empty():
		print("MOBILE_OK: 竖屏单栏、任务领奖弹窗、触控战斗、九港航海图与货物贸易页面全部通过")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _check(condition, message):
	if not condition:
		failures.append(message)

func _has_button_text(node, text_fragment):
	if not is_instance_valid(node):
		return false
	if node is Button and text_fragment in node.text:
		return true
	for child in node.get_children():
		if _has_button_text(child, text_fragment):
			return true
	return false
