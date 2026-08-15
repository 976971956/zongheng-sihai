extends SceneTree

const ActorScript = preload("res://scripts/actor_2d.gd")

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

	_check(is_instance_valid(scene.world_layer), "世界地图必须成功创建")
	_check(is_instance_valid(scene.player_actor), "玩家角色必须成功创建")
	_check(scene.player_actor.display_id == "player", "主角必须使用独立的新版角色模型")
	_check(scene.player_actor.art_sprite.hframes == 4 and scene.player_actor.art_sprite.vframes == 2, "主角必须使用多帧行走图集")
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
	_check(_has_actor(scene, "guard_captain") and _has_actor(scene, "jeweler") and _has_actor(scene, "venice_shipwright"), "威尼斯必须生成守卫、珠宝商与船匠，不能只存在于数据配置中")
	_check(_actor_has_art(scene, "guard_captain") and _actor_has_art(scene, "jeweler") and _actor_has_art(scene, "venice_shipwright"), "威尼斯补充NPC也必须使用完整人物精灵，不能回退到通用占位模型")
	var enemy_art_signatures = {}
	for enemy_id in GameData.ENEMIES:
		var enemy_model = ActorScript.new()
		root.add_child(enemy_model)
		enemy_model.configure("monster", Color("7aa6a1"), Color("f2c66d"), enemy_id)
		_check(is_instance_valid(enemy_model.art_sprite) and enemy_model.art_sprite.texture != null, "%s 必须拥有完整敌人精灵，不能回退到程序占位模型" % enemy_id)
		var signature = _actor_art_signature(enemy_model)
		_check(signature != "" and not enemy_art_signatures.has(signature), "%s 必须使用独立敌人造型，不能复用其他敌人模型" % enemy_id)
		enemy_art_signatures[signature] = enemy_id
		enemy_model.free()
	_check(scene.player_actor.position.x > 0 and scene.player_actor.position.y > 0, "玩家必须出生在可行走地图内")
	_check(_has_button_text(scene, "角色") and _has_button_text(scene, "背包") and _has_button_text(scene, "任务") and _has_button_text(scene, "地图") and _has_button_text(scene, "日志"), "手机底栏必须把角色与背包拆成独立入口")
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
	_check(scene.state.quest_progress == 1, "NPC交谈必须推进原有任务状态")
	_check(is_instance_valid(scene.overlay), "NPC交谈必须显示对话面板")
	scene._close_then_claim()
	await process_frame
	_check(scene.state.quest_can_claim(), "结束任务对话后必须弹出领奖流程")
	scene._claim_quest_2d()
	_check(scene.state.quest_index == 1, "领奖必须进入下一任务")
	scene._close_overlay()

	# The 2D backpack must expose and execute real item actions.
	scene.state.inventory["warrior_blade"] = 1
	scene._open_inventory()
	_check(_has_button_text(scene.overlay, "装备") and _has_button_text(scene.overlay, "使用"), "背包必须显示装备与使用按钮")
	_check(_has_label_text(scene.overlay, "物品背包") and _has_label_text(scene.overlay, "背包物品") and not _has_label_text(scene.overlay, "当前已装备") and _count_visuals(scene.overlay, "equipment") >= 1 and _count_visuals(scene.overlay, "consumable") >= 1, "物品背包必须只展示带模型的未装备物品，不能继续混入角色装备槽")
	scene._open_character()
	_check(_has_label_text(scene.overlay, "角色信息 · 已装备") and _has_label_text(scene.overlay, "当前已装备") and _has_named_node(scene.overlay, "CharacterPortrait") and _count_visuals(scene.overlay, "equipment") == 6 and not _has_label_text(scene.overlay, "背包物品"), "角色页必须独立展示人物立绘、属性和六个已装备槽，不能与背包混成同一列表")
	scene._open_inventory()
	scene._equip_item_2d("warrior_blade")
	await process_frame
	_check(str(scene.state.equipment.weapon) == "warrior_blade", "点击装备必须更新角色装备槽")
	scene._open_character()
	_check(_has_label_text(scene.overlay, "武士套装") and _has_label_text(scene.overlay, "套装共鸣") and _has_button_text(scene.overlay, "强化至 +1"), "角色装备页必须显示套装进度、分段共鸣和+10强化入口")
	scene._open_inventory()
	var item_count_before = int(scene.state.inventory.get("small_milk", 0))
	var max_hp = int(scene.state.get_stats().max_hp)
	scene.state.player.hp = max_hp - 50
	scene._use_item_2d("small_milk")
	await process_frame
	_check(int(scene.state.player.hp) > max_hp - 50 and int(scene.state.inventory.get("small_milk", 0)) == item_count_before - 1, "点击使用药品必须恢复体力并消耗一件物品")
	scene._close_overlay()
	scene.state.inventory["ghost_card"] = 1
	scene._open_inventory()
	_check(_has_button_text(scene.overlay, "启用"), "背包必须允许启用怪物卡")
	scene._equip_card_2d("ghost_card")
	await process_frame
	_check(scene.state.active_card == "ghost_card" and _has_button_text(scene.overlay, "已启用"), "怪物卡启用后必须更新实际状态和背包显示")
	scene._close_overlay()

	# 威尼斯的珠宝商与酒馆老板必须拥有各自独立、可真实购买的货柜。
	scene.state.quest_index = GameData.QUESTS.size()
	scene.state.player.silver = 500
	scene._switch_region("city", "venice_market")
	scene.player_actor.position = _actor_position(scene, "jeweler")
	scene._update_nearest_actor()
	_check("选购珠宝" in scene.action_button.text, "靠近珠宝商时互动按钮必须明确显示珠宝服务")
	scene._interact()
	_check(_has_label_text(scene.overlay, "贝里昂珠宝铺") and _has_label_text(scene.overlay, "红珊瑚指环") and _has_button_text(scene.overlay, "购买"), "珠宝商必须打开包含真实珠宝商品和价格的货柜")
	var jewel_silver_before = int(scene.state.player.silver)
	scene._buy_vendor_item_2d("jeweler", "coral_ring")
	await process_frame
	await process_frame
	_check(int(scene.state.inventory.get("coral_ring", 0)) == 1 and int(scene.state.player.silver) < jewel_silver_before, "购买珠宝必须扣除银币并放入背包")
	scene._close_overlay()
	scene._switch_region("city", "venice_tavern")
	scene.player_actor.position = _actor_position(scene, "tavern_keeper")
	scene._update_nearest_actor()
	_check("购买食物" in scene.action_button.text, "没有酒馆对话任务时互动按钮必须显示食物服务")
	scene._interact()
	_check(_has_label_text(scene.overlay, "老海鸥酒馆 · 恢复补给") and _has_label_text(scene.overlay, "海盐面包") and _has_label_text(scene.overlay, "香草鱼汤") and _has_label_text(scene.overlay, "万能药"), "酒馆老板必须独立出售食物与恢复药品，而不是只有对话")
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
	_check(not scene.has_move_target and scene.player_actor.motion_direction == Vector2.ZERO, "任务导航抵达目的地后必须清除目标并停止走路动画")
	_check(_has_actor(scene, "mine_thief"), "城外地图必须实际生成偷矿者")
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
	_check(scene.state.dungeon_cleared.is_empty(), "离开副本后必须重置逐层解锁状态")

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

	# 区域地图和贸易入口都必须尊重世界移动，不能悄悄改写角色位置。
	scene.state.quest_index = GameData.QUESTS.size()
	scene.state.player.location = "venice_square"
	scene._switch_region("city", "venice_square")
	var map_walk_start = scene.player_actor.position
	scene._travel_to_location("venice_mine")
	_check(scene.task_navigation_active and scene.current_region == "city" and str(scene.state.player.location) == "venice_square" and scene.player_actor.position.distance_to(map_walk_start) < 1.0, "区域地图必须启动真实步行导航，不能立即传送到目标地点")
	await _walk_task_navigation(scene)
	_check(scene.current_region == "field" and str(scene.state.player.location) == "venice_mine", "区域地图步行导航必须能够跨区域抵达废矿山")
	scene._open_trade_2d()
	_check(str(scene.state.player.location) == "venice_mine" and _has_label_text(scene.overlay, "这里不是港口"), "人在野外打开贸易时必须保留原位置并提示前往码头，不能暗中传送")
	scene._close_overlay()
	scene.state.player.location = "alexandria_dock"
	scene._switch_region("city", "alexandria_dock")
	scene._travel_to_location("venice_square")
	_check(str(scene.state.player.location) == "alexandria_dock" and not scene.task_navigation_active and _has_label_text(scene.overlay, "需要先乘船返航"), "远洋港口不能通过区域地图跳回威尼斯，必须先走航海路线")
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
	_check(is_instance_valid(scene.battle_stage), "地图遇敌后必须切换到战斗舞台")
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
	_check(not scene.battle_result.is_empty() and bool(scene.battle_result.get("won", false)), "自动战斗必须正常结算胜利")
	_check(bool(scene.battle_result.get("quest_completed", false)), "最后一名任务敌人必须触发领奖引导")
	_check(not _has_actor(scene, "drunk_sailor"), "怪物被击败后必须立即从地图消失")
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
	_check(is_instance_valid(scene.overlay), "主线完成后必须能从地图打开港口市场")
	_check(_has_button_text(scene.overlay, "买1") and _has_button_text(scene.overlay, "买满") and _has_button_text(scene.overlay, "全卖") and _has_button_text(scene.overlay, "打开商会订单柜台") and _has_label_text(scene.overlay, "银币") and _has_label_text(scene.overlay, "今日行情") and not _has_button_text(scene.overlay, "出航拉古萨") and not _has_button_text(scene.overlay, "强化舱板"), "货栈NPC必须只展示货物买卖和订单入口，不能混入航线或船只改造")
	_check(_has_named_node(scene.overlay, "CargoCapacityBar") and _count_visuals(scene.overlay, "trade") >= 1 and _has_label_text(scene.overlay, "货舱装载") and _has_label_text(scene.overlay, "推荐销往"), "市场必须以货舱容量条、货物图标和销地利润提示呈现，不能只有价格文字")
	_check(_has_label_text(scene.overlay, "蕾娜｜翼狮货栈") and _has_label_text(scene.overlay, "本港产地货栈 · 仅出售威尼斯玻璃") and not _has_label_text(scene.overlay, "石墙羊毛布"), "威尼斯必须由专属货栈NPC只出售本地货单，不能展示全球商品总目录")
	scene._close_overlay()
	scene._open_port_harbor_2d("ship_owner")
	_check(_has_label_text(scene.overlay, "威尼斯 · 港务处") and _has_button_text(scene.overlay, "出航拉古萨") and _has_button_text(scene.overlay, "护航物资") and _has_button_text(scene.overlay, "九港航海大地图") and not _has_button_text(scene.overlay, "买1"), "航务NPC必须只提供航线、出航与护航服务")
	scene._close_overlay()
	scene._open_port_shipyard_2d("venice_shipwright")
	_check(_has_label_text(scene.overlay, "威尼斯 · 船坞") and _has_button_text(scene.overlay, "强化舱板") and _has_button_text(scene.overlay, "强化帆装") and not _has_button_text(scene.overlay, "买1") and not _has_button_text(scene.overlay, "出航拉古萨"), "船匠NPC必须只提供买船和船装改造")
	scene._close_overlay()
	scene._open_trade_2d()
	var silver_before = int(scene.state.player.silver)
	scene._trade_buy_2d("venetian_glass")
	_check(int(scene.state.cargo.get("venetian_glass", 0)) == 1 and int(scene.state.player.silver) < silver_before, "市场买货必须同步货舱和银币")
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

	# 九座城市必须拥有独立主题、地标与人物站位，不能继续复用同一张码头背景。
	_check(GameData.PORT_CITY_MAPS.size() == GameData.TRADE_PORTS.size(), "每座贸易城市都必须配置完整城内地图")
	var city_styles = {}
	for city_port_id in GameData.TRADE_PORTS:
		var city_layout = GameData.PORT_CITY_MAPS.get(str(city_port_id), {})
		_check(not city_layout.is_empty() and str(city_layout.get("title", "")) != "" and str(city_layout.get("landmark", "")) != "" and Array(city_layout.get("districts", [])).size() >= 4, "%s必须拥有城市主题、地标和至少四个街区" % GameData.TRADE_PORTS[str(city_port_id)].name)
		city_styles[str(city_layout.get("style", ""))] = true
		var configured_positions = Dictionary(city_layout.get("npc_positions", {}))
		for city_npc_id in GameData.LOCATIONS[str(city_port_id)].npcs:
			_check(configured_positions.has(str(city_npc_id)), "%s的%s必须在城内地图配置独立站位" % [GameData.TRADE_PORTS[str(city_port_id)].name, GameData.NPCS[str(city_npc_id)].name])
	_check(city_styles.size() == GameData.TRADE_PORTS.size(), "九座城市必须使用九种可区分的美术主题")

	# 重新加载或走入远洋城市的视觉街区时不能篡改真实所在港口。
	scene.state.quest_index = GameData.QUESTS.size()
	scene.state.player.location = "alexandria_dock"
	scene.state.cargo["venetian_glass"] = 1
	scene.state.cargo_costs["venetian_glass"] = 24
	scene.current_region = "city"
	scene.current_zone = ""
	scene.player_actor.position = scene._spawn_for_location("alexandria_dock")
	scene._spawn_world_actors()
	scene._update_zone(true)
	_check(str(scene.state.player.location) == "alexandria_dock" and _has_actor(scene, "alexandria_merchant"), "亚历山大重新进入世界地图后必须保留城市位置和当地商人")
	_check(_has_actor(scene, "alex_harbormaster") and _has_actor(scene, "alex_lighthouse_keeper") and _has_actor(scene, "alex_shipwright"), "远洋港口必须同时生成货栈、港务、商会和船匠，不能把服务合并给一名NPC")
	_check(_actor_has_label_text(scene, "alexandria_merchant", "货栈 · 买卖特产") and _actor_has_label_text(scene, "alex_harbormaster", "航务 · 航线出港") and _actor_has_label_text(scene, "alex_shipwright", "船坞 · 买船改造") and _actor_has_label_text(scene, "alex_lighthouse_keeper", "商会 · 订单交付"), "港区地图上的每名NPC名牌必须直接显示职能")
	scene.player_actor.position = _actor_position(scene, "alexandria_merchant")
	scene._update_nearest_actor()
	scene._interact()
	_check(_has_label_text(scene.overlay, "亚历山大 · 本地货栈") and _has_button_text(scene.overlay, "打开商会订单柜台") and not _has_button_text(scene.overlay, "购买灯塔卡拉维尔"), "非对话任务时点击亚历山大商人必须只打开当地货栈")
	_check(_has_label_text(scene.overlay, "香料商萨米尔｜灯塔货栈") and _has_label_text(scene.overlay, "仅出售亚历山大香料") and _has_label_text(scene.overlay, "船上外来货 · 本港只收购") and _has_label_text(scene.overlay, "威尼斯玻璃 · 外来货"), "亚历山大商人必须出售自己的香料，并单独收购船上的威尼斯货物")
	scene._close_overlay()
	scene._open_port_shipyard_2d("alex_shipwright")
	_check(_has_label_text(scene.overlay, "亚历山大 · 船坞") and _has_label_text(scene.overlay, "灯塔卡拉维尔") and _has_button_text(scene.overlay, "购买灯塔卡拉维尔") and not _has_label_text(scene.overlay, "亚历山大香料"), "亚历山大船匠必须独立展示当地船型，不能混入香料货单")
	scene._close_overlay()
	scene.state.player.location = "ragusa_dock"
	scene._switch_region("city", "ragusa_dock")
	scene.player_actor.position = _actor_position(scene, "ragusa_innkeeper")
	scene._update_nearest_actor()
	_check("恢复补给" in scene.action_button.text, "旅店NPC的互动按钮必须直接显示恢复补给职能")
	scene._interact()
	_check(_has_label_text(scene.overlay, "石墙旅店 · 恢复补给") and _has_label_text(scene.overlay, "万能药") and _has_button_text(scene.overlay, "免费休息"), "旅店必须独立出售恢复药品并提供休息，不能混入货物和船务")
	scene._close_overlay()
	await process_frame

	# “亚历山大商会”必须在地图上有明确人物，任务导航要步行到柜台再打开订单，不能只显示抽象文字。
	scene.state.quest_index = 22
	scene.state.quest_progress = 0
	scene.state.completed_trade_orders.erase("alexandria_lighthouse_glass")
	scene.state.cargo.erase("venetian_glass")
	scene.state.cargo_costs.erase("venetian_glass")
	var procurement_target = scene._quest_navigation_target()
	_check(str(procurement_target.location) == "venice_dock" and str(procurement_target.actor_id) == "venice_quartermaster" and "采购威尼斯玻璃" in str(procurement_target.name), "商会订单缺货时任务导航必须先指向货物原产港与当地商人")
	scene._navigate_to_quest()
	_check(is_instance_valid(scene.sailing_map) and str(scene.sailing_destination) == "venice_dock", "缺少订单货物且身处外港时，任务导航必须打开返回原产港的航线")
	scene._close_overlay()
	await process_frame
	scene._switch_region("city", "venice_dock")
	scene.player_actor.position = scene._spawn_for_location("venice_dock")
	scene._navigate_to_quest()
	_check(scene.task_navigation_active and not is_instance_valid(scene.overlay), "抵达采购港后任务导航必须让角色走向当地商人，不能原地弹出市场")
	await _walk_task_navigation(scene)
	await process_frame
	await process_frame
	_check(_has_label_text(scene.overlay, "威尼斯 · 本地货栈") and _has_label_text(scene.overlay, "仅出售威尼斯玻璃"), "走到原产港商人后必须自动打开正确的本地货栈")
	scene._close_overlay()
	await process_frame
	scene.state.cargo["venetian_glass"] = 3
	scene.state.cargo_costs["venetian_glass"] = 72
	scene._switch_region("city", "alexandria_dock")
	scene.player_actor.position = scene._spawn_for_location("alexandria_dock")
	var guild_target = scene._quest_navigation_target()
	_check(str(guild_target.actor_id) == "alex_lighthouse_keeper" and _has_actor(scene, "alex_lighthouse_keeper"), "灯塔修缮任务必须指向地图上的亚历山大商会执事")
	scene._navigate_to_quest()
	_check(scene.task_navigation_active and not is_instance_valid(scene.overlay), "点击亚历山大商会任务导航后必须从当前位置步行，不能直接弹出通用市场")
	await _walk_task_navigation(scene)
	await process_frame
	await process_frame
	_check(_has_label_text(scene.overlay, "亚历山大 · 商会订单") and _has_button_text(scene.overlay, "向亚历山大商会交付"), "抵达商会执事后必须打开可完成灯塔订单的明确交付界面")
	scene._close_overlay()
	await process_frame

	# 跨港采购任务必须直接打开目标产地，不能被旧固定航线强制中转。
	scene.state.quest_index = _quest_index_by_id("earth_order")
	scene.state.quest_progress = 0
	scene.state.cargo.erase("olive_oil")
	scene.state.cargo_costs.erase("olive_oil")
	scene._switch_region("city", "athens_dock")
	var multi_hop_target = scene._quest_navigation_target()
	_check(str(multi_hop_target.location) == "ragusa_dock" and str(multi_hop_target.actor_id) == "ragusa_broker", "王陵灯油缺货时必须导航到唯一产地拉古萨")
	scene._refresh_waypoint()
	_check("航线导航" in scene.navigation_button.text and "采购亚得里亚橄榄油" in scene.navigation_button.text, "跨港采购时导航按钮必须明确显示航线与采购目标")
	scene._navigate_to_quest()
	_check(is_instance_valid(scene.sailing_map) and str(scene.sailing_destination) == "ragusa_dock" and "雅典" in scene.sailing_route_label.text and "拉古萨" in scene.sailing_route_label.text and "九港大地图" in scene.sailing_route_label.text, "雅典至拉古萨采购导航必须直接选择目的港，不能再强制到威尼斯中转")
	scene._close_overlay()
	await process_frame

	# 多产地烹饪任务应按缺口逐项导航，货齐后才指向厨房。
	scene.state.quest_index = _quest_index_by_id("island_feast")
	scene.state.cargo.erase("olive_oil")
	scene.state.cargo.erase("spices")
	scene.state.cargo.erase("citrus")
	var recipe_target = scene._quest_navigation_target()
	_check(str(recipe_target.location) == "ragusa_dock" and "采购亚得里亚橄榄油" in str(recipe_target.name), "海风炖汤任务必须先导航到拉古萨采购缺少的橄榄油")
	scene.state.cargo["olive_oil"] = 1
	recipe_target = scene._quest_navigation_target()
	_check(str(recipe_target.location) == "alexandria_dock" and "采购亚历山大香料" in str(recipe_target.name), "橄榄油备齐后必须继续导航到亚历山大采购香料")
	scene.state.cargo["spices"] = 1
	recipe_target = scene._quest_navigation_target()
	_check(str(recipe_target.location) == "malta_dock" and "采购金岛柑橘" in str(recipe_target.name), "外来配料备齐后必须导航到马耳他采购本地柑橘")
	scene.state.cargo["citrus"] = 2
	recipe_target = scene._quest_navigation_target()
	_check(str(recipe_target.location) == "malta_dock" and str(recipe_target.actor_id) == "malta_cook" and "厨房" in str(recipe_target.name), "全部配料备齐后导航必须切换到马耳他厨师")

	# 九城地图、NPC位置与碰撞要逐城切换，每名人物都必须使用精灵模型。
	scene.state.quest_index = GameData.QUESTS.size()
	var modeled_city_art_paths = {}
	for modeled_port_id in GameData.TRADE_PORTS:
		scene._switch_region("city", str(modeled_port_id))
		_check(str(scene.map_node.city_port_id) == str(modeled_port_id), "%s必须加载自己的城内地图主题" % GameData.TRADE_PORTS[str(modeled_port_id)].name)
		var modeled_city_art_path = str(scene.map_node.city_art_path(str(modeled_port_id)))
		_check(modeled_city_art_path.ends_with("/%s_city_v%s.png" % [str(modeled_port_id).trim_suffix("_dock"), "2" if str(modeled_port_id) == "venice_dock" else "1"]), "%s必须加载与港口一一对应的独立手绘背景" % GameData.TRADE_PORTS[str(modeled_port_id)].name)
		_check(not modeled_city_art_paths.has(modeled_city_art_path), "%s不能复用其他城市的房屋与背景图" % GameData.TRADE_PORTS[str(modeled_port_id)].name)
		modeled_city_art_paths[modeled_city_art_path] = true
		for modeled_npc_id in GameData.LOCATIONS[str(modeled_port_id)].npcs:
			var expected_position = scene._world_point(Vector2(GameData.PORT_CITY_MAPS[str(modeled_port_id)].npc_positions[str(modeled_npc_id)]))
			_check(_actor_has_art(scene, str(modeled_npc_id)), "%s的%s必须拥有可见人物精灵" % [GameData.TRADE_PORTS[str(modeled_port_id)].name, GameData.NPCS[str(modeled_npc_id)].name])
			var position_is_reachable = true if str(modeled_port_id) == "venice_dock" else scene._is_walkable(expected_position)
			_check(_actor_position(scene, str(modeled_npc_id)).distance_to(expected_position) < 1.0 and position_is_reachable, "%s的%s必须生成在地图配置的可行走街区" % [GameData.TRADE_PORTS[str(modeled_port_id)].name, GameData.NPCS[str(modeled_npc_id)].name])
	_check(modeled_city_art_paths.size() == GameData.TRADE_PORTS.size(), "九座港口必须拥有九张互不复用的城内背景")
	scene._switch_region("city", "athens_dock")
	scene._open_world_map()
	_check(_has_label_text(scene.overlay, "雅典 · 城内地图") and _has_label_text(scene.overlay, "海岬神殿与银帆柱廊") and _has_button_text(scene.overlay, "卡珊德拉｜货栈 · 买卖特产") and _has_button_text(scene.overlay, "艾琳娜｜旅店 · 恢复补给"), "每座城市的城内地图必须展示本地地标、人物和职能")
	var athens_map_start = scene.player_actor.position
	scene._travel_to_city_npc("athens_dock", "athens_oracle")
	_check(scene.task_navigation_active and scene.player_actor.position.distance_to(athens_map_start) < 1.0, "从城内地图选择NPC必须启动步行导航，不能直接传送")
	scene._cancel_task_navigation()
	scene._switch_region("city", "alexandria_dock")

	# 航海必须把原作的“出航”和“传送”分开；正常出航进入可驾驶海域，靠港后才改写位置。
	scene.state.player.silver = 1000
	scene.state.player.level = 1
	scene.state.ship.armor = 0
	scene.state.voyage_protection = 0
	scene._open_sailing_map()
	_check(is_instance_valid(scene.sailing_map) and scene.sailing_map.port_buttons.size() == GameData.TRADE_PORTS.size(), "航海图必须显示全部九座港口节点")
	_check(not scene.sailing_map.port_buttons["amsterdam_dock"].disabled, "主线完成后九座港口必须全部在海图上解锁")
	scene.sailing_map.select_port("venice_dock")
	var selected_voyage_distance = int(GameData.trade_route("alexandria_dock", "venice_dock").distance_nm)
	_check("亚历山大" in scene.sailing_route_label.text and "威尼斯" in scene.sailing_route_label.text and ("%d海里" % selected_voyage_distance) in scene.sailing_route_label.text and "8.0节" in scene.sailing_route_label.text and "九港大地图" in scene.sailing_route_label.text and "航经" in scene.sailing_route_label.text and "威胁情报" in scene.sailing_route_label.text and "当前等级偏低" in scene.sailing_route_label.text and "正常出航免费" in scene.sailing_route_label.text and "付费传送" in scene.sailing_route_label.text and not scene.sailing_confirm_button.disabled, "选择港口后必须显示动态距离、船体与帆装合成船速、九港大地图、途经海域与威胁")
	var origin_before_departure = str(scene.state.player.location)
	var silver_before_departure = int(scene.state.player.silver)
	scene._start_sailing_voyage()
	_check(scene.current_region == "sea" and not scene.state.active_voyage.is_empty(), "确认正常出航后必须进入可驾驶海域")
	_check(scene._active_world_size() == GameData.SEA_GLOBAL_WORLD_SIZE and Vector2(float(scene.state.active_voyage.world_width), float(scene.state.active_voyage.world_height)) == GameData.SEA_GLOBAL_WORLD_SIZE, "跨海航行必须加载同一张固定比例的九港大地图（地图%s / 状态%s / 距离%d）" % [scene._active_world_size(), Vector2(float(scene.state.active_voyage.world_width), float(scene.state.active_voyage.world_height)), selected_voyage_distance])
	var alexandria_departure_position = scene.player_actor.position
	scene.joystick_direction = Vector2.RIGHT
	scene._process(0.25)
	scene.joystick_direction = Vector2.ZERO
	_check(scene.player_actor.position.distance_to(alexandria_departure_position) > 1.0, "亚历山大等港口出航后必须能立即驾船移动，不能被港内礁区卡住")
	_check(str(scene.state.player.location) == origin_before_departure and int(scene.state.player.silver) == silver_before_departure, "海上航行未靠港前不能提前改写位置或扣传送费")
	_check(scene.player_actor.display_id == "player_ship" and _has_actor(scene, scene.state.sea_enemy_id()) and _has_actor(scene, "drifting_cargo"), "海域必须生成可驾驶船只、航路海盗和漂流货箱")
	var visible_sea_ports = 0
	var visible_sea_threats = 0
	for sea_map_actor in scene.actors:
		if str(sea_map_actor.kind) == "sea_port":
			visible_sea_ports += 1
		elif str(sea_map_actor.kind) == "enemy":
			visible_sea_threats += 1
	_check(visible_sea_ports == GameData.TRADE_PORTS.size() and visible_sea_threats == Array(scene.state.active_voyage.encounters).size(), "共用航海大地图必须同时生成全部已解锁港口和本航程全部威胁")
	var retreat_enemy = {}
	for sea_actor in scene.actors:
		if str(sea_actor.kind) == "enemy":
			retreat_enemy = sea_actor
			break
	_check(not retreat_enemy.is_empty(), "海域必须存在可用于撤退测试的威胁")
	if not retreat_enemy.is_empty():
		var harbor_enemy_position = scene._sea_origin_position() + Vector2(260, 0)
		scene.player_actor.position = scene._sea_origin_position()
		retreat_enemy.node.position = harbor_enemy_position
		scene._update_sea_enemy_pursuit(0.5)
		_check(retreat_enemy.node.position == harbor_enemy_position, "船停在港湾守卫圈内时，附近敌人不能闯港追击")
		var open_sea_position = Vector2(3300, 2500)
		scene.player_actor.position = open_sea_position
		retreat_enemy.node.position = open_sea_position + Vector2(280, 0)
		var pursuit_distance_before = scene.player_actor.position.distance_to(retreat_enemy.node.position)
		scene._update_sea_enemy_pursuit(0.5)
		var persisted_enemy = scene.state.sea_encounter(str(retreat_enemy.get("encounter_id", "")))
		_check(scene.player_actor.position.distance_to(retreat_enemy.node.position) < pursuit_distance_before and Vector2(float(persisted_enemy.x), float(persisted_enemy.y)) == retreat_enemy.node.position, "船进入警戒圈后敌人必须主动靠近，并同步保存移动后的位置")
		scene.player_actor.position = retreat_enemy.node.position + Vector2(0, 70)
		scene.active_enemy_actor = retreat_enemy
		scene.state.active_voyage.current_encounter_id = str(retreat_enemy.get("encounter_id", ""))
		scene._retreat_from_sea_encounter()
		_check(scene.map_node.is_navigable(scene.player_actor.position) and scene.player_actor.position.distance_to(retreat_enemy.node.position) >= 125.0 and scene.active_enemy_actor.is_empty() and str(scene.state.active_voyage.current_encounter_id) == "", "海战撤退必须把船放到可航行且不会立即重新触敌的安全水域")
	scene.state.active_voyage.pirate_defeated = true
	scene._spawn_world_actors()
	scene.player_actor.position = scene._sea_destination_position()
	scene._update_sea_voyage(0.1)
	_check(str(scene.state.player.location) == "venice_dock" and scene.current_region == "city" and _has_actor(scene, "ship_owner"), "船只驶入目的港后才可结算抵港并重建当地NPC")
	_check(_has_label_text(scene.overlay, "航行抵达") and _has_label_text(scene.overlay, "完成%d海里航程" % selected_voyage_distance), "抵港后必须显示动态计算的实际航程和航期结算")
	scene._close_overlay()

	var ship_state = TestState.new()
	ship_state.quest_index = GameData.QUESTS.size()
	ship_state.player.location = "alexandria_dock"
	ship_state.player.silver = 1000
	var starter_speed = float(ship_state.ship_speed_profile().knots)
	var ship_purchase = ship_state.buy_ship("alex_caravel")
	_check(bool(ship_purchase.get("ok", false)) and str(ship_state.ship.hull_id) == "alex_caravel" and str(ship_state.ship.name) == "灯塔卡拉维尔" and ship_state.cargo_capacity() == 20 and float(ship_state.ship_speed_profile().knots) > starter_speed and ship_state.ship_armor() == 1, "不同港口的船老板必须能出售独有船型，换船后速度、货舱和船甲立即生效")
	var capacity_before_hold = ship_state.cargo_capacity()
	ship_state.player.silver = 1000
	var hold_upgrade = ship_state.upgrade_ship("hold")
	_check(bool(hold_upgrade.get("ok", false)) and ship_state.cargo_capacity() == capacity_before_hold + 6, "货舱装备强化必须在船体基础容量上增加六格载货量")

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
		print("WORLD_MAP_OK: 移动导航、十三座远征、自动战斗、怪物刷新、九港贸易与厨房全部通过")
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

