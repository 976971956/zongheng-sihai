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
	_check(scene.player_actor.art_sprite.hframes == 4 and scene.player_actor.art_sprite.vframes == 2, "主角必须使用多帧2D行走图集")
	scene.player_actor.set_motion(Vector2.RIGHT)
	scene.player_actor._process(0.16)
	var first_walk_frame = scene.player_actor.art_sprite.frame
	scene.player_actor._process(0.16)
	_check(scene.player_actor.art_sprite.frame != first_walk_frame, "主角移动时必须循环播放迈步帧而不是整图平移")
	scene.player_actor.set_motion(Vector2.UP)
	scene.player_actor._process(0.16)
	_check("player_walk_back_v1" in str(scene.player_actor.art_sprite.texture.resource_path), "主角向上走时必须切换为背面步态")
	scene.player_actor.set_motion(Vector2.ZERO)
	_check(scene.actors.size() >= 4, "地图必须包含NPC和可见敌人")
	_check(scene.player_actor.position.x > 0 and scene.player_actor.position.y > 0, "玩家必须出生在可行走地图内")
	var saved_respawn_key = scene._enemy_spawn_key("drunk_sailor")
	scene.state.enemy_respawns[saved_respawn_key] = scene._world_time_seconds() + 60.0
	scene._spawn_world_actors()
	_check(not _has_actor(scene, "drunk_sailor"), "重建地图时必须继续遵守存档中的怪物刷新倒计时")
	scene.state.enemy_respawns.erase(saved_respawn_key)
	scene._spawn_world_actors()
	_check(_has_actor(scene, "drunk_sailor"), "没有刷新冷却时必须正常生成怪物")
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
	scene.state.inventory["ghost_card"] = 1
	scene._open_inventory()
	_check(_has_button_text(scene.overlay, "启用"), "2D背包必须允许启用怪物卡")
	scene._equip_card_2d("ghost_card")
	await process_frame
	_check(scene.state.active_card == "ghost_card" and _has_button_text(scene.overlay, "已启用"), "怪物卡启用后必须更新实际状态和背包显示")
	scene._close_overlay()

	# Every mid/late-game objective must exist in a reachable 2D region.
	scene.state.quest_index = 4
	scene.state.quest_progress = 0
	scene.state.player.level = 3
	var navigation_start_position = scene.player_actor.position
	scene._navigate_to_quest()
	_check(scene.task_navigation_active and scene.current_region == "city" and scene.player_actor.position.distance_to(navigation_start_position) < 1.0, "点击任务导航后必须从当前位置开始走，不能直接跳到目标区域")
	await _walk_task_navigation(scene)
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
	_check(scene.task_navigation_active and scene.current_region == "field", "副本导航必须先步行寻找入口，不能立即切换地图")
	await _walk_task_navigation(scene)
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
	_check(scene.task_navigation_active and scene.current_region == "field", "黑帆导航必须先沿道路返回港口，不能跨区域瞬移")
	await _walk_task_navigation(scene)
	_check(scene.current_region == "black_sail" and str(scene.state.player.location) == "black_sail_1", "黑帆密令导航必须进入第二座四层副本")
	_check(_has_actor(scene, "corsair_deckhand") and not _has_actor(scene, "corsair_captain"), "黑帆据点只能显示当前已解锁敌人")
	_check(scene._dungeon_floor_lock("black_sail_2") != "", "未击败黑帆水手时火药仓必须锁定")
	scene.state.dungeon_cleared["corsair_deckhand"] = true
	scene._spawn_world_actors()
	_check(_has_actor(scene, "corsair_raider") and not _has_actor(scene, "corsair_deckhand"), "击败外围水手后必须只生成火药仓掠夺者")
	_check(scene._dungeon_floor_lock("black_sail_2") == "", "击败黑帆水手后火药仓必须开放")
	scene._switch_region("city", "venice_dock")
	_check(scene.state.dungeon_cleared.is_empty(), "离开黑帆据点后必须重置逐层进度")

	scene.state.quest_index = 32
	scene.state.quest_progress = 0
	scene.state.player.level = 20
	scene._switch_region("city", "malta_dock")
	_check(_has_actor(scene, "malta_keeper") and _has_actor(scene, "white_whale"), "第三卷到达马耳他后必须生成守钟人与白鲸残骸入口")
	scene._navigate_to_quest()
	_check(scene.task_navigation_active and scene.current_region == "city", "白鲸残骸导航必须从马耳他港步行寻找入口")
	await _walk_task_navigation(scene)
	_check(scene.current_region == "white_whale" and str(scene.state.player.location) == "white_whale_1", "白鲸任务导航必须进入残骸一层")
	_check(_has_actor(scene, "wreck_crab") and not _has_actor(scene, "abyss_siren"), "白鲸残骸只能显示当前已解锁敌人")
	_check(scene._dungeon_floor_lock("white_whale_2") != "", "未击败覆甲礁蟹时沉水甲板必须锁定")
	scene.state.dungeon_cleared["wreck_crab"] = true
	scene._spawn_world_actors()
	_check(_has_actor(scene, "drowned_sailor") and scene._dungeon_floor_lock("white_whale_2") == "", "击败覆甲礁蟹后必须生成下一层敌人并开放道路")

	# 第四至第十三卷的远征入口必须随当前任务在对应港口出现，并通过步行进入。
	scene._close_overlay()
	scene.state.quest_index = 41
	scene.state.quest_progress = 0
	scene.state.player.level = 30
	scene._switch_region("city", "cape_town_dock")
	_check(_has_actor(scene, "cape_keeper") and _has_actor(scene, "legacy"), "第四卷到达开普敦后必须生成向导与聚宝盆远征入口")
	var legacy_start_position = scene.player_actor.position
	scene._navigate_to_quest()
	_check(scene.task_navigation_active and scene.current_region == "city" and scene.player_actor.position.distance_to(legacy_start_position) < 1.0, "终局远征导航必须从港口步行寻找入口")
	await _walk_task_navigation(scene)
	_check(scene.current_region == "legacy" and str(scene.state.player.location) == "legacy_basin", "聚宝盆任务导航必须步行进入北河遗迹")
	_check(_has_actor(scene, "basin_leviathan"), "聚宝盆远征必须生成带等级与血量的专属Boss")
	scene._close_overlay()

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
	_check(float(scene.state.enemy_respawns.get(respawn_key, 0.0)) > scene._world_time_seconds(), "怪物消失后必须把刷新倒计时写入存档状态")
	var early_retry = scene.state.start_battle("drunk_sailor")
	_check(not bool(early_retry.get("ok", true)) and float(early_retry.get("respawn_remaining", 0.0)) > 0.0, "刷新冷却必须在核心战斗状态中阻止提前重复挑战")
	scene.state.enemy_respawns[respawn_key] = scene._world_time_seconds() - 0.1
	scene._try_respawn_enemy("drunk_sailor")
	_check(not _has_actor(scene, "drunk_sailor"), "战斗结算页未关闭时怪物不能在背后刷新")
	scene._close_overlay()
	scene.player_actor.position = scene._spawn_for_location("venice_tavern")
	scene._try_respawn_enemy("drunk_sailor")
	_check(_has_actor(scene, "drunk_sailor"), "倒计时结束且玩家离开出生点后怪物必须重新出现")

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
	_check(_has_button_text(scene.overlay, "买1") and _has_button_text(scene.overlay, "买满") and _has_button_text(scene.overlay, "全卖") and _has_button_text(scene.overlay, "拉古萨") and _has_button_text(scene.overlay, "交付订单") and _has_button_text(scene.overlay, "护航物资") and _has_label_text(scene.overlay, "持有银币") and _has_label_text(scene.overlay, "总声望") and _has_label_text(scene.overlay, "今日行情"), "2D港口市场必须包含资产、批量买卖、订单声望、护航、跨港航线和动态行情")
	var silver_before = int(scene.state.player.silver)
	scene._trade_buy_2d("venetian_glass")
	_check(int(scene.state.cargo.get("venetian_glass", 0)) == 1 and int(scene.state.player.silver) < silver_before, "2D市场买货必须同步货舱和银币")
	scene.state.player.silver = 1000
	var armor_upgrade = scene.state.upgrade_ship("armor")
	_check(bool(armor_upgrade.get("ok", false)) and int(scene.state.ship.get("armor", 0)) == 1, "船只必须可以加固护甲并降低航线风险")
	var sail_result = scene.state.sail_to("ragusa_dock")
	_check(bool(sail_result.get("ok", false)) and sail_result.has("event") and int(sail_result.get("risk", 99)) < int(GameData.trade_route("venice_dock", "ragusa_dock").risk), "航行必须结算随机事件，船体护甲必须降低风险")
	scene.state.cargo["venetian_glass"] = 2
	scene.state.cargo_costs["venetian_glass"] = 48
	var order_result = scene.state.claim_trade_order()
	_check(bool(order_result.get("ok", false)) and scene.state.port_reputation_value("ragusa_dock") == 2 and scene.state.trade_order_cycles["ragusa_dock"] == 1, "港口订单必须消耗指定货物、奖励声望并轮换下一单")
	var risk_without_protection = scene.state.voyage_risk("venice_dock")
	var protection_result = scene.state.buy_voyage_protection()
	_check(bool(protection_result.get("ok", false)) and scene.state.voyage_risk("venice_dock") < risk_without_protection, "护航物资必须降低下一次航行风险")
	scene.state.trade_profit = 120
	var unknown_before = int(scene.state.inventory.get("unknown_equipment", 0))
	var contract_result = scene.state.claim_trade_contract()
	_check(bool(contract_result.get("ok", false)) and int(scene.state.inventory.get("unknown_equipment", 0)) == unknown_before + 1, "贸易利润必须推进商会委托并可以领取成长奖励")
	_check(scene.state.trade_contract_count == 1 and scene.state.trade_contract_target() == 180 and scene.state.trade_contract_progress() == 0, "商会委托领取后必须自动开启更高目标的下一轮")
	_check(not scene.state.best_trade_opportunity().is_empty(), "港口必须能计算一条可见的动态商路推荐")

	# 九港复用同一港区地图，但重新加载或走入码头视觉区域时不能篡改真实所在港口。
	scene.state.quest_index = GameData.QUESTS.size()
	scene.state.player.location = "alexandria_dock"
	scene.current_region = "city"
	scene.current_zone = ""
	scene.player_actor.position = scene._spawn_for_location("alexandria_dock")
	scene._spawn_world_actors()
	scene._update_zone(true)
	_check(str(scene.state.player.location) == "alexandria_dock" and _has_actor(scene, "alexandria_merchant"), "亚历山大港重新进入2D地图后必须保留港口位置和当地商人")
	scene.player_actor.position = _actor_position(scene, "alexandria_merchant")
	scene._update_nearest_actor()
	scene._interact()
	_check(_has_label_text(scene.overlay, "亚历山大港口市场") and _has_button_text(scene.overlay, "交付订单"), "非对话任务时点击亚历山大商人必须直接打开当地港口市场")
	scene._close_overlay()

	var boss_state = TestState.new()
	boss_state.player.level = 5
	boss_state.player.location = "training_dungeon_4"
	boss_state.player.hp = boss_state.get_stats().max_hp
	boss_state.start_battle("vermilion_phantom")
	boss_state.active_battle.round = 3
	_check("赤焰风暴" in boss_state.get_enemy_intent(), "Boss特殊技能必须在发动前显示蓄力预警")
	boss_state.active_battle.focus = 3
	var skill_result = boss_state.skill_attack()
	_check(bool(skill_result.get("ok", false)) and int(skill_result.get("focus", -1)) == 0 and "破浪斩" in "".join(skill_result.get("logs", [])), "蓄力满后必须可释放破浪斩并消耗全部专注")

	scene.state.quest_index = GameData.QUESTS.size()
	scene.state.bounty_index = 0
	scene.state.bounty_progress = 3
	scene._open_quest()
	_check(_has_label_text(scene.overlay, "第十三卷·封印迷阵") and _has_label_text(scene.overlay, "剧情回顾") and _has_button_text(scene.overlay, "领取悬赏奖励"), "主线结束后任务页必须显示第十三卷进度、剧情回顾和可持续领取的悬赏")

	if failures.is_empty():
		print("WORLD_2D_OK: 移动导航、十三座远征、自动战斗、怪物刷新、九港贸易与厨房全部通过")
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

func _walk_task_navigation(scene):
	for step in range(900):
		if not scene.task_navigation_active:
			return
		scene._process(0.08)
		if step % 20 == 0:
			await process_frame
	_check(false, "任务自动寻路必须在合理时间内抵达，不能撞墙卡死（区域%s，位置%s，目标%s）" % [scene.current_region, scene.player_actor.position, scene.move_target])

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
