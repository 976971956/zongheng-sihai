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
	var initial_city_layout = GameData.PORT_CITY_MAPS.venice_dock
	_check(not initial_city_layout.has("buildings") and initial_city_layout.has("plaza_rect"), "新版城市必须彻底取消前景房屋，改用开放广场")
	for initial_npc_id in Array(initial_city_layout.npc_ids):
		_check(initial_city_layout.plaza_rect.has_point(Vector2(initial_city_layout.npc_positions[str(initial_npc_id)])), "%s必须站在威尼斯开放广场内" % GameData.NPCS[str(initial_npc_id)].name)
	scene.player_actor.position = scene._spawn_for_location("venice_square")
	_check(scene.player_actor.display_id == "player", "主角必须使用独立的新版角色模型")
	_check(scene.player_actor.art_sprite.hframes == 4 and scene.player_actor.art_sprite.vframes == 3, "主角必须使用正面、侧面、背面三向多帧行走图集")
	scene.player_actor.set_motion(Vector2.RIGHT)
	scene.player_actor._process(0.16)
	var first_walk_frame = scene.player_actor.art_sprite.frame
	scene.player_actor._process(0.16)
	_check(scene.player_actor.art_sprite.frame != first_walk_frame, "主角移动时必须循环播放迈步帧而不是整图平移")
	scene.player_actor.set_motion(Vector2.UP)
	scene.player_actor._process(0.16)
	_check(scene.player_actor.art_sprite.frame_coords.y == 2, "主角向上走时必须切换为背面步态")
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
	_check(_has_button_text(scene, "设置"), "手机主界面必须提供设置入口")
	scene._open_settings()
	_check(_has_label_text(scene.overlay, "当前：普通难度") and _has_button_text(scene.overlay, "冒险") and _has_button_text(scene.overlay, "背景音乐与音效") and _has_button_text(scene.overlay, "重置游戏进度"), "设置页必须集中提供难度、声音和重置游戏功能")
	scene._set_difficulty_from_settings(GameState.DIFFICULTY_ADVENTURE)
	await process_frame
	_check(scene.state.difficulty == GameState.DIFFICULTY_ADVENTURE and _has_label_text(scene.overlay, "当前：冒险难度"), "手机设置页切换难度后必须立即保存并刷新选中状态")
	scene._open_reset_confirmation()
	_check(_has_label_text(scene.overlay, "此操作无法撤销") and _has_button_text(scene.overlay, "确认重置") and _has_button_text(scene.overlay, "取消，返回设置"), "重置游戏必须先显示不可撤销的二次确认")
	scene._close_overlay()
	scene.state.set_difficulty(GameState.DIFFICULTY_NORMAL)
	scene.state.quest_index = 9
	scene.state.quest_progress = 0
	scene.state.cargo = {"venetian_glass": 2}
	scene._open_quest()
	_check(_has_label_text(scene.overlay, "行动清单") and _has_label_text(scene.overlay, "拉古萨港") and str(scene._quest_navigation_target().location) == "ragusa_dock", "手机任务页和任务导航必须把玻璃商路准确指向拉古萨")
	scene._close_overlay()
	scene.state.quest_index = 20
	scene.state.player.location = "venice_dock"
	scene.state.cargo = {}
	var preparation_target = scene._quest_navigation_target()
	_check(str(preparation_target.location) == "venice_dock" and str(preparation_target.actor_id) == "venice_quartermaster" and "远航准备" in str(preparation_target.name), "灯塔远航缺少玻璃时导航必须先指向威尼斯货栈")
	scene.state.cargo = {"venetian_glass": 3}
	_check(str(scene._quest_navigation_target().location) == "alexandria_dock", "备齐三箱玻璃后灯塔远航导航必须切换到亚历山大")
	scene.state.quest_index = 0
	scene.state.cargo = {}
	var saved_respawn_key = scene._enemy_spawn_key("drunk_sailor")
	scene.state.enemy_respawns[saved_respawn_key] = scene._world_time_seconds() + 60.0
	scene._spawn_world_actors()
	_check(not _has_actor(scene, "drunk_sailor"), "重建地图时必须继续遵守存档中的怪物刷新倒计时")
	var saved_respawn_marker = scene.enemy_respawn_markers.get(saved_respawn_key)
	_check(scene.enemy_respawn_markers.has(saved_respawn_key) and _has_label_text(scene, "喝醉的水手刷新中") and _has_label_text(scene, ":"), "怪物刷新期间必须持续显示名称和分秒倒计时")
	var saved_spawn_position = scene._world_point(scene.ENEMY_SPAWNS["drunk_sailor"].position)
	var saved_spawn_screen_position = scene.world_layer.position + saved_spawn_position
	var expected_marker_position = Vector2(clamp(saved_spawn_screen_position.x + scene.RESPAWN_MARKER_OFFSET.x, 12.0, scene.MAP_SIZE.x - scene.RESPAWN_MARKER_SIZE.x - 12.0), clamp(saved_spawn_screen_position.y + scene.RESPAWN_MARKER_OFFSET.y, 198.0, 850.0))
	_check(is_instance_valid(saved_respawn_marker) and saved_respawn_marker.get_parent() == scene and saved_respawn_marker.position.distance_to(expected_marker_position) < 1.0 and saved_respawn_marker.z_index > 50, "刷新倒计时必须跟随敌人原刷新点并显示在上方，且不能被敌人名字或HUD挡住")
	scene.state.enemy_respawns.erase(saved_respawn_key)
	scene._spawn_world_actors()
	_check(_has_actor(scene, "drunk_sailor"), "没有刷新冷却时必须正常生成怪物")
	_check(not scene.enemy_respawn_markers.has(saved_respawn_key), "怪物刷新完成后必须移除倒计时标记")
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
	scene.player_actor.position = scene._spawn_for_location("venice_square")
	scene._navigate_to_quest()
	_check(scene.task_navigation_active and not is_instance_valid(scene.overlay), "点击交谈任务导航后必须先向NPC步行")
	await _walk_task_navigation(scene)
	await process_frame
	await process_frame
	_check(scene.state.quest_progress == 1, "任务导航抵达NPC后必须自动交谈并推进任务，不能要求二次点击")
	_check(is_instance_valid(scene.overlay) and _has_label_text(scene.overlay, "艾丽莎"), "任务导航抵达NPC后必须立即显示对应对话面板")
	scene._close_then_claim()
	await process_frame
	_check(scene.state.quest_can_claim(), "结束任务对话后必须弹出领奖流程")
	scene._claim_quest_2d()
	_check(scene.state.quest_index == 1, "领奖必须进入下一任务")
	scene._close_overlay()

	# The 2D backpack must expose and execute real item actions.
	scene.state.inventory["warrior_blade"] = 1
	scene._open_inventory()
	_check(_has_label_text(scene.overlay, "航海行囊") and _has_label_text(scene.overlay, "全部货架") and _has_named_node(scene.overlay, "InventoryDetail") and _has_named_node(scene.overlay, "InventorySummary"), "新版背包必须提供标题、资产概览、货架和选中详情区")
	_check(_has_button_text(scene.overlay, "推荐排序") and _has_button_text(scene.overlay, "装备") and _has_button_text(scene.overlay, "全部") and _has_button_text(scene.overlay, "补给"), "新版背包必须提供分类、排序与集中操作按钮")
	_check(_count_named_nodes(scene.overlay, "InventoryTile") >= 3, "新版背包必须以三列物品网格展示库存")
	_check(not _has_label_text(scene.overlay, "当前已装备") and _count_visuals(scene.overlay, "equipment") >= 1 and _count_visuals(scene.overlay, "consumable") >= 1 and _has_visual_set(scene.overlay, "warrior"), "航海行囊必须可视化展示装备与补给，并只保留未装备物品")
	scene._select_inventory_item_2d("small_milk")
	await process_frame
	_check(_named_node_meta(scene.overlay, "InventoryDetail", "item_id") == "small_milk" and _has_button_text(scene.overlay, "使用"), "点选补给后详情区必须切换为对应物品并提供使用操作")
	scene._set_inventory_filter_2d("equipment")
	await process_frame
	_check(scene.inventory_filter == "equipment" and _has_label_text(scene.overlay, "装备货架") and _count_visuals(scene.overlay, "consumable") == 0, "装备分类必须隐藏其他类别并保留独立货架")
	scene._open_character()
	_check(_has_label_text(scene.overlay, "角色信息 · 已装备") and _has_label_text(scene.overlay, "当前已装备") and _has_named_node(scene.overlay, "CharacterPortrait") and _has_named_node(scene.overlay, "CurrentShipModel") and _has_label_text(scene.overlay, "座舰系统") and _has_label_text(scene.overlay, "Lv.1  海燕号") and _has_label_text(scene.overlay, "九港船型图鉴") and _has_label_text(scene.overlay, "Lv.9 北海飞剪船") and _count_visuals(scene.overlay, "equipment") == 6 and not _has_label_text(scene.overlay, "航海行囊"), "角色页必须独立展示人物、装备与当前座舰，并列出九港分级船型")
	scene._open_inventory()
	scene._equip_item_2d("warrior_blade")
	await process_frame
	_check(str(scene.state.equipment.weapon) == "warrior_blade", "点击装备必须更新角色装备槽")
	var outdoor_equipment = scene.player_actor.equipment_visual_state()
	_check(str(outdoor_equipment.skin) == "warrior" and str(outdoor_equipment.weapon) == "warrior_blade" and bool(outdoor_equipment.has_weapon_layer), "地图角色必须同步穿上当前主套装，并显示真实手持武器")
	scene.player_actor.set_motion(Vector2.UP)
	scene.player_actor._process(0.2)
	outdoor_equipment = scene.player_actor.equipment_visual_state()
	_check(str(outdoor_equipment.facing) == "up" and Vector2i(outdoor_equipment.frame).y == 2 and str(outdoor_equipment.weapon_mount) == "back" and int(outdoor_equipment.weapon_z) == 2, "套装角色向上走时必须切换背面帧，并把武器露在背部上方")
	scene.player_actor.set_motion(Vector2.LEFT)
	scene.player_actor._process(0.2)
	outdoor_equipment = scene.player_actor.equipment_visual_state()
	_check(str(outdoor_equipment.facing) == "left" and Vector2i(outdoor_equipment.frame).y == 0 and str(outdoor_equipment.weapon_mount) == "back" and int(outdoor_equipment.weapon_z) == 0, "套装角色侧向行走时武器必须斜背在人物后层")
	scene.player_actor.set_motion(Vector2.ZERO)
	scene.player_actor._process(0.1)
	outdoor_equipment = scene.player_actor.equipment_visual_state()
	_check(str(outdoor_equipment.weapon_mount) == "back" and int(outdoor_equipment.weapon_z) == 0, "角色停下后武器也必须留在背部，不能重新跳回手中")
	scene.state.inventory["spider_knife"] = 1
	scene._equip_item_2d("spider_knife")
	await process_frame
	outdoor_equipment = scene.player_actor.equipment_visual_state()
	_check(str(outdoor_equipment.skin) == "base" and str(outdoor_equipment.weapon) == "spider_knife" and bool(outdoor_equipment.has_weapon_layer), "非套装武器也必须在基础旅行装角色手中真实显示")
	scene.state.inventory["warrior_blade"] = 1
	scene._equip_item_2d("warrior_blade")
	await process_frame
	scene._open_character()
	_check(_has_label_text(scene.overlay, "武士套装") and _has_label_text(scene.overlay, "套装共鸣") and _has_label_text(scene.overlay, "套装猎场") and _has_label_text(scene.overlay, "赤潮礁王·阿刻隆") and _has_button_text(scene.overlay, "强化至 +1") and _has_named_node(scene.overlay, "EquipmentUpgradeMeter") and _named_node_meta(scene.overlay, "CharacterPortrait", "equipment_skin") == "warrior", "角色装备页必须切换新版套装皮肤，并显示强化进度、共鸣、指定海域Boss、掉率和强化入口")
	await process_frame
	await process_frame
	scene.character_equipment_scroll.scroll_vertical = 240
	await process_frame
	var character_scroll_before_upgrade = int(scene.character_equipment_scroll.scroll_vertical)
	scene.state.player.silver += 1000
	scene._upgrade_equipped_2d("weapon")
	await process_frame
	await process_frame
	await process_frame
	_check(scene.state.equipment_upgrade_level("warrior_blade") == 1 and character_scroll_before_upgrade > 0 and int(scene.character_equipment_scroll.scroll_vertical) == character_scroll_before_upgrade, "强化装备后必须留在原装备卡位置，不能自动滚回角色页顶部")
	scene.state.equipment_upgrades.erase("warrior_blade")
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
	scene._set_inventory_filter_2d("card")
	await process_frame
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
	_check(scene.enemy_respawn_markers.has(respawn_key) and _has_label_text(scene, "喝醉的水手刷新中"), "怪物被击败消失后必须立即在原刷新点上方显示可见倒计时")
	var early_retry = scene.state.start_battle("drunk_sailor")
	_check(not bool(early_retry.get("ok", true)) and float(early_retry.get("respawn_remaining", 0.0)) > 0.0, "刷新冷却必须在核心战斗状态中阻止提前重复挑战")
	scene.state.enemy_respawns[respawn_key] = scene._world_time_seconds() - 0.1
	scene._try_respawn_enemy("drunk_sailor")
	_check(not _has_actor(scene, "drunk_sailor"), "战斗结算页未关闭时怪物不能在背后刷新")
	scene._close_overlay()
	# Simulate a mobile browser discarding the deferred one-shot timer while
	# backgrounded. The visible countdown update must recover the spawn itself,
	# even when the player waits beside the marker.
	scene.enemy_respawn_scheduled[respawn_key] = scene._world_time_seconds() - 0.1
	scene._refresh_enemy_respawn_markers()
	_check(_has_actor(scene, "drunk_sailor"), "倒计时结束后怪物必须立即重新出现，不能因手机计时器丢失或玩家在附近而停在00:00")

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
	_check(_has_button_text(scene.overlay, "买1") and _has_button_text(scene.overlay, "买5") and _has_button_text(scene.overlay, "买满") and _has_button_text(scene.overlay, "全卖") and _has_button_text(scene.overlay, "打开商会订单柜台") and _has_label_text(scene.overlay, "银币") and _has_label_text(scene.overlay, "今日行情") and not _has_button_text(scene.overlay, "出航拉古萨") and not _has_button_text(scene.overlay, "强化舱板"), "货栈NPC必须只展示批量货物买卖和订单入口，不能混入航线或船只改造")
	_check(_has_named_node(scene.overlay, "CargoCapacityBar") and _count_visuals(scene.overlay, "trade") >= 1 and _has_label_text(scene.overlay, "货舱装载") and _has_label_text(scene.overlay, "船体12 + 舱板0") and _has_label_text(scene.overlay, "商会价差榜") and _has_label_text(scene.overlay, "每格") and _has_label_text(scene.overlay, "今日余货") and _has_label_text(scene.overlay, "推荐销往"), "市场必须以船体容量、舱板加成、每日供货和单位舱位利润呈现跑商决策")
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
		_check(not city_layout.has("buildings"), "%s不得再配置前景房屋、房屋边框或建筑碰撞" % GameData.TRADE_PORTS[str(city_port_id)].name)
		var plaza_rect = Rect2(city_layout.get("plaza_rect", Rect2()))
		_check(plaza_rect.size.x >= 550.0 and plaza_rect.size.y >= 650.0, "%s必须为NPC提供足够大的开放广场" % GameData.TRADE_PORTS[str(city_port_id)].name)
		var configured_positions = Dictionary(city_layout.get("npc_positions", {}))
		var configured_npc_ids = Array(city_layout.get("npc_ids", []))
		_check(configured_npc_ids.size() == configured_positions.size(), "%s的每名NPC都必须拥有唯一广场站位" % GameData.TRADE_PORTS[str(city_port_id)].name)
		var harbor_npc_id = GameData.port_service_npc(str(city_port_id), "harbor")
		var harbor_position = Vector2(configured_positions.get(harbor_npc_id, Vector2.ZERO))
		_check(harbor_npc_id != "" and is_equal_approx(harbor_position.x, 360.0) and harbor_position.y >= 850.0, "%s负责出海的航务NPC必须统一站在广场正下方" % GameData.TRADE_PORTS[str(city_port_id)].name)
		for city_npc_id in configured_npc_ids:
			_check(configured_positions.has(str(city_npc_id)) and plaza_rect.has_point(Vector2(configured_positions[str(city_npc_id)])), "%s的%s必须站在开放广场内" % [GameData.TRADE_PORTS[str(city_port_id)].name, GameData.NPCS[str(city_npc_id)].name])
			if str(city_npc_id) != harbor_npc_id:
				_check(harbor_position.distance_to(Vector2(configured_positions[str(city_npc_id)])) >= 150.0, "%s的出海NPC不能与%s站位或名牌重叠" % [GameData.TRADE_PORTS[str(city_port_id)].name, GameData.NPCS[str(city_npc_id)].name])
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

	# 九城开放广场与NPC站位要逐城切换，每名人物都必须使用带职业道具的新精灵。
	scene.state.quest_index = GameData.QUESTS.size()
	var modeled_city_art_paths = {}
	for modeled_port_id in GameData.TRADE_PORTS:
		scene._switch_region("city", str(modeled_port_id))
		_check(str(scene.map_node.city_port_id) == str(modeled_port_id), "%s必须加载自己的城内地图主题" % GameData.TRADE_PORTS[str(modeled_port_id)].name)
		var modeled_city_art_path = str(scene.map_node.city_art_path(str(modeled_port_id)))
		_check(modeled_city_art_path.ends_with("/%s_plaza_v1.png" % str(modeled_port_id).trim_suffix("_dock")), "%s必须加载无前景房屋的独立广场背景" % GameData.TRADE_PORTS[str(modeled_port_id)].name)
		_check(not modeled_city_art_paths.has(modeled_city_art_path), "%s不能复用其他城市的广场背景图" % GameData.TRADE_PORTS[str(modeled_port_id)].name)
		modeled_city_art_paths[modeled_city_art_path] = true
		var modeled_layout = GameData.PORT_CITY_MAPS[str(modeled_port_id)]
		_check(not modeled_layout.has("buildings"), "%s场景中不得再生成任何房屋节点或房屋碰撞" % GameData.TRADE_PORTS[str(modeled_port_id)].name)
		for modeled_npc_id in Array(modeled_layout.npc_ids):
			var expected_position = scene._world_point(Vector2(GameData.PORT_CITY_MAPS[str(modeled_port_id)].npc_positions[str(modeled_npc_id)]))
			_check(_actor_has_art(scene, str(modeled_npc_id)) and "npc_profession_atlas" in _actor_art_atlas_path(scene, str(modeled_npc_id)), "%s的%s必须使用带身份道具的新版职业精灵" % [GameData.TRADE_PORTS[str(modeled_port_id)].name, GameData.NPCS[str(modeled_npc_id)].name])
			var position_is_reachable = scene._is_walkable(expected_position)
			_check(_actor_position(scene, str(modeled_npc_id)).distance_to(expected_position) < 1.0 and position_is_reachable, "%s的%s必须生成在开放广场的可行走区域" % [GameData.TRADE_PORTS[str(modeled_port_id)].name, GameData.NPCS[str(modeled_npc_id)].name])
			var city_npc_path = scene._build_task_navigation_path(scene._spawn_for_location(str(modeled_port_id)), expected_position)
			var path_stays_walkable = not city_npc_path.is_empty()
			for city_path_point in city_npc_path:
				path_stays_walkable = path_stays_walkable and scene._is_walkable(Vector2(city_path_point))
			_check(path_stays_walkable, "%s前往%s的导航必须能直达开放广场站位" % [GameData.TRADE_PORTS[str(modeled_port_id)].name, GameData.NPCS[str(modeled_npc_id)].name])
	_check(modeled_city_art_paths.size() == GameData.TRADE_PORTS.size(), "九座港口必须拥有九张互不复用的城内背景")
	scene._switch_region("city", "venice_dock")
	var plaza_walk_start = scene._world_point(Vector2(360, 760))
	scene.player_actor.position = plaza_walk_start
	scene.joystick_direction = Vector2.RIGHT
	scene._process(0.20)
	scene.joystick_direction = Vector2.ZERO
	_check(scene.player_actor.position.x > plaza_walk_start.x and scene._is_walkable(scene.player_actor.position), "开放广场不得残留房屋隐形墙，摇杆移动必须连续")
	scene._switch_region("city", "athens_dock")
	scene._open_world_map()
	_check(_has_label_text(scene.overlay, "雅典 · 城内地图") and _has_label_text(scene.overlay, "海岬神殿、橄榄石庭与银帆地纹") and _has_label_text(scene.overlay, "开放广场") and not _has_label_text(scene.overlay, "城内实体建筑") and _has_button_text(scene.overlay, "卡珊德拉｜货栈 · 买卖特产") and _has_button_text(scene.overlay, "艾琳娜｜旅店 · 恢复补给"), "每座城市的城内地图必须展示开放广场、地域地标、人物和职能")
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
	_check("亚历山大" in scene.sailing_route_label.text and "威尼斯" in scene.sailing_route_label.text and ("%d海里" % selected_voyage_distance) in scene.sailing_route_label.text and "8.0节" in scene.sailing_route_label.text and "九港大地图" in scene.sailing_route_label.text and "航经" in scene.sailing_route_label.text and "海域等级" in scene.sailing_route_label.text and "海域等级段优先" in scene.sailing_route_label.text and "威胁情报" in scene.sailing_route_label.text and "正常出航免费" in scene.sailing_route_label.text and "付费传送" in scene.sailing_route_label.text and not scene.sailing_confirm_button.disabled, "选择港口后必须显示动态距离、船速、途经海域等级段与实际威胁")
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
	_check(scene.player_actor.display_id == "player_ship" and is_instance_valid(scene.player_actor.art_sprite) and "directions_8x8_v2" in _actor_art_signature(scene.player_actor) and _has_actor(scene, scene.state.sea_enemy_id()) and _has_actor(scene, "drifting_cargo"), "海域必须生成当前船体的八方向八帧可驾驶模型、航路海盗和漂流货箱")
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
		scene.active_enemy_actor = retreat_enemy
		var encounter_battle = scene.state.start_sea_encounter(str(retreat_enemy.get("encounter_id", "")))
		scene._open_battle(encounter_battle)
		_check(scene.battle_stage.player_model.display_id == "player" and scene.player_actor.display_id == "player_ship", "大航海遇敌后战斗舞台必须显示船长人物，航海地图仍保持当前船型，不能把人物直接变成船")
		scene.state.active_battle = {}
		scene.state.active_voyage.current_encounter_id = ""
		scene._close_overlay()
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
	_check(str(scene.state.player.location) == "venice_dock" and scene.current_region == "city" and scene.player_actor.display_id == "player" and _has_actor(scene, "ship_owner"), "船只驶入目的港后才可结算抵港，并把地图模型恢复成人物后重建当地NPC")
	_check(_has_label_text(scene.overlay, "航行抵达") and _has_label_text(scene.overlay, "完成%d海里航程" % selected_voyage_distance), "抵港后必须显示动态计算的实际航程和航期结算")
	scene._close_overlay()

	var ship_state = TestState.new()
	ship_state.quest_index = GameData.QUESTS.size()
	ship_state.player.location = "alexandria_dock"
	ship_state.player.silver = 1000
	var starter_speed = float(ship_state.ship_speed_profile().knots)
	var ship_purchase = ship_state.buy_ship("alex_caravel")
	_check(bool(ship_purchase.get("ok", false)) and str(ship_state.ship.hull_id) == "alex_caravel" and str(ship_state.ship.name) == "灯塔卡拉维尔" and ship_state.owns_ship("alex_caravel") and ship_state.cargo_capacity() == 20 and float(ship_state.ship_speed_profile().knots) > starter_speed and ship_state.ship_armor() == 1, "不同港口的船老板必须能出售独有船型并永久收藏，换船后速度、货舱和船甲立即生效")
	var hull_model = ActorScript.new()
	root.add_child(hull_model)
	hull_model.configure("player", Color.WHITE, Color.WHITE, "player_ship")
	hull_model.set_ship_hull("sea_swallow")
	var starter_hull_art = _actor_art_signature(hull_model)
	hull_model.set_ship_hull("alex_caravel")
	var purchased_hull_art = _actor_art_signature(hull_model)
	_check("sea_swallow_directions_8x8_v2" in starter_hull_art and "alex_caravel_directions_8x8_v2" in purchased_hull_art and starter_hull_art != purchased_hull_art, "航海大地图船只必须根据玩家购买的船体切换独立8×8模型")
	hull_model.set_motion(Vector2.RIGHT)
	hull_model._process(0.18)
	_check(hull_model.ship_target_heading < -1.5 and hull_model.rotation < -0.05 and hull_model.rotation > hull_model.ship_target_heading and hull_model.ship_motion_blend > 0.1, "船首必须朝实际航向平滑转舵，不能继续反向或瞬间旋转")
	_check(hull_model.ship_facing in ["down_right", "right"] and hull_model.art_sprite.texture.region.position.y in [128.0, 256.0] and hull_model.art_sprite.texture.region.size == Vector2(128, 128), "转向右舷时必须切换为8×8图集中的斜向或右向立体帧")
	var directional_signatures = []
	for direction_rotation in [0.0, -PI * 0.25, -PI * 0.5, -PI * 0.75, PI, PI * 0.75, PI * 0.5, PI * 0.25]:
		hull_model.rotation = direction_rotation
		hull_model._update_player_ship_direction(true)
		directional_signatures.append(_actor_art_signature(hull_model))
	var unique_directional_signatures = {}
	for direction_signature in directional_signatures:
		unique_directional_signatures[direction_signature] = true
	_check(unique_directional_signatures.size() == 8, "同一艘船必须使用八个独立航向，不能退回四方向或旋转同一张图")
	hull_model.rotation = 0.0
	hull_model.ship_motion_blend = 1.0
	hull_model.ship_animation_time = 0.0
	hull_model._update_player_ship_direction(true)
	var first_sailing_frame = _actor_art_signature(hull_model)
	hull_model._process(0.32)
	_check(hull_model.ship_animation_frame > 0 and _actor_art_signature(hull_model) != first_sailing_frame, "每个航向必须播放八帧航行动画，不能只重复静态方向图")
	_check(abs(hull_model.art_sprite.skew) > 0.001 and hull_model.art_sprite.position.length() > 0.1, "航行船体必须产生波浪俯仰、转弯侧倾与位移反馈，不能只做平面贴图滑动")
	_check(is_instance_valid(hull_model.ship_depth_sprite) and is_instance_valid(hull_model.ship_bow_foam) and hull_model.ship_depth_sprite.position.y > hull_model.art_sprite.position.y and hull_model.ship_bow_foam.default_color.a > 0.0 and hull_model.ship_bow_foam.points[0].distance_to(hull_model.ship_bow_foam.points[-1]) <= 33.0, "船体必须使用贴合外形的厚度暗层和只包裹船首的前景破浪水线，不能只靠平面椭圆阴影或让水线横跨甲板")
	var moving_wake_strength = hull_model.ship_motion_blend
	hull_model.set_motion(Vector2.ZERO)
	hull_model._process(0.50)
	_check(hull_model.ship_motion_blend < moving_wake_strength, "停船后尾浪必须逐渐消退，不能保持全速航行效果")
	hull_model._process(0.50)
	var stopped_transform = Transform2D(hull_model.art_sprite.transform)
	hull_model._process(0.35)
	_check(hull_model.ship_motion_blend == 0.0 and hull_model.ship_turn_lean == 0.0 and hull_model.art_sprite.transform == stopped_transform and hull_model.art_sprite.position == Vector2.ZERO and is_zero_approx(hull_model.art_sprite.skew) and is_zero_approx(hull_model.ship_bow_foam.default_color.a), "船只完全停稳后必须保持静止，不能继续俯仰、缩放或水花抖动")
	hull_model.free()
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
		push_error("CHECK_FAILED: %s" % message)

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

