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
	_check(state.difficulty == GameState.DIFFICULTY_NORMAL and state.difficulty_name() == "普通", "新游戏必须默认使用普通难度")
	var difficulty_state = TestState.new()
	difficulty_state.player.location = "venice_dock"
	var normal_route_risk = difficulty_state.voyage_risk("ragusa_dock")
	_check(bool(difficulty_state.set_difficulty(GameState.DIFFICULTY_ADVENTURE).ok), "设置页必须能切换到冒险难度")
	_check(difficulty_state.difficulty_enemy_hp(42) == 53 and difficulty_state.difficulty_enemy_attack(8) == 9 and difficulty_state.difficulty_battle_reward(100) == 120, "冒险难度必须应用耐久、攻击与奖励倍率")
	_check(difficulty_state.voyage_risk("ragusa_dock") == normal_route_risk + 6, "冒险难度必须让航行风险提高6点")
	difficulty_state.player.location = "venice_north_gate"
	var adventure_battle = difficulty_state.start_battle("drunk_sailor")
	_check(bool(adventure_battle.ok) and int(adventure_battle.enemy_max_hp) == 53 and str(adventure_battle.difficulty_name) == "冒险", "冒险难度必须真实改变战斗敌人耐久并显示难度")
	_check(not bool(difficulty_state.set_difficulty(GameState.DIFFICULTY_NORMAL).ok), "战斗进行中不能切换难度")
	difficulty_state.quest_index = 9
	difficulty_state.inventory["warrior_blade"] = 1
	difficulty_state.reset_progress()
	_check(difficulty_state.difficulty == GameState.DIFFICULTY_ADVENTURE and difficulty_state.quest_index == 0 and not difficulty_state.inventory.has("warrior_blade") and difficulty_state.player.location == "alisa_hut", "重置游戏必须清空成长进度并保留所选难度")
	var port_lock_state = TestState.new()
	port_lock_state.quest_index = 8
	port_lock_state.player.location = "venice_dock"
	_check(port_lock_state.is_port_unlocked("ragusa_dock") and not port_lock_state.is_port_unlocked("alexandria_dock"), "九港海图必须随主线逐港解锁，不能在第一卷一次性开放远洋港口")
	port_lock_state.player.silver = 999
	_check(not port_lock_state.sail_to("alexandria_dock").ok, "尚未发现的港口不能绕过海图锁定直接启航")
	_check(GameData.NPCS.size() >= 31, "九港剧情与服务人物必须完整配置，不能只保留少量任务NPC")
	var specialty_goods = {}
	var regional_ship_offers = {}
	var ship_levels = {}
	for port_id in GameData.TRADE_PORTS:
		var port = GameData.TRADE_PORTS[port_id]
		var order_npc = str(GameData.TRADE_PORTS[port_id].get("order_npc", ""))
		_check(order_npc != "" and order_npc in GameData.LOCATIONS[port_id].npcs, "%s商会交付人物必须真实存在于港口地图" % GameData.TRADE_PORTS[port_id].name)
		var merchant_npc = str(port.get("merchant_npc", ""))
		var specialty_good = str(port.get("specialty_good", ""))
		var stock = GameData.port_stock(str(port_id))
		_check(merchant_npc != "" and merchant_npc in GameData.LOCATIONS[port_id].npcs and str(GameData.NPCS.get(merchant_npc, {}).get("service", "")) == "market", "%s必须有可在地图互动的专属货栈NPC" % port.name)
		for service_id in ["market", "harbor", "shipyard"]:
			var service_npc = GameData.port_service_npc(str(port_id), service_id)
			_check(service_npc != "" and service_npc in GameData.LOCATIONS[port_id].npcs and str(GameData.NPCS.get(service_npc, {}).get("service", "")) == service_id, "%s必须由不同NPC分别承担%s职能" % [port.name, service_id])
		var offered_hull_id = str(port.get("ship_offer", ""))
		var offered_hull = Dictionary(GameData.SHIP_HULLS.get(offered_hull_id, {}))
		_check(not offered_hull.is_empty() and str(offered_hull.get("sales_port", "")) == str(port_id) and str(port.get("ship_seller", "")) != "", "%s必须由当地船老板出售本港专属船型" % port.name)
		_check(not regional_ship_offers.has(offered_hull_id), "%s不能与其他港口重复出售同一船型" % port.name)
		regional_ship_offers[offered_hull_id] = true
		ship_levels[int(offered_hull.get("level", 0))] = true
		_check(specialty_good != "" and specialty_good in stock and str(GameData.TRADE_GOODS.get(specialty_good, {}).get("origin", "")) == str(port_id), "%s必须出售产地归属明确的本港特色商品" % port.name)
		for stock_good_id in stock:
			_check(str(GameData.TRADE_GOODS.get(str(stock_good_id), {}).get("origin", "")) == str(port_id), "%s货栈不能混入其他城市出产的%s" % [port.name, GameData.TRADE_GOODS[str(stock_good_id)].name])
		specialty_goods[specialty_good] = true
		if port_id != "venice_dock":
			_check(GameData.LOCATIONS[port_id].npcs.size() >= 3, "%s至少需要剧情、贸易和港口服务三名可互动人物" % GameData.TRADE_PORTS[port_id].name)
	_check(specialty_goods.size() == GameData.TRADE_PORTS.size(), "九座城市必须各有不同的特色商品，不能重复套用同一批特产")
	_check(regional_ship_offers.size() == GameData.TRADE_PORTS.size() and ship_levels.size() == 9, "九座城市必须各卖一艘不同等级的专属船只")
	for expected_ship_level in range(1, 10):
		_check(ship_levels.has(expected_ship_level), "九港船只等级必须从Lv.1连续成长到Lv.9")
	var athens_to_ragusa = GameData.trade_route_path("athens_dock", "ragusa_dock", GameData.TRADE_PORTS.keys())
	_check(athens_to_ragusa == ["athens_dock", "ragusa_dock"], "雅典至拉古萨必须直接通航，不能被固定路线强制到威尼斯中转")
	for good_id in GameData.TRADE_GOODS:
		_check(GameData.TRADE_GOODS[good_id].prices.size() == GameData.TRADE_PORTS.size(), "%s必须在九港都有独立收购价" % GameData.TRADE_GOODS[good_id].name)
		var selling_ports = []
		for port_id in GameData.TRADE_PORTS:
			if GameData.port_sells_good(str(port_id), str(good_id)):
				selling_ports.append(str(port_id))
		_check(selling_ports == [str(GameData.TRADE_GOODS[good_id].origin)], "%s只能在唯一原产港买入，其他城市只负责收购" % GameData.TRADE_GOODS[good_id].name)
	var route_market = TestState.new()
	route_market.quest_index = GameData.QUESTS.size()
	route_market.player.silver = 9999
	for port_id in GameData.TRADE_PORTS:
		route_market.player.location = str(port_id)
		var opportunity = route_market.best_trade_opportunity()
		_check(not opportunity.is_empty() and str(opportunity.good_id) == str(GameData.TRADE_PORTS[port_id].specialty_good) and int(opportunity.total_profit) > 0, "%s必须至少有一条从本地特产低买、沿自由航线高卖的盈利商路" % GameData.TRADE_PORTS[port_id].name)
	var opening_story = state.story_progress()
	_check(int(opening_story.total) == GameData.QUESTS.size() and str(opening_story.chapter) == "序章·失去的名字", "任务系统必须返回总进度与当前章节")
	var gear_state = TestState.new()
	gear_state.inventory["warrior_blade"] = 1
	var power_before_recommend = gear_state.get_power()
	var recommend_result = gear_state.equip_recommended()
	_check(bool(recommend_result.ok) and str(gear_state.equipment.weapon) == "warrior_blade" and gear_state.get_power() > power_before_recommend, "一键推荐必须自动换上背包中更强的装备")
	var set_state = TestState.new()
	set_state.equipment = {"weapon": "warrior_blade", "head": "warrior_circlet", "body": "warrior_coat", "waist": "warrior_belt", "boots": "warrior_boots", "charm": ""}
	var warrior_bonus = set_state.equipment_set_bonus_stats()
	_check(int(set_state.equipment_set_counts().warrior) == 5 and int(warrior_bonus.attack) == 8 and int(warrior_bonus.defense) == 6 and int(warrior_bonus.speed) == 5 and is_equal_approx(float(warrior_bonus.drop_bonus), 0.20), "武士套必须按2件、4件、5件逐级叠加战斗与寻宝共鸣")
	set_state.inventory["corsair_cutlass"] = 1
	var preserve_set_result = set_state.equip_recommended()
	_check(not bool(preserve_set_result.ok) and str(set_state.equipment.weapon) == "warrior_blade", "一键推荐必须计算拆套损失，不能只按单件数值破坏完整套装")
	var forge_state = TestState.new()
	forge_state.player.silver = 10000
	forge_state.equipment.weapon = "warrior_blade"
	for forge_step in range(3):
		_check(bool(forge_state.upgrade_equipped("weapon").ok), "装备+1至+3必须只消耗银币并稳定成功")
	_check(not bool(forge_state.upgrade_equipped("weapon").ok) and forge_state.equipment_upgrade_level("warrior_blade") == 3, "装备强化至+4必须先准备龙泉水")
	forge_state.inventory["dragon_spring_water"] = 1
	_check(bool(forge_state.upgrade_equipped("weapon").ok) and forge_state.equipment_upgrade_level("warrior_blade") == 4 and int(forge_state.inventory.get("dragon_spring_water", 0)) == 0, "装备强化至+4必须消耗一份龙泉水")
	forge_state.inventory["dragon_spring_water"] = 5
	for forge_step in range(3):
		_check(bool(forge_state.upgrade_equipped("weapon").ok), "装备+5至+7必须消耗龙泉水并稳定成功")
	_check(not bool(forge_state.upgrade_equipped("weapon").ok) and forge_state.equipment_upgrade_level("warrior_blade") == 7, "装备强化至+8必须同时准备强化图纸")
	forge_state.inventory["forging_blueprint"] = 1
	_check(bool(forge_state.upgrade_equipped("weapon").ok) and forge_state.equipment_upgrade_level("warrior_blade") == 8 and int(forge_state.inventory.get("forging_blueprint", 0)) == 0, "装备强化至+8必须消耗图纸与两份龙泉水")
	var vendor_state = TestState.new()
	vendor_state.player.silver = 500
	vendor_state.player.location = "venice_market"
	var jewelry_purchase = vendor_state.buy_vendor_item("jeweler", "coral_ring")
	_check(bool(jewelry_purchase.ok) and int(vendor_state.inventory.get("coral_ring", 0)) == 1 and vendor_state.equip_item("coral_ring").ok, "珠宝商必须真实出售可穿戴珠宝")
	_check(bool(vendor_state.buy_vendor_item("jeweler", "dragon_spring_water").ok), "贝里昂锻造铺必须出售高阶强化所需的龙泉水")
	vendor_state.player.location = "venice_tavern"
	var food_purchase = vendor_state.buy_vendor_item("tavern_keeper", "herb_fish_stew")
	vendor_state.player.hp = max(1, int(vendor_state.get_stats().max_hp) - 70)
	_check(bool(food_purchase.ok) and vendor_state.use_item("herb_fish_stew").ok, "酒馆老板必须真实出售可在背包使用的食物")
	var inn_state = TestState.new()
	inn_state.player.location = "ragusa_dock"
	inn_state.player.silver = 100
	_check(bool(inn_state.buy_vendor_item("ragusa_innkeeper", "universal_medicine").ok), "拉古萨旅店必须独立出售恢复药品，不能混入货栈")
	_check(not vendor_state.buy_vendor_item("tavern_keeper", "coral_ring").ok, "不同NPC货柜必须隔离，酒馆不能出售珠宝")

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
	var sale_rule_state = TestState.new()
	sale_rule_state.quest_index = 9
	sale_rule_state.player.location = "venice_dock"
	sale_rule_state.cargo = {"venetian_glass": 4}
	sale_rule_state.cargo_costs = {"venetian_glass": 120}
	var wrong_port_sale = sale_rule_state.sell_cargo("venetian_glass", 2)
	_check(bool(wrong_port_sale.ok) and bool(wrong_port_sale.wrong_quest_port) and sale_rule_state.quest_progress == 0 and "拉古萨" in str(wrong_port_sale.message), "玻璃商路不能在错误港口完成，交易结果必须明确提示正确目的地")
	_check("拉古萨港" in " ".join(sale_rule_state.quest_action_steps()), "贸易任务行动清单必须由目标数据生成正确的出售港口")
	sale_rule_state.player.location = "ragusa_dock"
	var correct_port_sale = sale_rule_state.sell_cargo("venetian_glass", 2)
	_check(bool(correct_port_sale.ok) and not bool(correct_port_sale.wrong_quest_port) and sale_rule_state.quest_can_claim(), "抵达拉古萨出售足量玻璃后才能完成玻璃商路")
	var lighthouse_plan_state = TestState.new()
	lighthouse_plan_state.quest_index = 20
	lighthouse_plan_state.player.location = "venice_dock"
	_check("启航前到威尼斯港采购威尼斯玻璃×3" in " ".join(lighthouse_plan_state.quest_action_steps()), "灯塔远航行动清单必须先提示装载三箱玻璃，避免抵港后折返")
	lighthouse_plan_state.cargo = {"venetian_glass": 3}
	_check(not "启航前" in " ".join(lighthouse_plan_state.quest_action_steps()), "备齐灯塔玻璃后行动清单必须自动移除采购步骤")

	state.player.location = "venice_dock"
	_check(not state.buy_cargo("wool_cloth").ok and state.max_buyable_cargo("wool_cloth") == 0, "威尼斯货栈不能出售拉古萨特产，港口商品不能再全部混在一起")
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

	var market_state = TestState.new()
	market_state.quest_index = GameData.QUESTS.size()
	market_state.player.location = "venice_dock"
	market_state.player.silver = 9999
	var daily_glass_supply = market_state.market_supply_limit("venetian_glass")
	_check(daily_glass_supply >= 8 and market_state.max_buyable_cargo("venetian_glass") == min(daily_glass_supply, 6), "每日供货量必须与海燕号12格货舱、玻璃每箱2格共同限制可买数量")
	var route_board = market_state.trade_route_opportunities(3)
	_check(not route_board.is_empty() and int(route_board[0].space) <= market_state.cargo_space_free() and route_board[0].has("profit_per_space") and route_board[0].has("risk"), "商会价差榜必须按空余货舱、资金、供货量计算单位舱位利润和航线风险")
	var full_hold = market_state.buy_max_cargo("venetian_glass")
	_check(bool(full_hold.ok) and market_state.cargo_used() == market_state.cargo_capacity() and market_state.max_buyable_cargo("venetian_glass") == 0, "买满必须严格装至当前船只容量，不能超载")
	market_state.player.location = "ragusa_dock"
	market_state.cargo = {"venetian_glass": 18}
	market_state.cargo_costs = {"venetian_glass": 432}
	var first_sale_price = market_state.trade_sell_price("venetian_glass")
	var saturated_quote = market_state.trade_sale_quote("venetian_glass", 18)
	_check(int(saturated_quote.total) < first_sale_price * 18, "一次抛售超过本港高价需求后，后续货物必须按需求饱和价结算")
	var saturated_sale = market_state.sell_all_cargo("venetian_glass")
	_check(bool(saturated_sale.ok) and market_state.market_demand_remaining("venetian_glass") == 0 and int(saturated_sale.price) < first_sale_price, "大量倒货必须消耗本港需求并显示降低后的成交均价")

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
	state.buy_voyage_protection()
	state.sail_to("ragusa_dock")
	state.buy_cargo("olive_oil", 4)
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
	state.buy_voyage_protection()
	state.sail_to("ragusa_dock")
	state.buy_cargo("olive_oil", 1)
	state.buy_voyage_protection()
	state.sail_to("alexandria_dock")
	state.buy_cargo("spices", 1)
	state.buy_voyage_protection()
	state.sail_to("malta_dock")
	state.buy_cargo("citrus", 2)
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
	_check(state.get_current_quest().id == "sail_cape" and int(state.player.level) >= 30, "第三卷结束后必须接续第四卷聚宝盆")
	_check(str(state.player.title) == "白鲸继航者", "第三卷结局必须授予白鲸继航者称号")

	var late_volumes = [
		{"port": "cape_town_dock", "sail": "sail_cape", "meet": "meet_amanda", "npc": "cape_keeper", "order_quest": "basin_order", "order": "basin_supplies", "enter": "enter_basin", "location": "legacy_basin", "kill": "defeat_basin", "enemy": "basin_leviathan", "return": "basin_return", "gear": "basin_charm"},
		{"port": "quanzhou_dock", "sail": "sail_quanzhou", "meet": "meet_shenyan", "npc": "quanzhou_scholar", "order_quest": "changan_order", "order": "changan_seals", "enter": "enter_changan", "location": "legacy_changan", "kill": "defeat_changan", "enemy": "nine_tail_fox", "return": "changan_return", "gear": "demon_mask"},
		{"port": "athens_dock", "sail": "sail_athens_earth", "meet": "meet_oracle_earth", "npc": "athens_oracle", "order_quest": "earth_order", "order": "earth_lamps", "enter": "enter_earth", "location": "legacy_earth", "kill": "defeat_earth", "enemy": "earth_demon_king", "return": "earth_return", "gear": "earth_armor"},
		{"port": "venice_dock", "sail": "sail_venice_tira", "meet": "meet_keeper_tira", "npc": "tavern_keeper", "order_quest": "tira_order", "order": "tira_forge", "enter": "enter_tira", "location": "legacy_tira", "kill": "defeat_tira", "enemy": "tira_guardian", "return": "tira_return", "gear": "tira_sword"},
		{"port": "yangzhou_dock", "sail": "sail_yangzhou_demon", "meet": "meet_suling_demon", "npc": "yangzhou_weaver", "order_quest": "demon_order", "order": "demon_sails", "enter": "enter_demon_legend", "location": "legacy_demon_legend", "kill": "defeat_demon_legend", "enemy": "celestial_demon_general", "return": "demon_legend_return", "gear": "celestial_belt"},
		{"port": "amsterdam_dock", "sail": "sail_amsterdam_jade", "meet": "meet_vander_jade", "npc": "amsterdam_cartographer", "order_quest": "jade_order", "order": "jade_calendar", "enter": "enter_jade", "location": "legacy_jade", "kill": "defeat_jade", "enemy": "jade_dream_queen", "return": "jade_return", "gear": "jade_boots"},
		{"port": "venice_dock", "sail": "sail_venice_fire", "meet": "meet_keeper_fire", "npc": "tavern_keeper", "order_quest": "fire_order", "order": "furnace_decoy", "enter": "enter_fire", "location": "legacy_fire", "kill": "defeat_fire", "enemy": "black_furnace_lord", "return": "fire_return", "gear": "furnace_core"},
		{"port": "quanzhou_dock", "sail": "sail_quanzhou_return", "meet": "meet_shenyan_return", "npc": "quanzhou_scholar", "order_quest": "return_order", "order": "return_wards", "enter": "enter_return", "location": "legacy_return", "kill": "defeat_return", "enemy": "returned_demon_king", "return": "return_home", "gear": "demon_crown"},
		{"port": "athens_dock", "sail": "sail_athens_shears", "meet": "meet_oracle_shears", "npc": "athens_oracle", "order_quest": "shears_order", "order": "shears_alloy", "enter": "enter_shears", "location": "legacy_shears", "kill": "defeat_shears", "enemy": "clockwork_tailor", "return": "shears_return", "gear": "divine_shears"},
		{"port": "yangzhou_dock", "sail": "sail_yangzhou_seal", "meet": "meet_suling_seal", "npc": "yangzhou_weaver", "order_quest": "seal_order", "order": "seal_threads", "enter": "enter_seal", "location": "legacy_seal", "kill": "defeat_seal", "enemy": "tide_void_emperor", "return": "seal_epilogue", "gear": "tidekeeper_regalia"}
	]
	for volume in late_volumes:
		var voyage_result = state.sail_to(str(volume.port))
		_check(bool(voyage_result.ok), "%s必须存在可航行的连续主线航路" % str(volume.sail))
		_claim(state, str(volume.sail))
		if str(volume.npc) == "tavern_keeper":
			state.player.location = "venice_tavern"
		state.talk_to(str(volume.npc))
		_claim(state, str(volume.meet))
		var order = GameData.TRADE_ORDERS[str(volume.order)]
		var source_port = str(GameData.TRADE_GOODS[str(order.good)].origin)
		state.player.location = source_port
		var cargo_result = state.buy_cargo(str(order.good), int(order.amount))
		_check(bool(cargo_result.ok), "主线订单%s必须能从%s采购货物" % [str(volume.order), GameData.TRADE_PORTS[source_port].name])
		state.player.location = str(volume.port)
		_check(bool(state.claim_trade_order().ok), "主线订单%s必须能交付" % str(volume.order))
		_claim(state, str(volume.order_quest))
		state.arrive_from_2d(str(volume.location))
		_claim(state, str(volume.enter))
		_win_times(state, str(volume.enemy), 1)
		var boss_reward = _claim(state, str(volume.kill))
		_check(str(boss_reward.get("reward_item", "")) == str(volume.gear) and state.equip_item(str(volume.gear)).ok, "%s必须掉落并可装备专属装备" % str(volume.enemy))
		state.player.location = "venice_tavern" if str(volume.npc) == "tavern_keeper" else str(volume.port)
		state.talk_to(str(volume.npc))
		_claim(state, str(volume.return))
		state.player.location = str(volume.port)

	_check(state.get_current_quest().is_empty() and int(state.player.level) == GameData.MAX_LEVEL, "十三卷完整主线必须支持成长至Lv.100")
	_check(str(state.player.title) == "四海守潮人", "第十三卷结局必须授予四海守潮人称号")

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
	_check(GameData.LOCATIONS.size() == 40, "世界图应包含九座贸易港、三座四层副本与十座终局远征")
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
		print("SMOKE_OK: 十三卷主线、九港贸易、十座终局远征与Lv.100成长闭环全部通过")
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