func _count_visuals(node, visual_kind):
	if not is_instance_valid(node):
		return 0
	var count = 1 if node.has_meta("visual_kind") and str(node.get_meta("visual_kind")) == str(visual_kind) else 0
	for child in node.get_children():
		count += _count_visuals(child, visual_kind)
	return count

func _has_named_node(node, target_name):
	if not is_instance_valid(node):
		return false
	if str(node.name) == str(target_name):
		return true
	for child in node.get_children():
		if _has_named_node(child, target_name):
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

func _actor_has_art(scene, actor_id):
	for entry in scene.actors:
		if str(entry.id) == str(actor_id):
			return is_instance_valid(entry.node.art_sprite) and entry.node.art_sprite.texture != null
	return false

func _actor_art_signature(actor):
	if not is_instance_valid(actor.art_sprite) or actor.art_sprite.texture == null:
		return ""
	var texture = actor.art_sprite.texture
	if texture is AtlasTexture:
		return "%s@%s" % [texture.atlas.resource_path, texture.region]
	return str(texture.resource_path)

func _actor_position(scene, actor_id):
	for entry in scene.actors:
		if str(entry.id) == str(actor_id):
			return entry.node.position
	return Vector2.ZERO

func _actor_has_label_text(scene, actor_id, fragment):
	for entry in scene.actors:
		if str(entry.id) == str(actor_id):
			return _has_label_text(entry.node, fragment)
	return false

func _quest_index_by_id(quest_id):
	for index in range(GameData.QUESTS.size()):
		if str(GameData.QUESTS[index].id) == str(quest_id):
			return index
	return -1
