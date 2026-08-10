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
	_check(_has_text(scene.modal_layer, "扬帆拉古萨") and _has_text(scene.modal_layer, "第一卷·潮汐纪事") and _has_text(scene.modal_layer, "剧情回顾") and _has_text(scene.modal_layer, "400 经验"), "完整日志必须显示分卷章节进度与剧情回顾，并安全显示无道具奖励的任务")
	scene._close_modal()

	scene.state.inventory["ghost_card"] = 1
	scene.state.inventory["warrior_blade"] = 1
	scene._open_inventory()
	_check(_has_button(scene.modal_layer, "启用") and _has_button(scene.modal_layer, "一键穿戴推荐装备") and _has_text(scene.modal_layer, "持有银币"), "完整日志背包必须显示钱包、装备推荐并允许启用怪物卡")
	scene._equip_card_from_inventory("ghost_card")
	await process_frame
	_check(scene.state.active_card == "ghost_card" and _has_text(scene.modal_layer, "当前怪物卡"), "完整日志必须显示已启用怪物卡")
	scene._close_modal()
	scene.state.player.location = "venice_market"
	scene.state.player.silver = 500
	scene._open_vendor_shop("jeweler")
	_check(_has_text(scene.modal_layer, "贝里昂珠宝铺") and _has_text(scene.modal_layer, "红珊瑚指环") and _has_button(scene.modal_layer, "购买"), "完整日志中的珠宝商也必须打开真实珠宝货柜")
	scene._buy_from_vendor("jeweler", "coral_ring")
	await process_frame
	_check(int(scene.state.inventory.get("coral_ring", 0)) == 1, "完整日志购买珠宝必须同步背包")
	scene._close_modal()

	scene.state.quest_index = GameData.QUESTS.size()
	scene.state.bounty_progress = int(scene.state.get_bounty().need)
	scene._open_quest_detail()
	_check(_has_text(scene.modal_layer, "第十三卷") and _has_button(scene.modal_layer, "领取悬赏奖励"), "完整日志在第十三卷结束后必须衔接循环悬赏")
	scene._close_modal()

	scene.state.player.location = "venice_dock"
	scene.state.player.silver = 1000
	scene._open_harbor()
	_check(_has_text(scene.modal_layer, "持有银币") and _has_text(scene.modal_layer, "浮动") and _has_text(scene.modal_layer, "商会推荐") and _has_text(scene.modal_layer, "商会订单") and _has_text(scene.modal_layer, "总声望") and _has_button(scene.modal_layer, "护航物资") and _has_button(scene.modal_layer, "买满") and _has_button(scene.modal_layer, "全卖") and _has_button(scene.modal_layer, "加固船体"), "完整日志贸易页必须包含钱包、订单声望、护航、批量交易、商路推荐与船体改造")
	_check(_has_text(scene.modal_layer, "交易商人｜蕾娜") and _has_text(scene.modal_layer, "本港特产｜威尼斯玻璃") and not _has_text(scene.modal_layer, "石墙羊毛布"), "完整日志中的威尼斯货栈只能展示本地货单，不能混入其他城市特产")
	scene._close_modal()
	scene.state.player.location = "venice_mine"
	scene._open_harbor()
	_check(str(scene.state.player.location) == "venice_mine" and _has_text(scene.modal_layer, "这里不是港口") and _has_button(scene.modal_layer, "步行前往码头"), "完整日志在野外打开贸易时不能把角色瞬移到威尼斯码头")
	scene._close_modal()
	scene.state.player.location = "malta_dock"
	scene.state.cargo = {"citrus": 2, "olive_oil": 1, "spices": 1}
	scene._open_harbor()
	_check(_has_text(scene.modal_layer, "马耳他港口市场") and _has_text(scene.modal_layer, "交易商人｜伊莎贝拉") and _has_text(scene.modal_layer, "本港特产｜金岛柑橘") and _has_text(scene.modal_layer, "港口厨房") and _has_text(scene.modal_layer, "亚得里亚橄榄油 1/1（拉古萨）") and _has_text(scene.modal_layer, "亚历山大香料 1/1（亚历山大）") and _has_button(scene.modal_layer, "烹制"), "马耳他贸易页必须显示当地特产，并明确标出厨房原料的跨港采购地")

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
