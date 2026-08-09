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

	# 无道具奖励的贸易任务不得使完整日志报错。
	scene.state.quest_index = 8
	scene.state.quest_progress = 0
	scene._open_quest_detail()
	_check(_has_text(scene.modal_layer, "扬帆拉古萨") and _has_text(scene.modal_layer, "第一卷进度") and _has_text(scene.modal_layer, "剧情回顾") and _has_text(scene.modal_layer, "400 经验"), "完整日志必须显示章节进度与剧情回顾，并安全显示无道具奖励的任务")
	scene._close_modal()

	scene.state.inventory["ghost_card"] = 1
	scene.state.inventory["warrior_blade"] = 1
	scene._open_inventory()
	_check(_has_button(scene.modal_layer, "启用") and _has_button(scene.modal_layer, "一键穿戴推荐装备") and _has_text(scene.modal_layer, "持有银币"), "完整日志背包必须显示钱包、装备推荐并允许启用怪物卡")
	scene._equip_card_from_inventory("ghost_card")
	await process_frame
	_check(scene.state.active_card == "ghost_card" and _has_text(scene.modal_layer, "当前怪物卡"), "完整日志必须显示已启用怪物卡")
	scene._close_modal()

	scene.state.quest_index = GameData.QUESTS.size()
	scene.state.bounty_progress = int(scene.state.get_bounty().need)
	scene._open_quest_detail()
	_check(_has_text(scene.modal_layer, "第一卷") and _has_button(scene.modal_layer, "领取悬赏奖励"), "完整日志在主线结束后必须衔接循环悬赏")
	scene._close_modal()

	scene.state.player.location = "venice_dock"
	scene.state.player.silver = 1000
	scene._open_harbor()
	_check(_has_text(scene.modal_layer, "持有银币") and _has_text(scene.modal_layer, "浮动盈亏") and _has_text(scene.modal_layer, "商会推荐") and _has_text(scene.modal_layer, "商会委托") and _has_button(scene.modal_layer, "买满") and _has_button(scene.modal_layer, "全卖") and _has_button(scene.modal_layer, "加固船体"), "完整日志的贸易页必须包含钱包、盈亏、批量交易、商路推荐、循环委托与船体改造")

	if failures.is_empty():
		print("JOURNAL_OK: 完整日志的任务、怪物卡、悬赏与贸易入口全部通过")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _has_text(node, fragment):
	if not is_instance_valid(node):
		return false
	if node is Label and fragment in node.text:
		return true
	for child in node.get_children():
		if _has_text(child, fragment):
			return true
	return false

func _has_button(node, fragment):
	if not is_instance_valid(node):
		return false
	if node is Button and fragment in node.text:
		return true
	for child in node.get_children():
		if _has_button(child, fragment):
			return true
	return false

func _check(condition, message):
	if not condition:
		failures.append(message)
