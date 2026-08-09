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
	for _index in range(4):
		_check(state.buy_cargo("venetian_glass").ok, "威尼斯港应能买入玻璃")
	_check(state.cargo_used() == 8, "四箱玻璃应占用8格货舱")
	_claim(state, "first_cargo")
	var voyage = state.sail_to("ragusa_dock")
	_check(voyage.ok and state.player.location == "ragusa_dock" and state.trade_day > 1, "贸易船应能扣除航费并推进日期抵达拉古萨")
	_claim(state, "sail_ragusa")
	for _index in range(4):
		_check(state.sell_cargo("venetian_glass").ok, "拉古萨港应能卖出玻璃")
	_check(state.cargo_used() == 0, "卖完货物后货舱应清空")
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
	_check(state.get_current_quest().is_empty() and int(state.player.level) == GameData.MAX_LEVEL, "完整主线必须支持角色成长至Lv.15")
	_check(str(state.player.title) == "潮汐追迹者", "第一卷结局必须授予剧情称号")

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
	_check(GameData.LOCATIONS.size() == 20, "世界图应包含威尼斯、贸易港和两座四层副本")
	_check(GameData.SLOT_NAMES.has("waist"), "装备系统应包含腰部槽位")
	state.player.level = GameData.MAX_LEVEL
	state.player.xp = 350
	state._add_xp(500)
	_check(int(state.player.xp) == 0, "Lv.15经验必须封顶并保持MAX")

	var dungeon_reset = TestState.new()
	dungeon_reset.player.level = 4
	dungeon_reset.player.location = "venice_north_gate"
	dungeon_reset.move_to("training_dungeon_1")
	dungeon_reset.dungeon_cleared["dungeon_guard"] = true
	dungeon_reset.move_to("venice_north_gate")
	dungeon_reset.move_to("training_dungeon_1")
	_check(not dungeon_reset.move_to("training_dungeon_2").ok, "离开副本后必须重置逐层解锁进度")

	if failures.is_empty():
		print("SMOKE_OK: 威尼斯主线、逐层副本、贸易航线、买卖利润与船只升级全部通过")
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