func _has_visual_set(node, set_id):
	if not is_instance_valid(node):
		return false
	if node.has_meta("equipment_set_skin") and str(node.get_meta("equipment_set_skin")) == str(set_id):
		return true
	for child in node.get_children():
		if _has_visual_set(child, set_id):
			return true
	return false

func _named_node_meta(node, target_name, meta_name):
	if not is_instance_valid(node):
		return ""
	if str(node.name) == str(target_name):
		return str(node.get_meta(meta_name, ""))
	for child in node.get_children():
		var result = _named_node_meta(child, target_name, meta_name)
		if result != "":
			return result
	return ""

func _count_named_nodes(node, target_name):
	if not is_instance_valid(node):
		return 0
	var count = 1 if str(node.name).begins_with(str(target_name)) else 0
	for child in node.get_children():
		count += _count_named_nodes(child, target_name)
	return count

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

func _actor_art_atlas_path(scene, actor_id):
	for entry in scene.actors:
		if str(entry.id) != str(actor_id) or not is_instance_valid(entry.node.art_sprite):
			continue
		var texture = entry.node.art_sprite.texture
		if texture is AtlasTexture and texture.atlas != null:
			return str(texture.atlas.resource_path)
		return str(texture.resource_path) if texture != null else ""
	return ""

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
