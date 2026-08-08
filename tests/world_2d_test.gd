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
	var scene = load("res://scenes/world_2d.tscn").instantiate()
	scene.state = TestState.new()
	root.add_child(scene)
	await process_frame
	await process_frame

	_check(is_instance_valid(scene.world_layer), "2D世界地图必须成功创建")
	_check(is_instance_valid(scene.player_actor), "2D玩家角色必须成功创建")
	_check(scene.player_actor.display_id == "player", "主角必须使用独立的新版角色模型")
	_check(scene.actors.size() >= 4, "地图必须包含NPC和可见敌人")
	_check(scene.player_actor.position.x > 0 and scene.player_actor.position.y > 0, "玩家必须出生在可行走地图内")
	var touch = InputEventScreenTouch.new()
	touch.pressed = true
	touch.position = Vector2(360, 500)
	scene._gui_input(touch)
	_check(scene.has_move_target and scene.move_target == scene.world_layer.to_local(touch.position), "手机点击地面必须转换并写入世界移动目标")
	var before_move = scene.player_actor.position
	scene._process(0.25)
	_check(scene.player_actor.position.distance_to(before_move) > 1.0, "点击地面后玩家角色必须实际移动")
	scene.has_move_target = false
	scene.player_actor.position = scene._spawn_for_location("venice_square")
	var stick_press = InputEventScreenTouch.new()
	stick_press.index = 2
	stick_press.pressed = true
	stick_press.position = Vector2(160, 90)
	scene.joystick._gui_input(stick_press)
	_check(scene.joystick_direction.x > 0.8, "底部摇杆向右拖动必须产生方向输入")
	var joystick_before = scene.player_actor.position
	scene._process(0.2)
	_check(scene.player_actor.position.x > joystick_before.x, "摇杆输入必须实际推动角色移动")
	var stick_release = InputEventScreenTouch.new()
	stick_release.index = 2
	stick_release.pressed = false
	stick_release.position = Vector2(160, 90)
	scene.joystick._gui_input(stick_release)
	_check(scene.joystick_direction == Vector2.ZERO, "松开摇杆后角色方向必须归零")
	scene.player_actor.position = _actor_position(scene, "alisa")

	scene._update_nearest_actor()
	_check(not scene.nearest_actor.is_empty() and scene.nearest_actor.id == "alisa", "开局应能靠近艾丽莎互动")
	scene._interact()
	_check(scene.state.quest_progress == 1, "2D NPC交谈必须推进原有任务状态")
	_check(is_instance_valid(scene.overlay), "NPC交谈必须显示2D对话面板")
	scene._close_then_claim()
	await process_frame
	_check(scene.state.quest_can_claim(), "结束任务对话后必须弹出领奖流程")
	scene._claim_quest_2d()
	_check(scene.state.quest_index == 1, "2D领奖必须进入下一任务")
	scene._close_overlay()

	# The 2D backpack must expose and execute real item actions.
	scene.state.inventory["warrior_blade"] = 1
	scene._open_inventory()
	_check(_has_button_text(scene.overlay, "装备") and _has_button_text(scene.overlay, "使用"), "2D背包必须显示装备与使用按钮")
	scene._equip_item_2d("warrior_blade")
	await process_frame
	_check(str(scene.state.equipment.weapon) == "warrior_blade", "点击装备必须更新角色装备槽")
	var item_count_before = int(scene.state.inventory.get("small_milk", 0))
	var max_hp = int(scene.state.get_stats().max_hp)
	scene.state.player.hp = max_hp - 50
	scene._use_item_2d("small_milk")
	await process_frame
	_check(int(scene.state.player.hp) > max_hp - 50 and int(scene.state.inventory.get("small_milk", 0)) == item_count_before - 1, "点击使用药品必须恢复体力并消耗一件物品")
	scene._close_overlay()

	# Every mid/late-game objective must exist in a reachable 2D region.
	scene.state.quest_index = 4
	scene.state.quest_progress = 0
	scene.state.player.level = 3
	scene._navigate_to_quest()
	_check(scene.current_region == "field" and scene.state.player.location == "venice_mine", "失窃矿石任务导航必须进入城外废矿山")
	_check(_has_actor(scene, "mine_thief"), "城外2D地图必须实际生成偷矿者")
	_check(_actor_model_id(scene, "mine_thief") == "mine_thief", "不同敌人必须绑定各自的新版人物或怪物模型")
	scene._update_nearest_actor()
	_check(not scene.nearest_actor.is_empty() and scene.nearest_actor.id == "mine_thief", "导航抵达矿山后必须能直接找到任务敌人")

	scene.state.quest_index = 6
	scene.state.quest_progress = 0
	scene.state.player.level = 4
	scene.state.dungeon_cleared = {}
	scene._navigate_to_quest()
	_check(scene.current_region == "dungeon" and scene.state.player.location == "training_dungeon_1", "四层试炼导航必须从副本一层开始")
	_check(_has_actor(scene, "dungeon_guard") and not _has_actor(scene, "vermilion_phantom"), "四层副本只能显示当前已解锁守卫")
	_check(scene._dungeon_floor_lock("training_dungeon_2") != "", "未击败一层守卫时二层必须锁定")
	scene.state.dungeon_cleared["dungeon_guard"] = true
	scene._spawn_world_actors()
	_check(_has_actor(scene, "stone_puppet") and not _has_actor(scene, "dungeon_guard"), "击败一层后必须只生成二层石傀儡")
	_check(scene._dungeon_floor_lock("training_dungeon_2") == "", "击败一层守卫后二层必须开放")
	scene._switch_region("field", "residential_quarter")
	_check(scene.state.dungeon_cleared.is_empty(), "离开2D副本后必须重置逐层解锁状态")

	scene.state.quest_index = 12
	scene.state.quest_progress = 0
	scene.state.player.level = 8
	scene._navigate_to_quest()
	_check(scene.current_region == "black_sail" and str(scene.state.player.location) == "black_sail_1", "黑帆密令导航必须进入第二座四层副本")
	_check(_has_actor(scene, "corsair_deckhand") and not _has_actor(scene, "corsair_captain"), "黑帆据点只能显示当前已解锁敌人")
	_check(scene._dungeon_floor_lock("black_sail_2") != "", "未击败黑帆水手时火药仓必须锁定")
	scene.state.dungeon_cleared["corsair_deckhand"] = true
	scene._spawn_world_actors()
	_check(_has_actor(scene, "corsair_raider") and not _has_actor(scene, "corsair_deckhand"), "击败外围水手后必须只生成火药仓掠夺者")
	_check(scene._dungeon_floor_lock("black_sail_2") == "", "击败黑帆水手后火药仓必须开放")
	scene._switch_region("city", "venice_dock")
	_check(scene.state.dungeon_cleared.is_empty(), "离开黑帆据点后必须重置逐层进度")

	# Validate visible encounter -> side-view battle using the same production state.
	scene.state.quest_index = 3
	scene.state.quest_progress = 2
	scene.state.player.level = 5
	scene.state.player.hp = scene.state.get_stats().max_hp
	scene._switch_region("city", "venice_north_gate")
	scene.player_actor.position = _actor_position(scene, "drunk_sailor")
	scene._update_nearest_actor()
	_check(scene.nearest_actor.id == "drunk_sailor", "靠近地图敌人后必须出现挑战交互")
	scene._interact()
	_check(is_instance_valid(scene.battle_stage), "地图遇敌后必须切换到2D战斗舞台")
	_check(is_instance_valid(scene.battle_stage.enemy_model) and scene.battle_stage.enemy_model.display_id == "drunk_sailor", "战斗舞台必须沿用地图中的对应敌人模型")
	_check(_has_label_text(scene.overlay, "喝醉的水手 Lv.1") and _has_label_text(scene.overlay, "体力 42 / 42"), "战斗界面必须显示怪物等级与具体血量")
	scene._set_battle_stance_2d("assault")
	_check(scene.state.battle_stance == "assault" and _has_button_text(scene.overlay, "◆ 猛攻"), "战斗界面必须能切换并显示当前姿态")
	scene.state.battle_stance = "balanced"
	var medicine_before = int(scene.state.inventory.get("small_milk", 0))
	scene.state.player.hp = 20
	var supply = scene.state.auto_use_battle_supplies()
	_check(bool(supply.get("used", false)) and int(scene.state.player.hp) > 20 and int(scene.state.inventory.get("small_milk", 0)) <= medicine_before, "自动战斗必须按阈值使用补血道具")
	scene._battle_auto()
	_check(scene.auto_battle_running and scene.battle_result.is_empty(), "自动战斗必须逐回合播放，不能点击后瞬间跳到结算")
	await _wait_for_auto_battle(scene)
	_check(not scene.battle_result.is_empty() and bool(scene.battle_result.get("won", false)), "2D自动战斗必须正常结算胜利")
	_check(bool(scene.battle_result.get("quest_completed", false)), "最后一名任务敌人必须触发领奖引导")
	_check(not _has_actor(scene, "drunk_sailor"), "怪物被击败后必须立即从2D地图消失")
	var respawn_key = scene._enemy_spawn_key("drunk_sailor")
	_check(float(scene.enemy_respawn_deadlines.get(respawn_key, 0.0)) > scene._world_time_seconds(), "怪物消失后必须建立刷新倒计时")
	scene.enemy_respawn_deadlines[respawn_key] = scene._world_time_seconds() - 0.1
	scene._try_respawn_enemy("drunk_sailor")
	_check(_has_actor(scene, "drunk_sailor"), "刷新倒计时结束后怪物必须在原地图重新出现")
	scene._close_overlay()

	# A defeat must visibly finish at zero HP and return the player to the tavern map.
	scene.state.player.level = 1
	scene.state.player.hp = 1
	scene.state.equipment.weapon = ""
	scene.state.statuses = {"虚弱": 20}
	scene.state.auto_heal_threshold = 0
	scene.state.auto_cure_status = false
	scene._switch_region("city", "venice_north_gate")
	scene.player_actor.position = _actor_position(scene, "drunk_sailor")
	scene._update_nearest_actor()
	scene._interact()
	scene._battle_auto()
	await _wait_for_auto_battle(scene)
	_check(not scene.battle_result.is_empty() and not bool(scene.battle_result.get("won", true)) and int(scene.battle_result.get("player_hp", -1)) == 0, "战败结算必须记录角色体力归零")
	scene._finish_battle_overlay()
	await process_frame
	_check(scene.current_region == "city" and str(scene.state.player.location) == "venice_tavern", "战斗失败后必须返回威尼斯酒馆")
	_check(scene.player_actor.position.distance_to(scene._spawn_for_location("venice_tavern")) < 1.0, "战斗失败后角色必须出现在酒馆入口")
	_check(_has_label_text(scene.overlay, "已返回酒馆"), "返回酒馆后必须显示失败恢复说明")
	scene._close_overlay()

	scene.state.quest_index = GameData.QUESTS.size()
	scene.state.quest_progress = 0
	scene.state.player.location = "venice_dock"
	scene.state.player.silver = 500
	scene.state.equipment.weapon = "warrior_blade"
	var attack_before_upgrade = int(scene.state.get_stats().attack)
	var equipment_upgrade = scene.state.upgrade_equipped("weapon")
	_check(bool(equipment_upgrade.get("ok", false)) and scene.state.equipment_upgrade_level("warrior_blade") == 1 and int(scene.state.get_stats().attack) > attack_before_upgrade, "贸易银币必须可以用于强化已装备武器并提升属性")
	scene._open_trade_2d()
	_check(is_instance_valid(scene.overlay), "主线完成后必须能从2D地图打开港口市场")
	_check(_has_button_text(scene.overlay, "买1") and _has_button_text(scene.overlay, "拉古萨") and _has_label_text(scene.overlay, "今日行情"), "2D港口市场必须包含买卖、跨港航线和动态行情")
	var silver_before = int(scene.state.player.silver)
	scene._trade_buy_2d("venetian_glass")
	_check(int(scene.state.cargo.get("venetian_glass", 0)) == 1 and int(scene.state.player.silver) < silver_before, "2D市场买货必须同步货舱和银币")
	scene.state.player.silver = 1000
	var armor_upgrade = scene.state.upgrade_ship("armor")
	_check(bool(armor_upgrade.get("ok", false)) and int(scene.state.ship.get("armor", 0)) == 1, "船只必须可以加固护甲并降低航线风险")
	var sail_result = scene.state.sail_to("ragusa_dock")
	_check(bool(sail_result.get("ok", false)) and sail_result.has("event") and int(sail_result.get("risk", 99)) < int(GameData.trade_route("venice_dock", "ragusa_dock").risk), "航行必须结算随机事件，船体护甲必须降低风险")
	scene.state.trade_profit = 120
	var unknown_before = int(scene.state.inventory.get("unknown_equipment", 0))
	var contract_result = scene.state.claim_trade_contract()
	_check(bool(contract_result.get("ok", false)) and int(scene.state.inventory.get("unknown_equipment", 0)) == unknown_before + 1, "贸易利润必须推进商会委托并可以领取成长奖励")

	var boss_state = TestState.new()
	boss_state.player.level = 5
	boss_state.player.location = "training_dungeon_4"
	boss_state.player.hp = boss_state.get_stats().max_hp
	boss_state.start_battle("vermilion_phantom")
	boss_state.active_battle.round = 3
	_check("赤焰风暴" in boss_state.get_enemy_intent(), "Boss特殊技能必须在发动前显示蓄力预警")

	if failures.is_empty():
		print("WORLD_2D_OK: 移动、背包、任务、副本、逐回合自动战斗、战败回酒馆、怪物刷新与贸易全部通过")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _check(condition, message):
	if not condition:
		failures.append(message)

func _has_button_text(node, fragment):
	if not is_instance_valid(node):
		return false
	if node is Button and fragment in node.text:
		return true
	for child in node.get_children():
		if _has_button_text(child, fragment):
			return true
	return false

func _has_label_text(node, fragment):
	if not is_instance_valid(node):
		return false
	if node is Label and fragment in node.text:
		return true
	for child in node.get_children():
		if _has_label_text(child, fragment):
			return true
	return false

func _wait_for_auto_battle(scene):
	for _step in range(160):
		if not scene.auto_battle_running:
			return
		await create_timer(0.05).timeout

func _has_actor(scene, actor_id):
	for entry in scene.actors:
		if str(entry.id) == actor_id:
			return true
	return false

func _actor_model_id(scene, actor_id):
	for entry in scene.actors:
		if str(entry.id) == actor_id:
			return str(entry.node.display_id)
	return ""

func _actor_position(scene, actor_id):
	for entry in scene.actors:
		if str(entry.id) == str(actor_id):
			return entry.node.position
	return Vector2.ZERO
