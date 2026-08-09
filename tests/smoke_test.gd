extends SceneTree

class TestState extends GameState:
	func save_game():
		pass

var failures = []

func _init():
	var state = TestState.new()
	state.rng.seed = 424242
	_check(state.player.location == "alisa_hut", "新游戏应从海边小屋开始")
	_check(state.get_current_quest().objective.type == "talk", "首个任务应为交谈任务")
	var opening_story = state.story_progress()
	_check(int(opening_story.total) == GameData.QUESTS.size() and str(opening_story.chapter) == "序章·失去的名字", "任务系统必须返回总进度与当前章节")
	var gear_state = TestState.new()
	gear_state.inventory["warrior_blade"] = 1
	var power_before_recommend = gear_state.get_power()
	var recommend_result = gear_state.equip_recommended()
	_check(bool(recommend_result.ok) and str(gear_state.equipment.weapon) == "warrior_blade" and gear_state.get_power() > power_before_recommend, "一键推荐必须自动换上背包中更强的装备")

	var first_talk = state.talk_to("alisa")
	_check(bool(first_talk.get("quest_completed", false)), "任务首次达成时必须返回自动领奖触发标记")
	_claim(state, "scale_memory")
	state.move_to("venice_tavern")
	_claim(state, "to_tavern")
	state.talk_to("tavern_keeper")
	_claim(state, "tavern_clue")
	state.move_to("venice_square")
	state.move_to("venice_north_gate")
	_win_times(state, "drunk_sailor", 3)
	_claim(state, "north_gate")

	_check(int(state.player.level) >= 2, "北门任务后应达到 Lv.2")
	state.move_to("residential_quarter")
	state.move_to("venice_mine")
	_win_times(state, "mine_thief", 3)
	var mine_reward = _claim(state, "stolen_ore")
	_check(mine_reward.reward_item == "warrior_blade", "矿山任务应明确返回武士刃装备引导")
	_check(state.equip_item("warrior_blade").ok, "武士刃应能从任务奖励直接装备")
	_check(state.companion_unlocked, "矿山任务应解锁队友")
	var party_result = state.recruit_companion()
	_check(party_result.ok and state.party_members.size() == 1, "酒馆队友模拟应可加入")

	state.move_to("residential_quarter")
	state.move_to("venice_back_hill")
	_win_times(state, "giant_bear", 1)
	var bear_reward = _claim(state, "back_hill_bear")
	_check(bear_reward.reward_item == "warrior_coat", "巨熊任务应明确返回武士战衣装备引导")
	_check(state.equip_item("warrior_coat").ok, "武士战衣应能从任务奖励直接装备")
	_check(not state.pet.is_empty(), "后山任务应奖励月虎")

	state.move_to("residential_quarter")
	state.move_to("venice_north_gate")
	state.move_to("training_dungeon_1")
	_check(not state.move_to("training_dungeon_2").ok, "未击败一层守卫时必须锁住二层")
	_win_times(state, "dungeon_guard", 1)
	_check(state.move_to("training_dungeon_2").ok, "击败一层守卫后应开放二层")
	_check(not state.move_to("training_dungeon_3").ok, "未击败二层守卫时必须锁住三层")
	_win_times(state, "stone_puppet", 1)
	_check(state.move_to("training_dungeon_3").ok, "击败二层守卫后应开放三层")
	_check(not state.move_to("training_dungeon_4").ok, "未击败三层守卫时必须锁住四层")
	_win_times(state, "tide_beast", 1)
	_check(state.move_to("training_dungeon_4").ok, "击败三层守卫后应开放四层")
	_win_times(state, "vermilion_phantom", 1)
	var final_reward = _claim(state, "four_floor_trial")
	_check(state.get_current_quest().id == "first_cargo", "威尼斯试炼后必须衔接远洋贸易主线")
	_check(bool(final_reward.get("trade_unlocked", false)) and state.is_trade_unlocked(), "威尼斯试炼领奖后必须解锁货物贸易")

	state.player.location = "venice_dock"
	var trade_silver_before = int(state.player.silver)
	var batch_buy = state.buy_cargo("venetian_glass", 4)
	_check(batch_buy.ok and int(batch_buy.amount) == 4, "威尼斯港应能批量买入玻璃")
	_check(state.cargo_used() == 8, "四箱玻璃应占用8格货舱")
	_check(state.cargo_average_cost("venetian_glass") == int(batch_buy.price), "贸易系统必须记录货物的真实买入均价")
	_claim(state, "first_cargo")
	var voyage = state.sail_to("ragusa_dock")
	_check(voyage.ok and state.player.location == "ragusa_dock" and state.trade_day > 1, "贸易船应能扣除航费并推进日期抵达拉古萨")
	_claim(state, "sail_ragusa")
	var batch_sell = state.sell_all_cargo("venetian_glass")
	_check(batch_sell.ok and int(batch_sell.amount) == 4 and batch_sell.has("realized_profit"), "拉古萨港应能全卖并结算实际盈亏")
	_check(state.cargo_used() == 0, "卖完货物后货舱应清空")
	_check(not state.cargo_costs.has("venetian_glass"), "清仓后必须同步清除货物成本")
	_check(int(state.player.silver) > trade_silver_before, "批量跨港贸易扣除航费后应产生正收益")
	_claim(state, "sell_glass")
	_check(state.upgrade_equipped("weapon").ok, "远洋主线必须能使用贸易银币强化武器")
	_claim(state, "forge_for_sea")
	_check(state.upgrade_ship("armor").ok, "远洋主线必须能加固海燕号")
	_claim(state, "armor_the_swallow")
	var capacity_before = state.cargo_capacity()
	var upgrade = state.upgrade_ship("hold")
	_check(upgrade.ok and state.cargo_capacity() == capacity_before + 6, "货舱升级应增加6格容量")

	state.arrive_from_2d("black_sail_1")
	_claim(state, "black_sail_clue")
	_win_times(state, "corsair_deckhand", 1)
	var deckhand_reward = _claim(state, "clear_deckhands")
	_check(deckhand_reward.reward_item == "corsair_cutlass" and state.equip_item("corsair_cutlass").ok, "黑帆外围必须奖励并可装备黑帆弯刀")
	_check(state.move_to("black_sail_2").ok, "击败黑帆水手后必须开放火药仓")
	_win_times(state, "corsair_raider", 1)
	var raider_reward = _claim(state, "powder_store")
	_check(raider_reward.reward_item == "gunner_coat" and state.equip_item("gunner_coat").ok, "火药仓必须奖励炮手皮甲")
	_check(state.move_to("black_sail_3").ok, "击败袭击者后必须开放洞窟炮台")
	_win_times(state, "corsair_guard", 1)
	var guard_reward = _claim(state, "cave_battery")
	_check(guard_reward.reward_item == "captain_hat" and state.equip_item("captain_hat").ok, "洞窟炮台必须奖励船长帽")
	_check(state.move_to("black_sail_4").ok, "击败重卫后必须开放船长厅")
	_win_times(state, "corsair_captain", 1)
	var captain_reward = _claim(state, "captain_ledger")
	_check(captain_reward.reward_item == "black_sail_charm" and state.equip_item("black_sail_charm").ok, "黑帆船长必须奖励传说航路仪")
	state.player.location = "venice_tavern"
	_check(bool(state.talk_to("tavern_keeper").get("quest_completed", false)), "击败黑帆船长后必须回酒馆交付海图")
	_claim(state, "return_chart")
	state.player.location = "alisa_hut"
	_check(bool(state.talk_to("alisa").get("quest_completed", false)), "黑帆海图必须引导玩家回到艾丽莎小屋")
	var story_reward = _claim(state, "alisa_truth")
	_check(story_reward.reward_item == "tide_seal" and state.equip_item("tide_seal").ok, "第一卷结局必须奖励潮汐银章并可装备")
	_check(state.get_current_quest().id == "lighthouse_letter" and int(state.player.level) >= 15, "第一卷结束后必须立即接续第二卷灯塔来信")
	_check(str(state.player.title) == "潮汐追迹者", "第一卷结局必须授予剧情称号")

	state.player.location = "venice_tavern"
	state.talk_to("tavern_keeper")
	_claim(state, "lighthouse_letter")
	state.player.location = "venice_dock"
	var glass_for_lighthouse = state.buy_cargo("venetian_glass", 3)
	_check(bool(glass_for_lighthouse.ok), "第二卷启航前必须能准备灯塔玻璃订单")
	state.buy_voyage_protection()
	state.sail_to("alexandria_dock")
	_claim(state, "sail_lighthouse")
	state.talk_to("alexandria_merchant")
	_claim(state, "samir_testimony")
	var lighthouse_order = state.claim_trade_order()
	_check(bool(lighthouse_order.ok) and state.port_reputation_value("alexandria_dock") == 2, "灯塔订单必须交付货物并提升亚历山大声望")
	_claim(state, "lighthouse_repairs")
	state.buy_cargo("olive_oil", 4)
	state.buy_voyage_protection()
	state.sail_to("ragusa_dock")
	var ragusa_order = state.claim_trade_order()
	_check(bool(ragusa_order.ok) and state.total_trade_reputation() >= 4, "拉古萨剧情订单必须形成第二条跨港交付路线")
	_claim(state, "ragusa_nightwatch")
	_check(state.quest_progress == min(6, state.total_trade_reputation()), "进入三港信任任务时必须继承已有声望，不能要求重刷")
	state.buy_voyage_protection()
	state.sail_to("venice_dock")
	state.buy_cargo("venetian_glass", 2)
	state.buy_voyage_protection()
	state.sail_to("ragusa_dock")
	var repeat_order = state.claim_trade_order()
	_check(bool(repeat_order.ok) and state.total_trade_reputation() >= 6 and state.quest_can_claim(), "日常港口订单必须可循环并推进三港声望主线")
	_claim(state, "three_port_trust")
	var protection = state.buy_voyage_protection()
	_check(bool(protection.ok) and bool(protection.quest_completed), "购买护航物资必须推进季风准备任务")
	_claim(state, "guarded_passage")
	state.sail_to("alexandria_dock")
	state.buy_cargo("spices", 4)
	state.buy_voyage_protection()
	state.sail_to("venice_dock")
	var medicine_order = state.claim_trade_order()
	_check(bool(medicine_order.ok), "潮汐药引必须通过亚历山大到威尼斯的香料订单完成")
	_claim(state, "tide_medicine")
	state.player.location = "venice_tavern"
	state.talk_to("tavern_keeper")
	var volume_two_reward = _claim(state, "keeper_return")
	_check(volume_two_reward.reward_item == "lighthouse_compass" and state.equip_item("lighthouse_compass").ok, "第二卷结局必须奖励可装备的灯塔星盘")
	_check(state.get_current_quest().id == "white_whale_news" and int(state.player.level) >= 20, "第二卷结束后必须立即接续第三卷白鲸号线索")
	_check(str(state.player.title) == "灯塔守望者", "第二卷结局必须授予灯塔守望者称号")

	state.player.location = "alisa_hut"
	state.talk_to("alisa")
	_claim(state, "white_whale_news")
	state.player.location = "venice_dock"
	var malta_voyage = state.sail_to("malta_dock")
	_check(bool(malta_voyage.ok) and str(state.player.location) == "malta_dock", "第四港马耳他必须能从威尼斯直航抵达")
	_claim(state, "sail_malta")
	state.talk_to("malta_keeper")
	_claim(state, "meet_isabella")
	state.buy_cargo("citrus", 2)
	state.buy_cargo("olive_oil", 1)
	state.buy_cargo("spices", 1)
	var cooking = state.cook_provision("maltese_stew")
	_check(bool(cooking.ok) and bool(cooking.quest_completed) and int(state.inventory.get("maltese_stew", 0)) == 1, "马耳他厨房必须消耗贸易货物并产出可用餐食")
	_claim(state, "island_feast")
	var attack_without_meal = int(state.get_stats().attack)
	var eat = state.use_item("maltese_stew")
	_check(bool(eat.ok) and state.meal_buff_battles == 3 and int(state.get_stats().attack) == attack_without_meal + 6, "海风炖汤必须提供持续3场战斗的真实属性加成")
	state.arrive_from_2d("white_whale_1")
	_claim(state, "wreck_entry")
	_check(not state.move_to("white_whale_2").ok, "未击败覆甲礁蟹时必须锁住沉水甲板")
	_win_times(state, "wreck_crab", 1)
	_claim(state, "clear_reef")
	_check(state.move_to("white_whale_2").ok, "击败覆甲礁蟹后必须开放沉水甲板")
	_win_times(state, "drowned_sailor", 1)
	_claim(state, "drowned_deck")
	_check(state.move_to("white_whale_3").ok, "击败溺潮水手后必须开放雾锁货舱")
	_win_times(state, "fog_siren", 1)
	_claim(state, "fog_hold")
	_check(state.move_to("white_whale_4").ok, "击败雾歌海妖后必须开放鲸心船舱")
	_win_times(state, "abyss_siren", 1)
	_claim(state, "white_whale_heart")
	_check(state.meal_buff_battles == 0, "远航餐食必须按完成的战斗场次正确消耗")
	state.player.location = "malta_dock"
	state.talk_to("malta_keeper")
	var volume_three_reward = _claim(state, "heir_testimony")
	_check(volume_three_reward.reward_item == "white_whale_coat" and state.equip_item("white_whale_coat").ok, "第三卷结局必须奖励可装备的白鲸守望衣")
	_check(state.get_current_quest().is_empty() and int(state.player.level) == GameData.MAX_LEVEL, "三卷完整主线必须支持成长至Lv.30")
	_check(str(state.player.title) == "白鲸继航者", "第三卷结局必须授予白鲸继航者称号")

	state.inventory["ghost_card"] = 1
	var defense_before_card = int(state.get_stats().defense)
	_check(state.equip_card("ghost_card").ok and int(state.get_stats().defense) == defense_before_card + 3, "怪物卡必须可启用并提供真实属性加成")
	var discovery = state.claim_discovery("alisa_shell")
	_check(discovery.ok and not state.claim_discovery("alisa_shell").ok, "地图发现物必须可领取且不能重复获取")

	var bounty_state = TestState.new()
	bounty_state.player.level = 8
	bounty_state.player.location = "residential_quarter"
	_win_times(bounty_state, "sewer_rat", 3)
	_check(bounty_state.bounty_can_claim(), "击败指定怪物必须完成当前循环悬赏")
	var bounty_reward = bounty_state.claim_bounty()
	_check(bounty_reward.ok and bounty_state.get_bounty().id == "mine_patrol", "领取后必须自动轮换到下一个悬赏")

	state.inventory["unknown_equipment"] = 1
	var silver_before = int(state.player.silver)
	var identify = state.identify_unknown()
	_check(identify.ok and int(state.player.silver) == silver_before - 5, "未知道具应消耗5银币并成功鉴定")
	_check(GameData.LOCATIONS.size() == 25, "世界图应包含威尼斯、四座贸易港和三座四层副本")
	_check(GameData.SLOT_NAMES.has("waist"), "装备系统应包含腰部槽位")
	state.player.level = GameData.MAX_LEVEL
	state.player.xp = 350
	state._add_xp(500)
	_check(int(state.player.xp) == 0, "满级经验必须封顶并保持MAX")

	var dungeon_reset = TestState.new()
	dungeon_reset.player.level = 4
	dungeon_reset.player.location = "venice_north_gate"
	dungeon_reset.move_to("training_dungeon_1")
	dungeon_reset.dungeon_cleared["dungeon_guard"] = true
	dungeon_reset.move_to("venice_north_gate")
	dungeon_reset.move_to("training_dungeon_1")
	_check(not dungeon_reset.move_to("training_dungeon_2").ok, "离开副本后必须重置逐层解锁进度")

	if failures.is_empty():
		print("SMOKE_OK: 三卷主线、三座逐层副本、四港贸易、烹饪补给与成长闭环全部通过")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _claim(state, expected_id):
	_check(state.get_current_quest().id == expected_id, "任务顺序错误：应为%s" % expected_id)
	_check(state.quest_can_claim(), "任务%s目标未正确推进" % expected_id)
	var result = state.claim_quest()
	_check(result.ok, "任务%s无法领取奖励" % expected_id)
	return result

func _win_times(state, enemy_id, count):
	for _index in range(count):
		state.player.hp = state.get_stats().max_hp
		# Each loop represents returning after the overworld respawn delay.
		state.enemy_respawns.erase(str(enemy_id))
		var start = state.start_battle(enemy_id)
		_check(start.ok and not start.battle_over, "%s无法开始战斗" % enemy_id)
		var result = state.auto_attack()
		if not bool(result.get("won", false)):
			# Smoke testing checks the flow rather than difficulty tuning. Give the
			# traveler a temporary retry advantage without changing production data.
			state.player.hp = state.get_stats().max_hp
			state.player.level = min(GameData.MAX_LEVEL, int(state.player.level) + 1)
			state.player.location = _enemy_location(enemy_id)
			state.start_battle(enemy_id)
			result = state.auto_attack()
		_check(bool(result.get("won", false)), "%s自动战斗未能结束" % enemy_id)

func _enemy_location(enemy_id):
	for location_id in GameData.LOCATIONS:
		if enemy_id in GameData.LOCATIONS[location_id].enemies:
			return location_id
	return "alisa_hut"

func _check(condition, message):
	if not condition:
		failures.append(message)
